using System.ComponentModel;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using Inprotech.Web.Search;

namespace Inprotech.Web.Picklists
{
    public enum QueryType
    {
        All,
        Public,
        Private
    }

    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists")]
    public class SavedQueriesPicklistController : ApiController
    {
        readonly ISavedQueries _savedQueries;

        public SavedQueriesPicklistController(ISavedQueries savedQueries)
        {
            _savedQueries = savedQueries;
        }

        [HttpGet]
        [Route("dataDownloadCaseQueries")]
        public PagedResults<SavedQueryPicklistItem> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                           CommonQueryParameters queryParameters = null, string search = "")
        {
            var results = _savedQueries.Get(search, QueryContext.CaseSearch, QueryType.All)
                                       .Select(_ => new SavedQueryPicklistItem
                                       {
                                           Key = _.Key,
                                           Description = _.Description,
                                           Name = _.Name
                                       });

            return Helpers.GetPagedResults(results,
                                           queryParameters,
                                           null, x => x.Name, search);
        }

        public class SavedQueryPicklistItem
        {
            [PicklistKey]
            public int Key { get; set; }

            [PicklistDescription]
            public string Name { get; set; }

            [DisplayName(@"Description")]
            public string Description { get; set; }
        }
    }
}