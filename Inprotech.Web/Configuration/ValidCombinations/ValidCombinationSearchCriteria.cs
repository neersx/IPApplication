using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    public class ValidCombinationSearchCriteria
    {
        public ValidCombinationSearchCriteria()
        {
            Jurisdictions = Enumerable.Empty<string>();
        }

        public IEnumerable<string> Jurisdictions { get; set; }
        public string PropertyType { get; set; }
        public string CaseType { get; set; }
        public string Action { get; set; }
        public string CaseCategory { get; set; }
        public string SubType { get; set; }
        public string Basis { get; set; }
        public DateTime DateOfLaw { get; set; }
        public short? Status { get; set; }
        public string Relationship { get; set; }

        public short? Checklist { get; set; }
    }
}
