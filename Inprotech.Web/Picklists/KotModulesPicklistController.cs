using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists.ResponseShaping;
using InprotechKaizen.Model;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/modules")]
    public class KotModulesPicklistController : ApiController
    {
        static readonly CommonQueryParameters DefaulQueryParameters =
            CommonQueryParameters.Default.Extend(new CommonQueryParameters
            {
                SortBy = "Name"
            });

        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IStaticTranslator _staticTranslator;

        public KotModulesPicklistController(IPreferredCultureResolver preferredCultureResolver, IStaticTranslator staticTranslator)
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
        public PagedResults Modules(string search = "", [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            if (search == null)
            {
                search = string.Empty;
            }

            queryParameters = DefaulQueryParameters.Extend(queryParameters, !string.IsNullOrEmpty(search));

            var modules = GetTranslatedModules()
                                 .Select(_ => new ModulePicklistItem
                                 {
                                     Name = _.Value,
                                     Key = _.Key
                                 });

            if (!string.IsNullOrWhiteSpace(search))
            {
                modules = modules.Where(_ => _.Name.ToLower().Contains(search.ToLower()));
            }

            return Helpers.GetPagedResults(modules,
                                           queryParameters ?? new CommonQueryParameters(),
                                           x => x.Key.ToString(), x => x.Name, search);
        }

        IDictionary<string, string> GetTranslatedModules()
        {
            var cultures = _preferredCultureResolver.ResolveAll().ToArray();
            var collection = new Dictionary<string, string>
            {
                {KnownKotModules.Case, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.caseProgram", cultures)},
                {KnownKotModules.Name, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.nameProgram", cultures)},
                {KnownKotModules.Time, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.timeProgram", cultures)},
                {KnownKotModules.TaskPlanner, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.taskPlannerProgram", cultures)},
                {KnownKotModules.Billing, _staticTranslator.TranslateWithDefault("kotTextTypes.maintenance.billingProgram", cultures)}
            };

            return collection;
        }

    }

    public class ModulePicklistItem
    {
        [PicklistKey]
        public string Key { get; set; }

        [PicklistDescription]
        public string Name { get; set; }
    }
}

