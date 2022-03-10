using System;
using System.Globalization;

namespace Inprotech.Infrastructure.Extensions
{
    public static class StringComparisonExtensions
    {
        public static bool IgnoreCaseEquals(this string theString, string other)
        {
            return string.Compare(theString, other, StringComparison.CurrentCultureIgnoreCase) == 0;
        }

        public static bool IgnoreCaseContains(this string str, string containsString)
        {
            return str?.IndexOf(containsString, StringComparison.InvariantCultureIgnoreCase) > -1;
        }

        public static bool IgnoreCaseStartsWith(this string str, string startsWith)
        {
            return str?.StartsWith(startsWith, StringComparison.InvariantCultureIgnoreCase) ?? false;
        }

        public static bool TextContains(this string source, string value)
        {
            if (source == null) return false;

            var index = CultureInfo.InvariantCulture.CompareInfo.IndexOf
                (source, value, CompareOptions.IgnoreCase | CompareOptions.IgnoreSymbols | CompareOptions.IgnoreNonSpace);
            return index != -1;
        }

        public static bool TextRelaxedEquals(this string source, string value)
        {
            return CultureInfo.InvariantCulture.CompareInfo.Compare(source, value, 
                CompareOptions.IgnoreCase | CompareOptions.IgnoreSymbols | CompareOptions.IgnoreNonSpace) == 0;
        }
    }
}