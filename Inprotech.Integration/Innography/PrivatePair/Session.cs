using System;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class Session
    {
        public Guid Id { get; set; }

        public string Root { get; set; }

        public string Name { get; set; }

        public int ScheduleId { get; set; }

        public string CertificateId { get; set; }

        public string CustomerNumber { get; set; }

        public DownloadActivityType DownloadActivity { get; set; }

        public int? DaysWithinLast { get; set; }

        public bool UnviewedOnly { get; set; }
    }

    public enum DownloadActivityType
    {
        All,
        StatusChanges,
        Documents,
        RecoverDocuments
    }

    public static class DownloadActivityTypeExt
    {
        public static bool DownloadsDocuments(this DownloadActivityType type)
        {
            return type == DownloadActivityType.Documents || type == DownloadActivityType.RecoverDocuments;
        }
    }
}