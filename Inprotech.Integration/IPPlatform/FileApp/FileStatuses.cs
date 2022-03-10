using System.Collections.Generic;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    public static class FileStatuses
    {
        public const string Draft = "DRAFT";

        public const string Instructed = "INSTRUCTED";

        public static readonly Dictionary<string, string> Map = new Dictionary<string, string>
        {
            {"DRAFT", "Draft"},
            {"SENT", "Sent"},
            {"RECEIVED", "Received"},
            {"ACKNOWLEDGED", "Acknowledged"},
            {"SENT_TO_PTO", "Sent To PTO"},
            {"FILING_RECEIPT", "Filing Receipt"},
            {"COMPLETED", "Completed"},
            {"REJECTED", "Rejected"}
        };
    }
}
