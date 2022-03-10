using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Search
{
    public class SearchResult
    {
        public class Column
        {
            public string Id { get; set; }
            public string Title { get; set; }
            public string Format { get; set; }
            public int? DecimalPlaces { get; set; }
            public string CurrencyCodeColumnName { get; set; }
            public bool IsHyperlink { get; set; }
            public bool Filterable { get; set; }
            public string FieldId { get; set; }
            public string ColumnItemId { get; set; }
            public string LinkType { get; set; }
            public IEnumerable<string> LinkArgs { get; set; }
            public bool IsColumnFreezed {get; set;}
            public int? GroupBySortOrder { get; set; }
            public SortDirectionType? GroupBySortDirection { get; set; }
            public Column()
            {
                LinkArgs = Enumerable.Empty<string>();
            }
        }

        public string XmlCriteriaExecuted { get; set; }
        public int TotalRows { get; set; }
        public IEnumerable<Column> Columns { get; set; }
        public IEnumerable<Dictionary<string, object>> Rows { get; set; }
    }

    public static class ColumnFormatExtension
    {
        public static IEnumerable<SearchResult.Column> ToSearchColumn(this IEnumerable<ColumnFormat> columnFormats)
        {
            return columnFormats.Select(x => new SearchResult.Column
            {
                Id = x.Id.ToLower(),
                FieldId = x.Id,
                ColumnItemId = x.ColumnItemId,
                Title = x.Title,
                Format = x.Format,
                DecimalPlaces = x.DecimalPlaces,
                CurrencyCodeColumnName = x.CurrencyCodeColumnName.ToCamelCase(),
                IsHyperlink = x.Links != null && x.Links.Count > 0,
                LinkType = x.Links?.FirstOrDefault()?.Type,
                LinkArgs = x.Links?.FirstOrDefault()?.LinkArguments?.Select(_ => _.Source.ToCamelCase()),
                Filterable = x.Filterable,
                IsColumnFreezed = x.IsColumnFreezed,
                GroupBySortOrder = x.GroupBySortOrder,
                GroupBySortDirection = x.GroupBySortDirection
            }).ToList();
        }

    }
}
