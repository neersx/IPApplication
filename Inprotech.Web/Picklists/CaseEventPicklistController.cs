using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/caseEvents")]
    public class CaseEventPicklistController : ApiController
    {
        readonly ICommonQueryService _commonQueryService;
        readonly ICaseEventMatcher _matcher;

        public CaseEventPicklistController(ICommonQueryService commonQueryService, ICaseEventMatcher matcher)
        {
            _commonQueryService = commonQueryService;
            _matcher = matcher;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route]
        public PagedResults Events(int caseId, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "", string actionId = null)
        {
            var all = _commonQueryService.Filter(MatchingItems(search, caseId, actionId), queryParameters).ToArray();

            var result = Helpers.GetPagedResults(all, queryParameters, x => x.Key.ToString(), x => x.Value, search);
            result.Ids = Helpers.GetPagedResults(all, new CommonQueryParameters {SortDir = queryParameters?.SortDir, SortBy = queryParameters?.SortBy, Take = all.Length}, x => x.Key.ToString(), x => x.Value, search)
                                .Data.Select(_ => _.Key);

            return result;
        }

        IEnumerable<Event> MatchingItems(string search, int caseId, string actionId = null)
        {
            return from e in _matcher.MatchingItems(caseId, search, actionId)
                   select new Event
                   {
                       Key = e.Key,
                       Code = e.Code,
                       Value = e.Value,
                       MaxCycles = e.MaxCycles,
                       Importance = e.Importance,
                       ImportanceLevel = e.ImportanceLevel,
                       Alias = e.Alias,
                       EventCategory = e.EventCategory,
                       EventGroup = e.EventGroup,
                       EventNotesGroup = e.EventNotesGroup,
                       CurrentCycle = e.CurrentCycle
                   };
        }
    }   
}
