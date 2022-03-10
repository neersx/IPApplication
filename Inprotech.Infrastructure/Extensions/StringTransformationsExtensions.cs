using System;
using System.Text.RegularExpressions;

namespace Inprotech.Infrastructure.Extensions
{
    public static class StringTransformationsExtensions
    {
        public static string[] AsArrayOrNull(this string input)
        {
            return string.IsNullOrEmpty(input) ? null : new[] {input};
        }

        public static string WhiteSpaceAsNull(this string input)
        {
            return string.IsNullOrWhiteSpace(input) ? null : input;
        }

        public static string ToCamelCase(this string input)
        {
            if (input == null)
                return null;

            if (input.Length < 2)
                return input.ToLower();

            var words = input.Split(
                                    new char[] { },
                                    StringSplitOptions.RemoveEmptyEntries);

            if (words.Length == 1)
                return input.Substring(0, 1).ToLower() + input.Substring(1);

            var result = words[0].ToLower();
            for (var i = 1; i < words.Length; i++)
                result +=
                    words[i].Substring(0, 1).ToUpper() +
                    words[i].Substring(1);
            return result;
        }

        public static string CamelCaseToUnderscore(this string input)
        {
            return Regex.Replace(input, @"(\p{Ll})(\p{Lu})", "$1_$2").ToUpper();
        }

        public static string ToHyphenatedLowerCase(this string input)
        {
            return Regex.Replace(input.ToCamelCase(), @"(\p{Ll})(\p{Lu})", "$1-$2").ToLower();
        }

        public static string StripNonAlphanumerics(this string input)
        {
            var stripRegex = new Regex("[^a-zA-Z0-9]");
            return stripRegex.Replace(input, string.Empty);
        }

        public static string StripNonNumerics(this string input)
        {
            var stripRegex = new Regex("[^0-9]");
            return stripRegex.Replace(input, string.Empty);
        }

        public static string MaskAsAsterisks(this string input)
        {
            return new string('*', input.Length);
        }
    }
}