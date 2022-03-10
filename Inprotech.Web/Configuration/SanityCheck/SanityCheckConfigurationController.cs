using System;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.SanityCheck
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/sanity-check")]
    public class SanityCheckConfigurationController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ISanityCheckService _sanityCheckService;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public SanityCheckConfigurationController(ISanityCheckService sanityCheckService, IDbContext dbContext, ITaskSecurityProvider taskSecurityProvider)
        {
            _sanityCheckService = sanityCheckService;
            _dbContext = dbContext;
            _taskSecurityProvider = taskSecurityProvider;
        }

        dynamic CaseNameAccessRights()
        {
            return new
            {
                CanCreateForCase = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Create),
                canDeleteForCase = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Delete),
                canUpdateForCase = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Modify),
                CanCreateForName = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Create),
                canDeleteForName = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Delete),
                canUpdateForName = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Modify)
            };
        }

        [HttpGet]
        [Route("view-data/case")]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Create)]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Modify)]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Delete)]
        public dynamic GetViewDataCase()
        {
            return CaseNameAccessRights();
        }

        [HttpGet]
        [Route("view-data/name")]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Create)]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Modify)]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Delete)]
        public dynamic GetViewDataName()
        {
            return CaseNameAccessRights();
        }

        [HttpGet]
        [Route("case/search")]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Create)]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Modify)]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForCases, ApplicationTaskAccessLevel.Delete)]
        public async Task<dynamic> CaseSearch([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")] SanityCheckCaseViewModel filters,
                                              [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                              CommonQueryParameters queryParameters)
        {
            if (filters == null) throw new ArgumentNullException(nameof(filters));
            queryParameters = new CommonQueryParameters { SortBy = "ruleDescription" }.Extend(queryParameters);

            var rows = await _sanityCheckService.GetCaseValidationRules(filters, queryParameters);

            return rows;
        }

        [HttpGet]
        [Route("name/search")]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Create)]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Modify)]
        [RequiresAccessTo(ApplicationTask.MaintainSanityCheckRulesForNames, ApplicationTaskAccessLevel.Delete)]
        public async Task<dynamic> NameSearch([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "criteria")] SanityCheckNameViewModel filters,
                                              [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                              CommonQueryParameters queryParameters)
        {
            if (filters == null) throw new ArgumentNullException(nameof(filters));
            queryParameters = new CommonQueryParameters { SortBy = "ruleDescription" }.Extend(queryParameters);

            var rows = await _sanityCheckService.GetNameValidationRules(filters, queryParameters);

            return rows;
        }
    }
}