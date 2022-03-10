using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Case;

namespace Inprotech.Web.Portal
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/recentCases")]
    [RequiresAccessTo(ApplicationTask.RunSavedCaseSearch)]
    public class RecentCasesController : ApiController
    {
        readonly ICaseSearchService _caseSearchService;
        readonly IListPrograms _listCasePrograms;

        public RecentCasesController(ICaseSearchService caseSearchService, IListPrograms listCasePrograms)
        {
            _caseSearchService = caseSearchService;
            _listCasePrograms = listCasePrograms;
        }

        [HttpGet]
        public async Task<SearchResult> Get([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters)
        {
            queryParameters.Take = 50;
            return await _caseSearchService.GetRecentCaseSearchResult(queryParameters);
        }

        [HttpGet]
        [Route("defaultProgram")]
        public string GetDefaultProgram()
        {
            return _listCasePrograms.GetDefaultCaseProgram();
        }
    }
}