using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Picklists;

namespace Inprotech.Web.Configuration.Keywords
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/keywords")]
    public class KeywordsController : ApiController
    {
        readonly IKeywords _keywordService;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        static readonly CommonQueryParameters DefaultQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "KeyWord",
                SortDir = "asc"
            });

        public KeywordsController(IKeywords keywordService, ITaskSecurityProvider taskSecurityProvider)
        {
            _keywordService = keywordService;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [HttpGet]
        [Route("viewdata")]
        [NoEnrichment]
        public dynamic ViewData()
        {
            return new
            {
                CanAdd = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainKeyword, ApplicationTaskAccessLevel.Create),
                CanDelete = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainKeyword, ApplicationTaskAccessLevel.Delete),
                CanEdit = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainKeyword, ApplicationTaskAccessLevel.Modify)
            };
        }

        [HttpGet]
        [Route("{keywordNo}")]
        public async Task<KeywordItems> GetKeyWordDetails(int keywordNo)
        {
            return await _keywordService.GetKeywordByNo(keywordNo);
        }

        [HttpGet]
        [Route("")]
        public async Task<PagedResults> GetKeyWords(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] SearchOptions searchOptions,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters qp)
        {

            var queryParameters = DefaultQueryParameters.Extend(qp);
            var all = await _keywordService.GetKeywords();

            if (!String.IsNullOrEmpty(searchOptions?.Text))
            {
                all = all.Where(_ => _.KeyWord.IndexOf(searchOptions.Text, StringComparison.InvariantCultureIgnoreCase) > -1);
            }

            var result = Helpers.GetPagedResults(all, queryParameters, x => x.KeywordNo.ToString(), x => x.KeywordNo.ToString(), searchOptions.Text);
            result.Ids = result.Data.Select(_ => _.KeywordNo);
            return result;
        }

        [HttpPost]
        [Route("")]
        [RequiresAccessTo(ApplicationTask.MaintainKeyword, ApplicationTaskAccessLevel.Create)]
        public async Task<dynamic> AddKeywords(KeywordItems request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return await _keywordService.SubmitKeyWordForm(request);
        }

        [HttpPut]
        [Route("{id}")]
        [RequiresAccessTo(ApplicationTask.MaintainKeyword, ApplicationTaskAccessLevel.Modify)]
        public async Task<dynamic> UpdateKeywords(KeywordItems request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return await _keywordService.SubmitKeyWordForm(request);
        }

        [HttpDelete]
        [Route("delete")]
        [RequiresAccessTo(ApplicationTask.MaintainKeyword, ApplicationTaskAccessLevel.Delete)]
        public async Task<dynamic> DeleteKeywords(DeleteRequestModel request)
        {
            if (request == null) throw new ArgumentNullException(nameof(request));
            return await _keywordService.DeleteKeywords(request);
        }
    }
}
