using System;
using System.Text.RegularExpressions;

namespace Inprotech.Integration.Notifications
{
    public class Utility
    {
        public static string StripNonAlphaNumerics(string input)
        {
            return string.IsNullOrWhiteSpace(input)
                ? input
                : Regex.Replace(input, "[^a-zA-Z0-9]", string.Empty, RegexOptions.Compiled);
        }

        public static bool IgnoreCaseEquals(string s1, string s2)
        {
            return string.Equals(s1, s2, StringComparison.OrdinalIgnoreCase);
        }
    }
}