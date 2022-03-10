using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml.Linq;
using Inprotech.Infrastructure;

namespace Inprotech.Web.SchemaMapping
{
    static class Helpers
    {        
        public static string GetXml(XDocument xdoc)
        {
            using (var writer = new EncodingStringWriter(Encoding.UTF8))
            {
                xdoc.Save(writer);

                return writer.ToString();
            }
        }

        public static string SanitiseFilename(string name, string replacement = "")
        {
            var invalidChars = Regex.Escape(new string(Path.GetInvalidFileNameChars()));
            var invalidCharsRegex = $@"[{invalidChars}]+";

            return Regex.Replace(name, invalidCharsRegex, replacement);
        }
    }
}