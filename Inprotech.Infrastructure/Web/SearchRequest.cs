using System.Collections.Generic;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.SearchResults.Exporters;

namespace Inprotech.Infrastructure.Web
{
    public class SearchRequestParams<T>
    {
        public T Criteria { get; set; }
        public CommonQueryParameters Params { get; set; }
        public IEnumerable<SelectedColumn> SelectedColumns { get; set; }
        public QueryContext QueryContext { get; set; }
        public bool IsHosted { get; set; }
    }

    public class SavedSearchRequestParams<T> : SearchRequestParams<T>
    {
        public int? QueryKey { get; set; }
    }
    
    public class SearchExportParams<T> : SearchRequestParams<T>
    {
        public int? QueryKey { get; set; }
        public string SearchName { get; set; }
        public bool ForceConstructXmlCriteria { get; set; }
        public int[] DeselectedIds { get; set; }
        public int ContentId {get; set; }
        public ReportExportFormat ExportFormat { get; set; }
    }

    public class ColumnFilterParams<T> : SearchRequestParams<T>
    {
        public string Column { get; set; }
        public int? QueryKey { get; set; }
    }

    public class ColumnRequestParams
    {
        public int? QueryKey { get; set; }
        public string PresentationType { get; set; }
        public IEnumerable<SelectedColumn> SelectedColumns { get; set; }
        public QueryContext QueryContext { get; set; }
    }

    public class SelectedColumn
    {
        public int ColumnKey { get; set; }

        public int? DisplaySequence { get; set; }

        public int? SortOrder { get; set; }

        public string GroupBySortDirection { get; set; }

        public int? GroupBySortOrder { get; set; }

        public string SortDirection { get; set; }

        public bool IsFreezeColumnIndex { get; set; }
    }
}