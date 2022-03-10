using System;
using System.Collections.Generic;
using System.Linq;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Delivery
{
    public class EmailRecipients
    {
        public EmailRecipients(string to, string cc = null, string bcc = null)
        {
            To = new HashSet<string>(Prep(to), StringComparer.InvariantCultureIgnoreCase);
            Cc = new HashSet<string>(Prep(cc), StringComparer.InvariantCultureIgnoreCase);
            Bcc = new HashSet<string>(Prep(bcc), StringComparer.InvariantCultureIgnoreCase);
        }

        public EmailRecipients()
        {
            To = new HashSet<string>(StringComparer.InvariantCultureIgnoreCase);
            Cc = new HashSet<string>(StringComparer.InvariantCultureIgnoreCase);
            Bcc = new HashSet<string>(StringComparer.InvariantCultureIgnoreCase);
        }
            
        public HashSet<string> To { get; }

        public HashSet<string> Cc { get; }

        public HashSet<string> Bcc { get; }

        public string Subject { get; set; }

        static IEnumerable<string> Prep(string value)
        {
            return (value ?? string.Empty)
                   .Split(new[] {";"}, StringSplitOptions.RemoveEmptyEntries)
                   .Select(_ => _.Trim())
                   .ToArray();
        }
    }
}