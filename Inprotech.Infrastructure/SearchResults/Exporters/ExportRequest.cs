using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Web;
using System.Collections.Generic;

namespace Inprotech.Infrastructure.SearchResults.Exporters
{
    public class ExportRequest
    {
        public int SearchExportContentId { get; set; }
        public int RunBy { get; set; }
        public ReportExportFormat ExportFormat { get; set; }
        public IEnumerable<Column> Columns { get; set; }
        public List<Dictionary<string, object>> Rows { get; set; }
        public ExportAdditionalInfo AdditionalInfo { get; set; }
        public SearchPresentation SearchPresentation { get; set; }
    }
}
