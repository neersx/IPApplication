using System;
using System.ComponentModel.DataAnnotations;
using Inprotech.Integration.AutomaticDocketing;
using Inprotech.Integration.Storage;

namespace Inprotech.Integration.Documents
{
    public enum DocumentDownloadStatus
    {
        Pending,
        Downloaded,
        Failed,

        /// <summary>
        /// Scheduled For Sending To Dms (Previously SendingToDms) is a status set once a document is downloaded or when there are documents instructed to be sent to dms.
        /// </summary>
        ScheduledForSendingToDms,

        /// <summary>
        /// Send To Dms is a status instigated from SendToDmsController.
        /// </summary>
        SendToDms,
        SentToDms,
        FailedToSendToDms,

        /// <summary>
        /// SendingToDms is an internal state to avoid racing condition, occurring within the moving of the document.
        /// </summary>
        SendingToDms
    }

    public class Document
    {
        public int Id { get; set; }

        public string ApplicationNumber { get; set; }

        public string RegistrationNumber { get; set; }

        public string PublicationNumber { get; set; }

        public DataSourceType Source { get; set; }

        public string SourceUrl { get; set; }

        [Required]
        public DocumentDownloadStatus Status { get; set; }

        public virtual FileStore FileStore { get; set; }

        [Required]
        public string DocumentObjectId { get; set; }

        [Required]
        public DateTime MailRoomDate { get; set; }

        public string DocumentDescription { get; set; }

        public string DocumentCategory { get; set; }

        public string FileWrapperDocumentCode { get; set; }

        public int? PageCount { get; set; }

        public string Errors { get; set; }

        public string MediaType { get; set; }

        [Required]
        public DateTime CreatedOn { get; set; }

        [Required]
        public DateTime UpdatedOn { get; set; }

        [Required]
        public Guid Reference { get; set; }

        [Timestamp]
        public byte[] RowVersion { get; protected set; }

        public virtual DocumentEvent DocumentEvent { get; set; }

        public virtual string CorrelationRef()
        {
            return Id.ToString();
        }
    }

    public static class DocumentExtensions
    {
        public static string FileExtension(this Document document)
        {
            var ext = document.MediaType ?? "/pdf";

            return "." + ext.Substring(ext.IndexOf("/", StringComparison.Ordinal) + 1);
        }
    }
}