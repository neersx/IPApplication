using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;

namespace Inprotech.Infrastructure.Web
{
    public class CommonQueryParameters
    {
        public const int DefaultSkip = 0;
        public const int DefaultTake = 20;
        public const string DefaultSortBy = "Id";
        public const string DefaultSortDir = "asc";

        public CommonQueryParameters()
        {
            Filters = Enumerable.Empty<FilterValue>();
        }

        public string SortBy { get; set; }
        public string SortDir { get; set; }
        public int? Skip { get; set; }
        public int? Take { get; set; }
        public bool GetAllIds { get; set; }
        public IEnumerable<FilterValue> Filters { get; set; }
        public bool FilterEmpty { get; set; }

        public CommonQueryParameters Extend(CommonQueryParameters settings, bool isSearch = false)
        {
            var retval = new CommonQueryParameters
                   {
                       Skip = settings?.Skip ?? Skip,
                       Take = settings?.Take ?? Take,
                       GetAllIds = (settings?.GetAllIds).GetValueOrDefault(),
                       Filters = settings?.Filters ?? Filters
                   };

            if (isSearch)
            {
                // when searching, advanced sorting will be applied
                retval.SortBy = settings?.SortBy;
                retval.SortDir = settings?.SortDir;
            }
            else
            {
                retval.SortBy = settings?.SortBy ?? SortBy;
                retval.SortDir = settings?.SortDir ?? SortDir;
            }

            return retval;
        }

        public static CommonQueryParameters Default => new CommonQueryParameters
                                                       {
                                                           SortBy = DefaultSortBy,
                                                           SortDir = DefaultSortDir,
                                                           Skip = DefaultSkip,
                                                           Take = DefaultTake
                                                       };

        public class FilterValue
        {
            public string Operator { get; set; }

            public string Field { get; set; }

            public string Value { get; set; }

            public string Type { get; set; }

            public DateTime? DateTimeValue
            {
                get
                {
                    if (string.IsNullOrWhiteSpace(Type))
                        return null;

                    if (string.IsNullOrWhiteSpace(Value))
                        return null;

                    if (string.Compare(Type, "date", StringComparison.OrdinalIgnoreCase)!=0)
                        return null;
                    
                    return DateTime.ParseExact(Value, "yyyy-MM-dd", CultureInfo.InvariantCulture);
                }
            }
        }
    }

    public static class CommonQueryParametersExtension
    {
        public static CommonQueryParameters RemapFilter(this CommonQueryParameters parameters, string originalField, string targetField)
        {
            var f = parameters.Filters.FirstOrDefault(_ => string.Compare(_.Field, originalField, StringComparison.InvariantCultureIgnoreCase) == 0);
            if (f != null)
            {
                f.Field = targetField;
            }

            return parameters;
        }

        public static CommonQueryParameters RemapSortField(this CommonQueryParameters parameters, string originalField, string targetField)
        {
            if (string.IsNullOrWhiteSpace(parameters.SortBy))
                return parameters;

            if (string.Compare(parameters.SortBy, originalField, StringComparison.InvariantCultureIgnoreCase) == 0)
                parameters.SortBy = targetField;

            return parameters;
        }

        public static CommonQueryParameters RemapAll(this CommonQueryParameters parameters, string originalField, string targetField)
        {
            return parameters
                .RemapFilter(originalField, targetField)
                .RemapSortField(originalField, targetField);
        }

        public static CommonQueryParameters RemapAll(this CommonQueryParameters parameters, Dictionary<string, string> originalThenTarget)
        {
            foreach (var pair in originalThenTarget)
            {
                parameters = parameters.RemapAll(pair.Key, pair.Value);
            }

            return parameters;
        }
    }
}