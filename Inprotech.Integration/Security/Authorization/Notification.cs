using System.Collections;
using System.Collections.Generic;
using Inprotech.Infrastructure.Notifications.Security;

namespace Inprotech.Integration.Security.Authorization
{
    public class Notification
    {
        public string From { get; set; }

        public string Subject { get; set; }

        public string Body { get; set; }

        public ICollection<UserEmail> EmailRecipient { get; }

        public ICollection<UserEmail> CcEmailRecipient { get; }

        public Notification()
        {
            EmailRecipient = new List<UserEmail>();
            CcEmailRecipient = new List<UserEmail>();
        }

        public bool IsBodyHtml { get; set; }
    }
}