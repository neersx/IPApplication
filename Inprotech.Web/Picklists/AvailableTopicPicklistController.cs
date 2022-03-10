using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Configuration;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/availableTopic")]
    public class AvailableTopicPicklistController : ApiController
    {
        static readonly Dictionary<string, string> TypeMap =
            new Dictionary<string, string>
            {
                {"T ", "workflows.entrycontrol.steps.textType"},
                {"C ", "workflows.entrycontrol.steps.checklistTypes"},
                {"N ", "workflows.entrycontrol.steps.nameType"},
                {"F ", "workflows.entrycontrol.steps.designationStage"},
                {"P ", "workflows.entrycontrol.steps.nameTypeGroup"},
                {"A ", "workflows.entrycontrol.steps.createAction"},
                {"R ", "workflows.entrycontrol.steps.relationship"},
                {"M ", "workflows.entrycontrol.steps.mandatoryRelationship"},
                {"G ", "workflows.entrycontrol.steps.general"},
                {"O ", "workflows.entrycontrol.steps.officialNumber"},
                {"X ", "workflows.entrycontrol.steps.nameText"}
            };

        readonly IAvailableTopicsReader _availableTopicsReader;
        readonly IResolvedCultureTranslations _translations;

        public AvailableTopicPicklistController(IAvailableTopicsReader availableTopicsReader, IResolvedCultureTranslations translations)
        {
            _availableTopicsReader = availableTopicsReader;
            _translations = translations;
        }

        [HttpGet]
        [Route]
        public PagedResults Topics([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null,
                                   string search = "", string forMode = "entryStep")
        {
            var isEntryStep = forMode == "entryStep";

            var categoryDescriptions = TypeMap.ToDictionary(k => k.Key, v => _translations[v.Value]);

            var result = _availableTopicsReader
                .Retrieve()
                .ToArray()
                .Select(_ => new AvailableTopic
                        {
                            Key = _.Key,
                            DefaultTitle = _.DefaultTitle,
                            IsWebEnabled = _.IsWebEnabled,
                            Type = _.Type,
                            TypeDescription = categoryDescriptions.Get(_.Type) ?? _.Type
                        });

            if (isEntryStep)
            {
                result = result.ForOnlyEntries()
                               .ExcludeDefaultExistingForEntry()
                               .ToArray();
            }

            if (string.IsNullOrWhiteSpace(queryParameters?.SortBy))
                result = result.OrderByDescending(_ => _.IsWebEnabled)
                               .ThenBy(_ => _.DefaultTitle)
                               .ToArray();

            if (!string.IsNullOrEmpty(search))
                result = result.Where(s =>s.DefaultTitle.IndexOf(search, StringComparison.InvariantCultureIgnoreCase) > -1);

            return Helpers.GetPagedResults(result,
                                           queryParameters,
                                           null, x => x.DefaultTitle, search);
        }
    }
}