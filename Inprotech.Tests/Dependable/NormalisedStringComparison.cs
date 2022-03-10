using System;
using System.Text.RegularExpressions;

namespace Inprotech.Tests.Dependable
{
    public static class NormalisedStringComparison
    {
        public static string Normalize(string s)
        {
            return Regex.Replace(s, @"\s", string.Empty);
        }

        public static bool AreSame(string s1, string s2)
        {
            var normalized1 = Normalize(s1);
            var normalized2 = Normalize(s2);

            return string.Equals(
                                 normalized1,
                                 normalized2,
                                 StringComparison.OrdinalIgnoreCase);
        }
    }
}