using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
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
    public class ActionEventController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IEventNotesResolver _eventNotesResolver;
        readonly IActionEvents _events;
        readonly IImportanceLevelResolver _importanceLevel;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public ActionEventController(IDbContext dbContext,
                                     IActionEvents events,
                                     IImportanceLevelResolver importanceLevel,
                                     IEventNotesResolver eventNotesResolver,
                                     ITaskSecurityProvider taskSecurityProvider)
        {
            _dbContext = dbContext;
            _events = events;
            _importanceLevel = importanceLevel;
            _eventNotesResolver = eventNotesResolver;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/action/{actionId}")]
        public async Task<PagedResults> GetCaseActionEvents(int caseKey, string actionId,
                                                            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")]
                                                            ActionEventQuery q = null,
                                                            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                            CommonQueryParameters qp = null)
        {
            if (q == null) throw new HttpResponseException(HttpStatusCode.BadRequest);

            var qp1 = qp ?? new CommonQueryParameters();

            var @case = _dbContext.Set<Case>().SingleOrDefault(v => v.Id == caseKey);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            q.ImportanceLevel = _importanceLevel.GetValidImportanceLevel(q.ImportanceLevel);

            var interimResults = _events.Events(@case, actionId, q);

            var interimPagedResults = interimResults.OrderByProperty(qp1)
                                                    .AsPagedResults(qp1);

            if (!interimPagedResults.Data.Any())
            {
                return interimPagedResults;
            }

            var results = (await _events.ClearValueByCaseAndNameAccess(interimPagedResults.Data)).ToArray();

            var notes = _eventNotesResolver.Resolve(caseKey, results.Select(_ => _.EventNo)).ToArray();

            var canLaunchWorkflowWizard = _taskSecurityProvider.HasAccessTo(ApplicationTask.LaunchWorkflowWizard);

            foreach (var @event in results)
            {
                @event.EventNotes = notes.Where(n => n.EventId == @event.EventNo && n.Cycle == @event.Cycle);

                if (!canLaunchWorkflowWizard)
                {
                    @event.CanLinkToWorkflow = false;
                }
            }

            return new PagedResults(results, interimPagedResults.Pagination.Total);
        }
    }

    public class ActionEventQuery
    {
        public int? CriteriaId { get; set; }

        public int? ImportanceLevel { get; set; }

        public int? Cycle { get; set; }

        public bool IsCyclic { get; set; }

        public bool AllEvents { get; set; }

        public bool MostRecent { get; set; }

        public bool IncludeOpenActions { get; set; }

        public bool IncludeClosedActions { get; set; }

        public bool IncludePotentialActions { get; set; }
    }
}