using System.Collections.Generic;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public class CaseDetailsSelection
    {
        public CaseDetailsSelection()
        {
            Countries = new string[0];
            PropertyTypes = new KeyValuePair<string, string>[0];
            CaseCategories = new KeyValuePair<string, string>[0];
        }

        public string[] Countries { get; set; }

        public string CaseType { get; set; }

        public KeyValuePair<string, string>[] PropertyTypes { get; set; }

        public KeyValuePair<string, string>[] CaseCategories { get; set; }

        public KeyValuePair<string, string>[] SubTypes { get; set; }

        public KeyValuePair<string, string>[] BasisList { get; set; }

        public string ChangingField { get; set; }
    }
}