using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using Newtonsoft.Json;

namespace Inprotech.Web.Configuration.Search
{
    [Authorize]
    [RoutePrefix("api/configuration/search")]
    public class ConfigurationSearchController : ApiController
    {
        static readonly CommonQueryParameters DefaultQueryParameters = new CommonQueryParameters
        {
            SortBy = "name",
            SortDir = "asc",
            Skip = 0,
            Take = 50
        };

        readonly ICommonQueryService _commonQueryService;

        readonly IConfigurableItems _configurableItems;
        readonly ISecurityContext _securityContext;

        public ConfigurationSearchController(ISecurityContext securityContext,
            ICommonQueryService commonQueryService,
            IConfigurableItems configurableItems)
        {
            _securityContext = securityContext;
            _commonQueryService = commonQueryService;
            _configurableItems = configurableItems;
        }

        [HttpGet]
        [Route("view")]
        [NoEnrichment]
        public dynamic GetViewData()
        {
            return new
            {
                CanUpdate = !_securityContext.User.IsExternalUser && _configurableItems.Any()
            };
        }

        [HttpGet]
        [Route("")]
        [NoEnrichment]
        public async Task<PagedResults> Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] ConfigurationSearchOptions searchOptions,
                                               [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            queryParameters = DefaultQueryParameters.Extend(queryParameters);
            searchOptions = searchOptions ?? new ConfigurationSearchOptions();

            var items = await _configurableItems.Retrieve();

            if (!string.IsNullOrWhiteSpace(searchOptions.Text))
            {
                items = items.Where(_ => _.Name.IgnoreCaseContains(searchOptions.Text) || _.Description.IgnoreCaseContains(searchOptions.Text));
            }

            if (searchOptions.ComponentIds.Any())
            {
                items = items.Where(_ => _.Components.Select(c => c.Id).Cast<int>().Any(c => searchOptions.ComponentIds.Contains(c)));
            }

            if (searchOptions.TagIds.Any())
            {
                items = items.Where(_ => _.Tags.Select(t => t.Id).Any(t => searchOptions.TagIds.Contains(t)));
            }

            if (queryParameters.Filters.Any())
            {
                items = _commonQueryService.Filter(items, queryParameters);
            }

            return (from item in items
                    select new ConfigItem
                    {
                        Id = item.Id,
                        Ids = item.Ids,
                        GroupId = item.GroupId,
                        Name = item.Name,
                        Description = item.Description,
                        DefaultUrl = item.Url,
                        Tags = item.Tags,
                        IeOnly = item.IeOnly,
                        Components = string.Join(", ", item.Components.Select(_ => _.ComponentName).OrderBy(_ => _))
                    })
                .OrderByProperty(queryParameters.SortBy, queryParameters.SortDir)
                .AsPagedResults(queryParameters);
        }
    }

    public class CasesData
    {
        public int CaseId { get; set; }
        public string Irn { get; set; }
        public string Title { get; set; }
        public string Country { get; set; }
        public string CaseType { get; set; }
        public string PropertyType { get; set; }

    }

    public class ConfigurationSearchOptions
    {
        public ConfigurationSearchOptions()
        {
            ComponentIds = Enumerable.Empty<int>();
            TagIds = Enumerable.Empty<int>();
        }

        public string Text { get; set; }

        public IEnumerable<int> ComponentIds { get; set; }

        public IEnumerable<int> TagIds { get; set; }
    }

    public class ConfigItem
    {
        public int? Id { get; set; }

        public IEnumerable<int> Ids { get; set; }

        public int? GroupId { get; set; }

        public string Name { get; set; }

        public string Description { get; set; }

        [JsonIgnore]
        public string DefaultUrl { get; set; }

        public string Url => !string.IsNullOrWhiteSpace(DefaultUrl)
            ? DefaultUrl.Substring(6)
            : $"../default.aspx?ConfigFor={Id}";

        public bool Legacy => string.IsNullOrWhiteSpace(DefaultUrl);

        public string Components { get; set; }

        public IEnumerable<Tag> Tags { get; set; }

        public string RowKey => $"{Id}^{string.Join(",", Ids)}^{GroupId}";

        public bool IeOnly { get; set; }
    }
}