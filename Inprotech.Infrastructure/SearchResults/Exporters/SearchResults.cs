using System.Collections.Generic;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Infrastructure.SearchResults.Exporters
{
    public class SearchResults
    {
        public IEnumerable<Column> Columns { get; set; }
        public IEnumerable<Dictionary<string, object>> Rows { get; set; }
        public ExportAdditionalInfo AdditionalInfo { get; set; }
        public QueryContext QueryContext { get; set; }
    }
}
