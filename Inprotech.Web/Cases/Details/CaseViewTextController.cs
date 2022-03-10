using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class CaseViewTextController : ApiController
    {
        static readonly CommonQueryParameters DefaultQueryParameters = new CommonQueryParameters
        {
            SortDir = "asc",
            Skip = 0,
            Take = 10
        };

        static readonly TextTypeFilterQuery DefaultTextTypeFilterQuery = new TextTypeFilterQuery();

        readonly ICaseTextSection _caseTextSection;

        public CaseViewTextController(ICaseTextSection caseTextSection)
        {
            _caseTextSection = caseTextSection;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/texts")]
        public async Task<PagedResults> GetCaseTexts(int caseKey,
                                                     [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                     CommonQueryParameters qp = null,
                                                     [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "textTypes")]
                                                     TextTypeFilterQuery textTypes = null)
        {
            var queryParameters = DefaultQueryParameters.Extend(qp);

            var textTypeKeys = DefaultTextTypeFilterQuery.Extend(textTypes).ValidTextTypeKeys;

            return (await _caseTextSection.Retrieve(caseKey, textTypeKeys))
                   .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir)
                   .AsPagedResults(queryParameters);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/textHistory")]
        public async Task<CaseHistoryDataModel> GetCaseTextHisoty(int caseKey, string textType, int? language = null, string textClass = "")
        {
            return await _caseTextSection.GetHistoryData(caseKey, textType, textClass, language);
        }
    }

    public class TextTypeFilterQuery
    {
        public TextTypeFilterQuery()
        {
            Keys = new List<string>();
        }

        public IEnumerable<string> Keys { get; set; }

        public TextTypeFilterQuery Extend(TextTypeFilterQuery query)
        {
            if (query == null)
            {
                return this;
            }

            if (query.Keys == null)
            {
                query.Keys = new string[0];
            }

            return query;
        }

        public string[] ValidTextTypeKeys => Keys.Where(_ => !string.IsNullOrWhiteSpace(_)).ToArray();
    }
}