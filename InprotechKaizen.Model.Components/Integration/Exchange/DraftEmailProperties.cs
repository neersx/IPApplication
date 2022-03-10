using System;
using System.Collections.Generic;
using System.IO;

namespace InprotechKaizen.Model.Components.Integration.Exchange
{
    public class DraftEmailProperties
    {
        public string Mailbox { get; set; }

        public HashSet<string> Recipients { get; set; }

        public HashSet<string> CcRecipients { get; set; }

        public HashSet<string> BccRecipients { get; set; }

        public string Subject { get; set; }

        public string Body { get; set; }

        public bool IsBodyHtml { get; set; }

        public ICollection<EmailAttachment> Attachments { get; set; }

        public DraftEmailProperties()
        {
            Recipients = new HashSet<string>();
            CcRecipients = new HashSet<string>();
            BccRecipients = new HashSet<string>();
            Attachments = new List<EmailAttachment>();
        }
    }

    public class EmailAttachment
    {
        public string FileName { get; set; }

        public string ContentId { get; set; }

        public string Content { get; set; }

        public bool IsInline { get; set; }
    }

    public static class EmailAttachmentExtensions
    {
        public static Stream GetContentStream(this EmailAttachment attachment)
        {
            if (string.IsNullOrWhiteSpace(attachment.Content))
                return null;

            return new MemoryStream(Convert.FromBase64String(attachment.Content));
        }
    }
}