using System;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using Inprotech.Web.Search;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/CopyPresentation")]
    public class CopyPresentationPicklistController : ApiController
    {
        readonly ISavedQueries _savedQueries;

        public CopyPresentationPicklistController(ISavedQueries savedQueries)
        {
            _savedQueries = savedQueries;
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(CaseFamily))]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        public dynamic Get([ModelBinder(BinderType = typeof (JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters
                                    = null, string search = "", int? queryContextKey = null)
        {
            if (queryContextKey == null)
                throw new ArgumentNullException(nameof(queryContextKey));

            var data = _savedQueries.GetSavedPresentationQueries(queryContextKey.Value);
            var result = data.Select(x => new SavedPresentation
            {
                Key = x.Key.ToString(),
                Value = x.Name,
                GroupName = x.GroupName == null ? string.Empty : x.GroupName
            }).ToArray();

            if (!string.IsNullOrWhiteSpace(search))
            {
                result = result.Where(_ => _.Value.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) >= 0
                                            || _.GroupName.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) >= 0).ToArray();
            }

            return Helpers.GetPagedResults(result,
                                           queryParameters ?? new CommonQueryParameters(),
                                           x => x.Key, x => x.Value, search);
        }
    }

    public class SavedPresentation
    {

        [PicklistKey]
        public string Key { get; set; }

        [DisplayOrder(0)]
        public string Value { get; set; }

        [DisplayOrder(1)]
        public string GroupName { get; set; }

    }
}
