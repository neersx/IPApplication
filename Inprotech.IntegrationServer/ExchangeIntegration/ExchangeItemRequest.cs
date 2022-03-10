using System;

namespace Inprotech.IntegrationServer.ExchangeIntegration
{
    public class ExchangeItemRequest
    {
        public string Mailbox { get; set; }
        public string RecipientEmail { get; set; }
        public string CcRecipientEmails { get; set; }
        public string BccRecipientEmails { get; set; }
        public string Subject { get; set; }
        public string Body { get; set; }
        public bool IsBodyHtml { get; set; }
        public int StaffId { get; set; }
        public DateTime CreatedOn { get; set; }
        public DateTime? DueDate { get; set; }
        public DateTime? ReminderDate { get; set; }
        public bool IsReminderRequired { get; set; }
        public bool IsHighPriority { get; set; }
        public int? UserIdentity { get; set; }
        public string Attachments { get; set; }
    }
}