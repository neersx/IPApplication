using System;
using System.Collections.Generic;

namespace Inprotech.Integration.ExternalApplications.Crm.Request
{
    [Serializable]
    public class ContactActivityRequest
    {
        public ContactActivity ContactActivity { get; set; }

        public List<ContactActivityAttachment> ContactActivityAttachments { get; set; }
    }
}
