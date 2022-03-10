using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Infrastructure.SearchResults.Exporters
{
    public interface IExportSettings
    {
        SearchResultsSettings Load(string searchName, QueryContext queryContext);
        int? GetExportLimitorDefault(ReportExportFormat reportExportFormat);
    }
}
