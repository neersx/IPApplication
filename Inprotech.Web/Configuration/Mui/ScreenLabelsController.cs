using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Translation;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Mui
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/system")]
    public class ScreenLabelsController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ISiteConfiguration _siteConfiguration;
        readonly ITranslationSource _source;
        readonly IResourceFile _resourceFile;
        readonly ICommonQueryService _commonQueryService;

        public ScreenLabelsController(IDbContext dbContext,
                                      ISiteConfiguration siteConfiguration,
                                      ITranslationSource source,
                                      IResourceFile resourceFile,
                                      ICommonQueryService commonQueryService)
        {
            _dbContext = dbContext;
            _siteConfiguration = siteConfiguration;
            _source = source;
            _resourceFile = resourceFile;
            _commonQueryService = commonQueryService;
        }

        [HttpGet]
        [Route("mui/view")]
        public IEnumerable<dynamic> ViewData()
        {
            var supportedCulture = _dbContext.Set<TableCode>()
                                             .Where(_ => _.UserCode != null && _.TableTypeId == (short)TableTypes.Language)
                                             .Select(_ => _.UserCode)
                                             .Distinct()
                                             .ToArray();

            var candidates = CultureInfo.GetCultures(CultureTypes.AllCultures)
                                        .Where(culture =>
                                                   supportedCulture.Contains(culture.Name) ||
                                                   (!culture.IsNeutralCulture && supportedCulture.Contains(culture.Parent.Name)))
                                        .ToDictionary(culture => culture.Name,
                                                      culture => new
                                                                 {
                                                                     IsNeutral = culture.IsNeutralCulture,
                                                                     Description = culture.DisplayName + " (" + culture.Name + ")"
                                                                 });

            var neutral = candidates.Where(_ => _.Value.IsNeutral).OrderBy(_ => _.Value.Description);
            var specific = candidates.Where(_ => _.Value.IsNeutral == false).OrderBy(_ => _.Value.Description);
            var siteLanguage = _siteConfiguration.DatabaseLanguageCode;

            return neutral.Union(specific)
                          .Select(_ => new
                                       {
                                           Culture = _.Key,
                                           _.Value.Description,
                                           Default = _.Key == siteLanguage
                                       });
        }

        [HttpGet]
        [Route("mui/search")]
        public async Task<PagedResults> Search(
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "q")] SearchCriteria filter,
            [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            var results = new List<TranslatableItem>();

            results.AddRange(await _source.Fetch(filter.Language));

            var areaAndId = results.Where(_ => _.ResourceKey.StartsWith("screenlabels.area"))
                                   .ToDictionary(k => k.Id, v => v.Default);

            if (filter.IsRequiredTranslationsOnly)
                results = results.Where(_ => string.IsNullOrWhiteSpace(_.Translated)).ToList();

            if (!string.IsNullOrWhiteSpace(filter.Text))
            {
                var filterByArea = areaAndId.Where(_ => _.Value.TextContains(filter.Text))
                                            .Select(_ => _.Key.Replace("condor-screenlabels","screenlabels")).ToArray();

                results = results
                    .Where(_ =>
                               _.ResourceKey.TextContains(filter.Text) ||
                               _.Translated.TextContains(filter.Text) ||
                               _.Default.TextContains(filter.Text) ||
                               filterByArea.Any(fa => fa.StartsWith(_.AreaKey, StringComparison.InvariantCultureIgnoreCase)))
                    .ToList();
            }

            var qp = (queryParameters ?? new CommonQueryParameters())
                .RemapAll(new Dictionary<string, string>
                          {
                              {"areaKey", "Area"},
                              {"original", "Default"},
                              {"key", "ResourceKey"},
                              {"translation", "Translated"}
                          });

            return _commonQueryService.Filter(results, qp)
                                      .OrderByProperty(qp.SortBy, qp.SortDir)
                                      .AsPagedResults(qp);
        }

        [HttpPut]
        [Route("mui")]
        public async Task<dynamic> Save(ScreenLabelChanges changes)
        {
            await _source.Save(changes);

            return "success";
        }

        [HttpGet]
        [Route("mui/export")]
        [NoEnrichment]
        public Task<HttpResponseMessage> Export()
        {
            var keys = new Dictionary<string, string> {{_source.Name, _source.ExportStartPath}};
            var response = new HttpResponseMessage(HttpStatusCode.OK)
                           {
                               Content = new StreamContent(File.OpenRead(_resourceFile.Export(keys)))
                           };

            response.Content.Headers.ContentType = new MediaTypeHeaderValue("application/zip");
            response.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment") {FileName = "Resources.zip"};
            return Task.FromResult(response);
        }
    }

    public class SearchCriteria
    {
        public string Language { get; set; }

        public bool IsRequiredTranslationsOnly { get; set; }

        public string Text { get; set; }
    }
}