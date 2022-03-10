using System.Text.RegularExpressions;
using Inprotech.IntegrationServer.PtoAccess.Utilities;

namespace Inprotech.IntegrationServer.PtoAccess.Epo
{
    public static class Utility
    {
        const string CheckDigitRegex = @"\.\d\b";

        public static string FormatEpNumber(string number)
        {
            var formattedNumber = number;
            if (char.IsDigit(number[0]))
                formattedNumber = "EP" + number;

            formattedNumber = OfficialNumbers.ExtractSearchTerm(formattedNumber);
            formattedNumber = Regex.Replace(formattedNumber, CheckDigitRegex, string.Empty);

            return formattedNumber;
        }
    }
}