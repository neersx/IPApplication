using System;
using System.Collections.Generic;

namespace Inprotech.Integration.ExternalApplications.Crm
{
    [Serializable]
    public class NameAttributes
    {
        public List<SelectedAttribute> SelectedNameAttributes { get; set; }

        public List<AttributeType> AvailableNameAttributes { get; set; }
    }
}
