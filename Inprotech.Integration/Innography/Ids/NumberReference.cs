using System;
using System.Globalization;

namespace Inprotech.Integration.Innography.Ids
{
    public static class DateStringsExt
    {
        public static DateTime? FormatAsUtcDateValue(this string dateReference)
        {
            if (string.IsNullOrWhiteSpace(dateReference)) return null;

            return DateTime.Parse(dateReference, null, DateTimeStyles.AdjustToUniversal | DateTimeStyles.AssumeUniversal);
        }
    }
}