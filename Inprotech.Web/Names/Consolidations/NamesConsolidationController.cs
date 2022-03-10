using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Names.Consolidations;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Names.Consolidations
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.NamesConsolidation)]
    [RoutePrefix("api/names")]
    public class NamesConsolidationController : ApiController
    {
        readonly IConfigureJob _configureJob;
        readonly INamesConsolidationValidator _namesConsolidationValidator;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControlReader;

        public NamesConsolidationController(ISecurityContext securityContext,
                                            ISiteControlReader siteControlReader,
                                            INamesConsolidationValidator namesConsolidationValidator,
                                            IConfigureJob configureJob)
        {
            _securityContext = securityContext;
            _siteControlReader = siteControlReader;
            _namesConsolidationValidator = namesConsolidationValidator;
            _configureJob = configureJob;
        }

        [HttpPost]
        [Route("consolidate/{targetNameNo:int}")]
        public async Task<dynamic> Consolidate(int targetNameNo, ConsolidationData model)
        {
            var validationResult = await _namesConsolidationValidator.Validate(targetNameNo, model.NamesToBeConsolidated, model.IgnoreTypeWarnings);
            var status = !validationResult.Errors.Any();
            if (!validationResult.Errors.Any(_ => _.IsBlocking))
            {
                if (model.IgnoreFinancialWarnings && validationResult.FinancialCheckPerformed || !validationResult.Errors.Any())
                {
                    var arg = new NameConsolidationArgs
                    {
                        NameIds = model.NamesToBeConsolidated,
                        TargetId = targetNameNo,
                        ExecuteAs = _securityContext.User.Id,
                        KeepTelecomHistory = model.KeepTelecomHistory,
                        KeepAddressHistory = model.KeepAddressHistory,
                        KeepConsolidatedName = _siteControlReader.Read<bool?>(SiteControls.KeepConsolidatedName) ?? false
                    };

                    if (!_configureJob.TryCreateOneTimeJob(nameof(NameConsolidationJob), arg))
                    {
                        throw new InvalidOperationException("Name Consolidation job failed to initiated because another name consolidation job is already running");
                    }

                    return new
                    {
                        Status = true
                    };
                }
            }

            return new
            {
                Status = status,
                validationResult.FinancialCheckPerformed,
                validationResult.Errors
            };
        }

        public class ConsolidationData
        {
            public bool IgnoreTypeWarnings { get; set; }
            public bool IgnoreFinancialWarnings { get; set; }
            public int[] NamesToBeConsolidated { get; set; }
            public bool KeepAddressHistory { get; set; }
            public bool KeepTelecomHistory { get; set; }
        }
    }
}