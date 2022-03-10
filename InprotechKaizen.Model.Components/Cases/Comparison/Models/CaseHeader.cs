using System;
using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Models
{
    public class CaseHeader
    {
        public CaseHeader()
        {
            Messages = new Dictionary<string, IEnumerable<string>>();     
        }

        public string Id { get; set; }

        public string Ref { get; set; }

        public string Title { get; set; }

        public string Status { get; set; }

        public DateTime? StatusDate { get; set; }

        public string LocalClasses { get; set; }

        public string IntClasses { get; set; }

        public string ApplicationLanguageCode { get; set; }

        public Dictionary<string, IEnumerable<string>> Messages { get; set; }
    }
}
