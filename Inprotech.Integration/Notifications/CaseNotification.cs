using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Inprotech.Integration.Notifications
{
    public class CaseNotification
    {
        public int Id { get; set; }

        [Required]
        public CaseNotificateType Type { get; set; }

        public string Body { get; set; }

        [Required]
        public DateTime CreatedOn { get; set; }

        [Required]
        public DateTime UpdatedOn { get; set; }

        public bool IsReviewed { get; set; }

        public int? ReviewedBy { get; set; }

        public virtual Case Case { get; set; }

        [Required]
        [ForeignKey("Case")]
        public int CaseId { get; set; }

        [Timestamp]
        public byte[] Timestamp { get; protected set; }
    }

    public enum CaseNotificateType
    {
        CaseUpdated,
        Error,
        Rejected
    }
}