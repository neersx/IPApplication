using System.Text.RegularExpressions;

namespace Inprotech.Infrastructure.Extensions
{
    public static class Wildcard
    {
        public static string Match(string input, string pattern, bool caseSensitive)
        {
            var regExPattern = "^" + Regex.Escape(pattern).Replace(@"\*", "(.*)").Replace(@"\?", ".") + "$";

            var regex = caseSensitive ? 
                new Regex(regExPattern) : 
                new Regex(regExPattern, RegexOptions.IgnoreCase);

            var match = regex.Match(input);
            if (!match.Success) return null;

            return match.Groups.Count != 2 ? null : match.Groups[1].Value;
        }
    }
}