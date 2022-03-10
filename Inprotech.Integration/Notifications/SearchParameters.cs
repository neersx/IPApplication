using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Integration.Notifications
{
    public class SearchParameters
    {
        public SearchParameters()
        {
            DataSourceTypes = new DataSourceType[0];
        }

        public DataSourceType[] DataSourceTypes { get; set; }

        public bool IncludeReviewed { get; set; }

        public bool IncludeErrors { get; set; }

        public bool IncludeRejected { get; set; }

        public string SearchText { get; set; }
    }

    public static class SearchParametersExtension
    {
        public static bool IsInitialLoad(this LastChangedNotificationsOptions options)
        {
            if (options == null) throw new ArgumentNullException(nameof(options));

            return !options.Since.HasValue;
        }

        public static bool IsInitialLoad(this SelectedCasesNotificationOptions options)
        {
            if (options == null) throw new ArgumentNullException(nameof(options));

            return !options.Since.HasValue;
        }

        public static bool HasSearchText(this SearchParameters options)
        {
            if (options == null) throw new ArgumentNullException(nameof(options));

            return !string.IsNullOrWhiteSpace(options.SearchText);
        }

        public static IEnumerable<DataSourceType> DataSourceTypesOrDefault(this SearchParameters options)
        {
            if (options == null) throw new ArgumentNullException(nameof(options));

            return options.DataSourceTypes.Any() 
                ? options.DataSourceTypes 
                : DefaultDataSourceTypes();
        }

        static IEnumerable<DataSourceType> DefaultDataSourceTypes()
        {
            return Enum.GetValues(typeof(DataSourceType)).Cast<DataSourceType>();
        }
    }
}