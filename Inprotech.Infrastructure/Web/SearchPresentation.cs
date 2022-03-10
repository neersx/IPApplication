using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Infrastructure.Web
{
    public class SearchPresentation
    {
        public string ProcedureName { get; set; }
        public string XmlCriteria { get; set; }
        public string XmlFilterCriteria { get; set; }

        public List<ColumnFormat> ColumnFormats { get; set; }
        public List<OutputRequest> OutputRequests { get; set; }
        public List<SearchReport> SearchReports { get; set; }
        public List<ContextLink> ContextLinks { get; set; }
        public List<Program> Programs { get; set; }
        public QueryContext QueryContextKey { get; set; }

        public int UserId { get; set; }
        public string Culture { get; set; }

        public IEnumerable<ColumnFormat> FindAllColumnFormatByFormat(string format)
        {
            return
                ColumnFormats.Where(
                                    _ => string.Compare(_.Format, format, StringComparison.InvariantCultureIgnoreCase) == 0);
        }
    }

    public class ColumnFormat
    {
        public string Id { get; set; }
        public string ColumnItemId { get; set; }
        public string Title { get; set; }
        public string Format { get; set; }
        public int? DecimalPlaces { get; set; }
        public string CurrencyCodeColumnName { get; set; }
        public int Position { get; set; }
        public List<Link> Links { get; set; } = new List<Link>();
        public bool Filterable { get; set;  } = false;
        public bool IsColumnFreezed { get; set; } = false;
        public int? GroupBySortOrder { get; set; }
        public SortDirectionType? GroupBySortDirection { get; set; }
    }

    public class OutputRequest
    {
        public string Id { get; set; }
        public string Qualifier { get; set; }
        public string PublishName { get; set; }
        public int? SortOrder { get; set; }
        public SortDirectionType? SortDirection { get; set; }
        public int? GroupBySortOrder { get; set; }
        public SortDirectionType? GroupBySortDirection { get; set; }
        public bool IsFreezeColumnIndex { get; set; }
        public int? DocItemKey { get; set; }
        public string ProcedureName { get; set; }
    }

    public class SearchReport
    {
        public int QueryKey { get; set; }
        public string QueryName { get; set; }
        public string ReportTitle { get; set; }
        public string ReportTemplateName { get; set; }
    }

    public class ContextLink
    {
        public string Type { get; set; }
        public List<ContextArgument> ContextArguments { get; } = new List<ContextArgument>();
    }

    public class ContextArgument
    {
        public string Type { get; set; }
        public string Source { get; set; }
    }

    public enum ProgramType
    {
        Case,
        Name
    }

    public class Program
    {
        public ProgramType ProgramType { get; set; }
        public string ProgramKey { get; set; }
        public string ProgramName { get; set; }
        public bool IsDefault { get; set; }
    }

    public enum SortDirectionType
    {
        Ascending,
        Descending
    }

    public class Link
    {
        public string Id { get; set; }
        public string Type { get; set; }
        public List<LinkArgument> LinkArguments { get; } = new List<LinkArgument>();
    }

    public class LinkArgument
    {
        public string Id { get; set; }
        public string Source { get; set; }
    }
}
