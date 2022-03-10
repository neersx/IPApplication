using System.Linq;
using System.Text.RegularExpressions;
using System.Xml;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.BulkCaseImport
{
    public interface IXmlIllegalCharSanitiser
    {
        bool TrySanitise(JProperty property, int row, out SanitisedForXml sanitised);
    }

    public class XmlIllegalCharSanitiser : IXmlIllegalCharSanitiser
    {
        const string UnsupportedUnicodeXmlChars = @"[\xA0\uFFFD]";

        static readonly Regex Regex = new Regex(UnsupportedUnicodeXmlChars, RegexOptions.IgnoreCase | RegexOptions.Compiled);

        public bool TrySanitise(JProperty property, int row, out SanitisedForXml sanitised)
        {
            var value = (string)property.Value;
            var validForXml = EnsureValidForXml(value);
            if (value != validForXml)
            {
                sanitised = new SanitisedForXml
                {
                    Row = row,
                    FieldName = property.Name,
                    OriginalValue = value,
                    SanitisedValue = validForXml
                };

                property.Value = validForXml;

                return true;
            }

            sanitised = null;
            return false;
        }

        static string EnsureValidForXml(string input)
        {
            if (string.IsNullOrWhiteSpace(input))
            {
                return input;
            }

            var validXmlChars = input.Where(XmlConvert.IsXmlChar).ToArray();
            var sanitized = new string(validXmlChars);

            return Regex.IsMatch(sanitized)
                ? Regex.Replace(sanitized, string.Empty)
                : sanitized;
        }
    }
}