using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/Keywords")]
    public class KeywordsPicklistController : ApiController
    {
        readonly IDbContext _dbContext;

        public KeywordsPicklistController(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(Keyword))]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        public PagedResults Get([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                                    = null, string search = "", string mode = "all")
        {
            var result = _dbContext.Set<InprotechKaizen.Model.Keywords.Keyword>().Select(_ => new Keyword
            {
                Key = _.KeyWord,
                Id = _.KeywordNo,
                CaseStopWord = _.StopWord == 1 || _.StopWord == 3,
                NameStopWord = _.StopWord == 2 || _.StopWord == 3
            }).OrderBy(_ => _.Key).ToArray();

            if (!string.IsNullOrWhiteSpace(search))
            {
                result = result.Where(_ => _.Key.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) >= 0).ToArray();
            }

            return Helpers.GetPagedResults(result,
                                           queryParameters ?? new CommonQueryParameters(),
                                           x => x.Key, x => x.Key, search);
        }
    }

    public class Keyword
    {
        [PicklistKey]
        [DisplayName("keyword")]
        [DisplayOrder(0)]
        public string Key { get; set; }

        [PicklistCode]
        public int Id { get; set; }

        [DisplayName("caseStopWord")]
        [DisplayOrder(1)]
        [DataType("boolean")]
        public bool CaseStopWord { get; set; }

        [DisplayName("nameStopWord")]
        [DisplayOrder(2)]
        [DataType("boolean")]
        public bool NameStopWord { get; set; }
    }
}