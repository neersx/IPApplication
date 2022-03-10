using System;
using System.Text.RegularExpressions;

namespace InprotechKaizen.Model.Components.System.Utilities
{
    static class Helper
    {
        public static string StripNonNumerics(string input)
        {
            return string.IsNullOrWhiteSpace(input)
                ? input
                : Regex.Replace(input, "[^0-9]", string.Empty, RegexOptions.Compiled);
        }

        public static bool AreStringsEqual(string string1, string string2)
        {
            return string.Compare(string1, string2, StringComparison.OrdinalIgnoreCase) == 0;
        }
    }
}
