using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Search.Case;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Picklists
{
    [NoEnrichment]
    [RoutePrefix("api/picklists/cases")]
    public class TimesheetCasesPicklistController : CasesPicklistController
    {
        readonly IRecentCasesProvider _recentCases;
        readonly ISecurityContext _securityContext;
        readonly IFunctionSecurityProvider _functionSecurity;

        public TimesheetCasesPicklistController(IListCase listCase, IRecentCasesProvider recentCases, ISecurityContext securityContext, IFunctionSecurityProvider functionSecurity) : base(listCase)
        {
            _recentCases = recentCases;
            _securityContext = securityContext;
            _functionSecurity = functionSecurity;
        }

        [HttpGet]
        [Route("instructor")]
        [RequiresNameAuthorization]
        [PicklistPayload(typeof(Case))]
        public async Task<dynamic> CasesWithInstructor([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                       CommonQueryParameters queryParameters = null, string search = "", int? nameKey = null, bool includeRecent = false)
        {
            var staffNameId = _securityContext.User.NameId;
            if (!await _functionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, _securityContext.User, staffNameId))
            {
                throw new HttpResponseException(HttpStatusCode.Forbidden);
            }

            var extendedQueryParams = _queryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            PagedResults recentEntriesResult = includeRecent ? await RecentResultsForTimeSheet(search, nameKey, extendedQueryParams.Take / 2 ?? 10) : null;

            var picklistSearchResults = new PagedResults(new object[]{}, 0);

            if (!includeRecent || !string.IsNullOrWhiteSpace(search))
            {
                var cases = _listCase.Get(out var rowCount, search, MapColumn(extendedQueryParams.SortBy), extendedQueryParams.SortDir, extendedQueryParams.Skip, extendedQueryParams.Take, nameKey, true);
                var result = cases.Select(c => new Case
                {
                    Key = c.Id,
                    Code = c.CaseRef,
                    Value = c.Title,
                    OfficialNumber = c.OfficialNumber,
                    PropertyTypeDescription = c.PropertyTypeDescription,
                    CountryName = c.CountryName,
                    InstructorName = c.InstructorName,
                    InstructorNameId = c.InstructorNameId
                });
                
                picklistSearchResults = new PagedResults(result, rowCount);
            }

            if (recentEntriesResult == null)
            {
                return picklistSearchResults;
            }

            return new PagedResultsWithRecent {Results = picklistSearchResults, RecentResults = recentEntriesResult};
        }

        async Task<dynamic> RecentResultsForTimeSheet(string search = "", int? nameKey = null, int take = 10)
        {
            var recentCasesInTimesheet = (await _recentCases.ForTimesheet(_securityContext.User.NameId, nameKey: nameKey, search: search, take: take)).ToArray();
            return recentCasesInTimesheet.Any() ? new PagedResults(recentCasesInTimesheet.Select(_ => _.ToCase()), recentCasesInTimesheet.Length) : null;
        }
    }
}