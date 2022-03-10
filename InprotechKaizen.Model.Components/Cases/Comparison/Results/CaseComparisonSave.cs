using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Results
{
    public class CaseComparisonSave
    {
        public Case Case { get; set; }
        public IEnumerable<OfficialNumber> OfficialNumbers { get; set; }
        public IEnumerable<CaseName> CaseNames { get; set; }
        public IEnumerable<Event> Events { get; set; }
        public IEnumerable<GoodsServices> GoodsServices { get; set; }

        public string SystemCode { get; set; }
        public int CaseId { get; set; }
        public int NotificationId { get; set; }

        public bool ImportImage { get; set; }
    }
}
