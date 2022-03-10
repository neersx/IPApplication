using System;
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
    public class CaseViewEventsController : ApiController
    {
        readonly ICaseViewEvents _caseViewEvents;
        readonly IDbContext _dbContext;
        readonly IEventNotesResolver _eventNotesResolver;
        readonly IImportanceLevelResolver _importanceLevel;

        public CaseViewEventsController(IDbContext dbContext, ICaseViewEvents caseViewEvents, IImportanceLevelResolver importanceLevel, IEventNotesResolver eventNotesResolver)
        {
            _dbContext = dbContext;
            _caseViewEvents = caseViewEvents;
            _eventNotesResolver = eventNotesResolver;
            _importanceLevel = importanceLevel;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/caseviewevent/occurred")]
        public async Task<PagedResults> GetCaseOccurredEvents(int caseKey,
                                                  [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters qp = null,
                                                  [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] CaseEventQuery q = null)
        {
            return await GetCaseEvents(caseKey, qp, q, EventType.Occurred);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/caseviewevent/due")]
        public async Task<PagedResults> GetCaseDueEvents(int caseKey,
                                             [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters qp = null,
                                             [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] CaseEventQuery q = null)
        {
            return await GetCaseEvents(caseKey, qp, q, EventType.Due);
        }

        async Task<PagedResults> GetCaseEvents(int caseKey, CommonQueryParameters qp, CaseEventQuery q, EventType eventType)
        {
            var @case = _dbContext.Set<Case>().SingleOrDefault(v => v.Id == caseKey);
            if (@case == null) throw new HttpResponseException(HttpStatusCode.NotFound);

            var importanceLevel = _importanceLevel.GetValidImportanceLevel(q?.ImportanceLevel);

            var events = eventType == EventType.Occurred ? _caseViewEvents.Occurred(caseKey) : _caseViewEvents.Due(caseKey);

            if (importanceLevel.HasValue)
                events = events.Where(_ => string.Compare(_.ImportanceLevel, importanceLevel.ToString(), StringComparison.InvariantCultureIgnoreCase) >= 0);

            var eventsData = events.OrderByProperty(qp)
                                   .AsPagedResults(qp);

            if (!eventsData.Data.Any()) return eventsData;

            await _caseViewEvents.ClearUnauthorisedDetails(eventsData.Data);

            var notes = _eventNotesResolver.Resolve(caseKey, eventsData.Data.Select(_ => _.EventNo)).ToArray();
            foreach (var @event in eventsData.Data)
                @event.EventNotes = notes.Where(n => n.EventId == @event.EventNo && n.Cycle == @event.Cycle);

            return new PagedResults(eventsData.Data, eventsData.Pagination.Total);
        }

        public class CaseEventQuery
        {
            public int? ImportanceLevel { get; set; }
        }

        enum EventType
        {
            Occurred,
            Due
        }
    }
}