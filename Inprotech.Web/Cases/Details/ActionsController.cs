using System;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class ActionsController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IActions _actions;
        readonly IImportanceLevelResolver _importanceLevelResolver;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly ISiteControlReader _siteControlReader;
        readonly ICaseAuthorization _caseAuthorization;

        public ActionsController(IDbContext dbContext, IActions actions, IImportanceLevelResolver importanceLevelResolverResolver, ITaskSecurityProvider taskSecurityProvider, ISiteControlReader siteControlReader, ICaseAuthorization caseAuthorization)
        {
            _dbContext = dbContext;
            _actions = actions;
            _importanceLevelResolver = importanceLevelResolverResolver;
            _taskSecurityProvider = taskSecurityProvider;
            _siteControlReader = siteControlReader;
            _caseAuthorization = caseAuthorization;
        }

        [HttpGet]
        [Route("action/view/{caseKey:int}")]
        [RequiresCaseAuthorization]
        public async Task<dynamic> View(int caseKey)
        {
            var canPolicyActions = !(await _caseAuthorization.Authorize(caseKey, AccessPermissionLevel.Update)).IsUnauthorized
                   && _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCase, ApplicationTaskAccessLevel.Modify)
                   && _taskSecurityProvider.HasAccessTo(ApplicationTask.PoliceActionsOnCase, ApplicationTaskAccessLevel.Execute);

            return new
            {
                CanMaintainWorkflow = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRules) || _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRulesProtected),
                CanPoliceActions = canPolicyActions,
                IsPoliceImmediately = _siteControlReader.Read<bool>(SiteControls.PoliceImmediately) || _siteControlReader.Read<bool>(SiteControls.PoliceImmediateInBackground),
                MaintainCaseEvent = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseEvent),
                MaintainEventNotes = _taskSecurityProvider.HasAccessTo(ApplicationTask.AnnotateDueDates),
                ClearCaseEventDates = _taskSecurityProvider.HasAccessTo(ApplicationTask.ClearCaseEventDates),
                CanViewRuleDetails = _taskSecurityProvider.HasAccessTo(ApplicationTask.ViewRuleDetails),
                CanAddAttachment = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.Create)
            };
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/action")]
        public PagedResults GetCaseActions(int caseKey, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                                           ActionEventQuery q = null, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                           CommonQueryParameters qp = null)
        {
            var @case = _dbContext.Set<Case>().SingleOrDefault(v => v.Id == caseKey);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            var importanceLevel = _importanceLevelResolver.GetValidImportanceLevel(q?.ImportanceLevel);

            var actions = _actions.CaseViewActions(caseKey, @case.Country.Id, @case.PropertyType.Code, @case.TypeId);

            if (q != null)
                actions = actions.Where(a => (q.IncludePotentialActions && a.IsPotential == true) || (q.IncludeOpenActions && a.IsOpen == true)
                                             || q.IncludeClosedActions && a.IsClosed == true);

            if (importanceLevel.HasValue)
                actions = actions.Where(_ => string.Compare(_.ImportanceLevel, importanceLevel.ToString(), StringComparison.InvariantCultureIgnoreCase) >= 0);

            return actions.OrderByProperty(qp).AsPagedResults(qp);
        }
    }
}