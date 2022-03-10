using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Search.Case.GlobalCaseChange
{
    public class GlobalCaseChangeRequestParam
    {
        public int GlobalProcessKey { get; set; }
        public string PresentationType { get; set; }
        public CommonQueryParameters Params { get; set; }
        public string SearchName { get; set; }
        public int? QueryContext { get; set; }
        public ReportExportFormat ExportFormat { get; set; }
    }

    [Authorize]
    [RoutePrefix("api/globalCaseChangeResults")]
    public class GlobalCaseChangeResultsController : ApiController
    {
        readonly ICaseSearchService _caseSearch;
        readonly IExportSettings _exportSettings;
        readonly ISearchResultsExport _searchExporter;

        public GlobalCaseChangeResultsController(ICaseSearchService caseSearch, IExportSettings exportSettings, ISearchResultsExport searchExporter)
        {
            _caseSearch = caseSearch;
            _exportSettings = exportSettings;
            _searchExporter = searchExporter;
        }

        [HttpPost]
        [Route("")]
        [NoEnrichment]
        public async Task<SearchResult> RunSearch(GlobalCaseChangeRequestParam globalCaseChangeRequestParam)
        {
            if (globalCaseChangeRequestParam == null)
            {
                throw new ArgumentNullException(nameof(globalCaseChangeRequestParam));
            }

            var queryParameters = globalCaseChangeRequestParam.Params;
            queryParameters = queryParameters ?? new CommonQueryParameters();

            return await _caseSearch.GlobalCaseChangeResults(queryParameters, globalCaseChangeRequestParam.GlobalProcessKey, globalCaseChangeRequestParam.PresentationType);
        }

        [HttpPost]
        [Route("export")]
        [NoEnrichment]
        public async Task<IHttpActionResult> Export(GlobalCaseChangeRequestParam globalCaseChangeRequestParam)
        {
            if (globalCaseChangeRequestParam == null) throw new ArgumentNullException(nameof(globalCaseChangeRequestParam));

            var queryParameters = globalCaseChangeRequestParam.Params;
            queryParameters = queryParameters ?? new CommonQueryParameters();

            var maxRowsToExport = _exportSettings.GetExportLimitorDefault(globalCaseChangeRequestParam.ExportFormat);
            queryParameters.Take = maxRowsToExport ?? int.MaxValue;

            var exportData = await _caseSearch.GlobalCaseChangeResultsExportData(queryParameters,
                                                                                 globalCaseChangeRequestParam.GlobalProcessKey,
                                                                                 globalCaseChangeRequestParam.PresentationType);
            var exportRequest = new ExportRequest
            {
                ExportFormat = globalCaseChangeRequestParam.ExportFormat,
                Columns = exportData.Presentation.ColumnFormats
                                    .Select(x => new Infrastructure.SearchResults.Exporters.Column
                                    {
                                        Name = x.Id,
                                        Title = x.Title,
                                        Format = x.Format,
                                        DecimalPlaces = x.DecimalPlaces,
                                        CurrencyCodeColumnName = x.CurrencyCodeColumnName
                                    }),
                Rows = exportData.SearchResults.Rows,
                SearchPresentation = exportData.Presentation
            };

            var settings = _exportSettings.Load(globalCaseChangeRequestParam.SearchName, QueryContext.CaseSearch);
            settings.ExportLimitedToNbRecords = exportData.SearchResults.TotalRows <= maxRowsToExport
                ? null
                : maxRowsToExport;

            var exportResult = await _searchExporter.Export(exportRequest, settings);

            return new FileStreamResult(exportResult, Request);
        }
    }
}