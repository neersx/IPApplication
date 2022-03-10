using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/kot-status")]
    public class KotStatusPicklistController : ApiController
    {
        static readonly CommonQueryParameters DefaulQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Name"
            });

        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IStaticTranslator _staticTranslator;

        public KotStatusPicklistController(IPreferredCultureResolver preferredCultureResolver, IStaticTranslator staticTranslator)
        {
            _preferredCultureResolver = preferredCultureResolver;
            _staticTranslator = staticTranslator;
        }

        [HttpGet]
        [Route("meta")]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        public PagedResults KotStatus(string search = "", [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            if (search == null)
            {
                search = string.Empty;
            }

            queryParameters = DefaulQueryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var status = GetTranslatedStatus()
                .Select(_ => new KotStatusPicklistItem
                {
                    Name = _.Value,
                    Key = _.Key
                });

            if (!string.IsNullOrWhiteSpace(search))
            {
                status = status.Where(_ => _.Name.ToLower().Contains(search.ToLower()));
            }

            return Helpers.GetPagedResults(status,
                                           queryParameters ?? new CommonQueryParameters(),
                                           x => x.Key.ToString(), x => x.Name, search);
        }

        IDictionary<string, string> GetTranslatedStatus()
        {
            var cultures = _preferredCultureResolver.ResolveAll().ToArray();
            var collection = new Dictionary<string, string>
            {
                {KnownKotCaseStatus.Registered, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.registered", cultures)},
                {KnownKotCaseStatus.Pending, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.pending", cultures)},
                {KnownKotCaseStatus.Dead, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.dead", cultures)}
            };

            return collection;
        }

    }

    public class KotStatusPicklistItem
    {
        [PicklistKey]
        public string Key { get; set; }

        [PicklistDescription]
        public string Name { get; set; }
    }
}
