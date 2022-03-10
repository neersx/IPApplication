using System.Text.RegularExpressions;

namespace Inprotech.IntegrationServer.PtoAccess.Utilities
{
    public class OfficialNumbers
    {
        public static string ExtractSearchTerm(string number)
        {
            return Regex.Replace(number, @"(\/|,|\s|-)", string.Empty);
        }
    }
}
