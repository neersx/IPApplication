using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Search.Export;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Search
{
    public interface ISearchExportService
    {
        Task Export<T>(SearchExportParams<T> searchExportParams) where T : SearchRequestFilter;
    }

    public class SearchExportService : ISearchExportService
    {
        readonly IExportSettings _exportSettings;
        readonly ISearchService _searchService;
        readonly ISecurityContext _securityContext;
        readonly IBus _bus;

        public SearchExportService(ISearchService searchService, IExportSettings exportSettings,
                                    ISecurityContext securityContext, IBus bus)
        {
            _searchService = searchService;
            _exportSettings = exportSettings;
            _securityContext = securityContext;
            _bus = bus;
        }

        public async Task Export<T>(SearchExportParams<T> searchExportParams) where T : SearchRequestFilter
        {
            if (searchExportParams?.Criteria == null) throw new ArgumentNullException(nameof(searchExportParams));
            
            var maxRowsToExport = _exportSettings.GetExportLimitorDefault(searchExportParams.ExportFormat);

            var queryParameters = searchExportParams.Params ?? new CommonQueryParameters();
            queryParameters.Take = maxRowsToExport ?? int.MaxValue;

            var exportData = await _searchService.GetSearchExportData(
                                                                      searchExportParams.Criteria,
                                                                      queryParameters,
                                                                      searchExportParams.QueryKey,
                                                                      searchExportParams.QueryContext,
                                                                      searchExportParams.SelectedColumns,
                                                                      searchExportParams.ForceConstructXmlCriteria);
            var exportRequest = new ExportRequest
            {
                ExportFormat = searchExportParams.ExportFormat,
                Columns = exportData.Presentation.ColumnFormats
                                    .Select(x => new Infrastructure.SearchResults.Exporters.Column
                                    {
                                        Name = x.Id,
                                        Title = x.Title,
                                        Format = x.Format,
                                        DecimalPlaces = x.DecimalPlaces,
                                        CurrencyCodeColumnName = x.CurrencyCodeColumnName,
                                        ColumnItemId = x.ColumnItemId
                                    }),
                Rows = exportData.SearchResults.Rows,
                SearchPresentation = exportData.Presentation,
                SearchExportContentId = searchExportParams.ContentId,
                RunBy = _securityContext.User.Id
            };

            var settings = _exportSettings.Load(searchExportParams.SearchName, searchExportParams.QueryContext);
            settings.ExportLimitedToNbRecords = exportData.SearchResults.RowCount <= maxRowsToExport
                ? null
                : maxRowsToExport;

            var args = new ExportExecutionJobArgs
            {
                ExportRequest = exportRequest,
                Settings = settings
            };

            await _bus.PublishAsync(args);
        }

    }
}