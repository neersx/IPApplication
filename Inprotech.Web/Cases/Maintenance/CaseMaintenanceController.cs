using System.Collections.Generic;
using System.Linq;
using System.Transactions;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Persistence;
using Severity = Inprotech.Infrastructure.Validations.Severity;

namespace Inprotech.Web.Cases.Maintenance
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainCase, ApplicationTaskAccessLevel.Modify)]
    [RoutePrefix("api/case/maintenance")]
    public class CaseMaintenanceController : ApiController
    {
        readonly ITopicsUpdater<Case> _topicsUpdater;
        readonly IDbContext _dbContext;
        readonly ICaseMaintenanceSave _caseMaintenanceSave;
        readonly IPolicingEngine _policingEngine;
        readonly ISiteControlReader _siteControlReader;
        public CaseMaintenanceController(IDbContext dbContext, ITopicsUpdater<Case> topicsUpdater, ICaseMaintenanceSave caseMaintenanceSave, IPolicingEngine policingEngine, ISiteControlReader siteControlReader)
        {
            _topicsUpdater = topicsUpdater;
            _dbContext = dbContext;
            _caseMaintenanceSave = caseMaintenanceSave;
            _policingEngine = policingEngine;
            _siteControlReader = siteControlReader;
        }

        [HttpPost]
        [RequiresCaseAuthorization(PropertyPath = "model.CaseKey")]
        [AppliesToComponent(KnownComponents.Case)]
        [Route]
        public MaintenanceSaveResponse SaveData(CaseMaintenanceSaveModel model)
        {
            var @case = _dbContext.Set<Case>().Single(_ => _.Id == model.CaseKey);
            var errors = _topicsUpdater.Validate(model, TopicGroups.Cases, @case).ToList();
            var warningsOnly = errors.All(e => e.Severity == Severity.Warning);
            if (errors.Any() && !(model.ForceUpdate && warningsOnly))
            {
                return new MaintenanceSaveResponse()
                {
                    Status = warningsOnly ? "warning" : "error",
                    Errors = errors
                };
            }

            int? batchNo = null;
            var isPolicingImmediate = model.IsPoliceImmediately ?? _siteControlReader.Read<bool>(SiteControls.PoliceImmediately);
            if (isPolicingImmediate)
            {
                batchNo = _policingEngine.CreateBatch();
            }

            bool anyPolicingRequests;
            bool saved = false;
            IEnumerable<dynamic> sanityCheckResults = null;
            using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var result = _caseMaintenanceSave.Save(@case, model.IsPoliceImmediately, batchNo, model);
                anyPolicingRequests = result.AnyPolicingRequests;
                var sanityCheckErrors = result.SanityCheckResults.Where(_ => !_.Details.IsWarning).ToList();
                if (!sanityCheckErrors.Any() || (sanityCheckErrors.All(_=> _.Details.CanOverride) && model.IgnoreSanityCheck))
                {
                    tcs.Complete();
                    saved = true;
                }

                if (!model.IgnoreSanityCheck)
                {
                    sanityCheckResults = result.SanityCheckResults.Select(_ => _.Details);
                }
            }

            bool shouldRunPolicing = saved && anyPolicingRequests && isPolicingImmediate;

            return new MaintenanceSaveResponse()
            {
                BatchNo = batchNo,
                ShouldRunPolicing = shouldRunPolicing,
                SanityCheckResults = sanityCheckResults,
                SavedSuccessfully = saved
            };
        }

        public class MaintenanceSaveResponse
        {
            public IEnumerable<ValidationError> Errors { get; set; }

            public string Status { get; set; }
            public bool ShouldRunPolicing { get; set; }
            public bool SavedSuccessfully { get; set; }
            public int? BatchNo { get; set; }
            public IEnumerable<dynamic> SanityCheckResults { get; set; }
        }
    }
}
