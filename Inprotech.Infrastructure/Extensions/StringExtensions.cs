using System;

namespace Inprotech.Infrastructure.Extensions
{
    public static class StringExtensions
    {
        public static bool IsNullOrEmpty(this string input)
        {
            return string.IsNullOrEmpty(input);
        }

        public static string Truncate(this string value, int maxLength)
        {
            return string.IsNullOrEmpty(value) ? value : value.Substring(0, Math.Min(value.Length, maxLength));
        }

        public static string NullIfEmptyOrWhitespace(this string input)
        {
            return string.IsNullOrWhiteSpace(input) ? null : input;
        }

        public static string MakeInitialLowerCase(this string input)
        {
            return string.Concat(input.Substring(0, 1).ToLower(), input.Substring(1));
        }

        public static (string ShortText, string LongText) SplitByLength(this string input)
        {
            if (string.IsNullOrWhiteSpace(input))
                return (null, null);

            var shortText = input.Length < 254 ? input : null;
            var longText = input.Length >= 254 ? input : null;

            return (shortText, longText);
        }
    }
}