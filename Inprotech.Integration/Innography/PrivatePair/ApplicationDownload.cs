using System;
using System.Text.RegularExpressions;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class ApplicationDownload
    {
        public string SessionRoot { get; set; }

        public Guid SessionId { get; set; }

        public string SessionName { get; set; }

        public string CustomerNumber { get; set; }

        public string Number { get; set; }

        /// <summary>
        /// For Uspto, is equivalent to ApplicationNumber without special characters
        /// </summary>
        public string ApplicationId { get; set; }
    }

    public static class ReformatApplicationId
    {
        static readonly Regex AllDigits = new Regex("/^[0-9]*$");
        static readonly Regex PctFormatLong = new Regex("^[a-zA-Z]{5}[0-9]{9,10}$");
        static readonly Regex PctFormatShort = new Regex("^[a-zA-Z]{5}[0-9]{7,8}$");
        public static string GetApplicationNumber(this string applicationId)
        {
            if (string.IsNullOrWhiteSpace(applicationId) || AllDigits.IsMatch(applicationId))
            {
                return applicationId;
            }

            if (PctFormatShort.IsMatch(applicationId))
            {
                return $"{applicationId.Substring(0, 3)}/{applicationId.Substring(3, 4)}/{applicationId.Substring(7, applicationId.Length - 7)}";
            }

            if (PctFormatLong.IsMatch(applicationId))
            {
                return $"{applicationId.Substring(0, 3)}/{applicationId.Substring(3, 6)}/{applicationId.Substring(9, applicationId.Length - 9)}";
            }

            return applicationId;
        }

        public static string SanitizeApplicationNumber(this string applicationNumber)
        {
            return applicationNumber.Replace("/", string.Empty);
        }
    }
}