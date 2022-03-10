using System;
using System.Globalization;

namespace Inprotech.Infrastructure.Extensions
{
    public static class DateStringExtensions
    {
        public static DateTime? Iso8601OrNull(this string eventDate)
        {
            if (string.IsNullOrWhiteSpace(eventDate))
            {
                return null;
            }

            if (DateTime.TryParseExact(eventDate, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None,
                                       out DateTime dt))
            {
                return dt;
            }

            return null;
        }

        public static string ToSql121(this DateTime? dateTime, char padWith = ' ')
        {
            return dateTime == null
                ? string.Empty.PadRight(23, padWith)
                : dateTime.GetValueOrDefault().ToString("yyyy-MM-dd HH:mm:ss.fff");
        }

        public static string ToSql112(this DateTime? dateTime, char padWith = ' ')
        {
            return dateTime == null
                ? string.Empty.PadRight(8, padWith)
                : dateTime.GetValueOrDefault().ToString("yyyyMMdd");
        }
    }
}