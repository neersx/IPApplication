using System;
using System.Collections.Generic;

namespace Inprotech.Integration.ExternalApplications.Crm.Request
{
    [Serializable]
    public class CrmAttributes
    {
        public List<SelectedAttribute> NameAttributes { get; set; }
    }
}
