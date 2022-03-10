using System;
using System.IO;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Infrastructure.SearchResults.Exporters.Pdf;
using Inprotech.Infrastructure.SearchResults.Exporters.Word;

namespace Inprotech.Infrastructure.SearchResults.Exporters
{
    public interface ISearchResultsExport
    {
        Task<ExportResult> Export(ExportRequest searchExportRequest, SearchResultsSettings settings);
    }

    public class SearchResultsExport : ISearchResultsExport
    {
        readonly IImageSettings _imageSettings;
        readonly IUserColumnUrlResolver _userColumnUrlResolver;

        public SearchResultsExport(IImageSettings imageSettings, IUserColumnUrlResolver userColumnUrlResolver)
        {
            _imageSettings = imageSettings;
            _userColumnUrlResolver = userColumnUrlResolver;
        }

        public async Task<ExportResult> Export(ExportRequest searchResultsExportRequest, SearchResultsSettings settings)
        {
            if (searchResultsExportRequest == null)
            {
                throw new ArgumentNullException(nameof(searchResultsExportRequest));
            }

            if (searchResultsExportRequest.SearchPresentation != null)
            {
                _imageSettings.Load(searchResultsExportRequest.SearchPresentation, searchResultsExportRequest.Rows);
            }

            var searchResults = new SearchResults
            {
                Columns = searchResultsExportRequest.Columns,
                Rows = searchResultsExportRequest.Rows,
                AdditionalInfo = searchResultsExportRequest.AdditionalInfo
            };

            Export export;
            switch (searchResultsExportRequest.ExportFormat)
            {
                case ReportExportFormat.Excel:
                    export = new ExcelExport(settings, searchResults, _imageSettings, _userColumnUrlResolver);
                    break;
                case ReportExportFormat.Word:
                    export = new WordExport(settings, searchResults, _imageSettings, _userColumnUrlResolver);
                    break;
                default:
                    export = new PdfExport(settings, searchResults, _imageSettings, _userColumnUrlResolver);
                    break;
            }

            var exportResult = new ExportResult
            {
                FileName = $"{settings.ReportFileName}.{export.FileNameExtension}"
            };

            using(var output = new MemoryStream())
            {
                export.Execute(output);
                exportResult.Content = new byte[output.Length];
                await output.ReadAsync(exportResult.Content, 0, exportResult.Content.Length);
            }

            exportResult.ContentType = export.ContentType;
            exportResult.ContentLength = exportResult.Content.Length;

            return exportResult;
        }
    }
}