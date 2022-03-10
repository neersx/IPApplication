using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Queries
{
    public class SearchResults
    {
        public int RowCount { get; set; }
        public int? TotalRows { get; set; }
        public List<Dictionary<string, object>> Rows { get; set; }
        public string XmlCriteriaExecuted { get; set; }
    }
}
