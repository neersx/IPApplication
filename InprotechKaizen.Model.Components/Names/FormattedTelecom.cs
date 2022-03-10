using System.Collections.Generic;
using System.Linq;

namespace InprotechKaizen.Model.Components.Names
{
    public static class FormattedTelecom
    {
        public const string Space = " ";

        public static string For(string isd, string areaCode, string number, string extension)
        {
            var formattedTelecom = string.Join(Space, Build(isd, areaCode, number, extension)
                .Where(_ => !string.IsNullOrWhiteSpace(_))
                .Select(_ => _.Trim())).Trim();

            return string.IsNullOrWhiteSpace(formattedTelecom) ? null : formattedTelecom;
        }

        static IEnumerable<string> Build(string isd, string areaCode, string number, string extension)
        {
            yield return string.IsNullOrEmpty(isd) ? null : "+" + isd.Replace("+", string.Empty);
            yield return areaCode;
            yield return number;
            yield return string.IsNullOrEmpty(extension) ? null : " x" + extension;
        }
    }
}
