using System;
using System.Linq;
using InprotechKaizen.Model.Accounting;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Wip
{
    public class WipSelectionCriteria
    {
        public int ItemEntityId { get; set; }
        public int? ItemTransactionId { get; set; }
        public int[] CaseIds { get; set; }
        public int? DebtorId { get; set; }
        public int? RaisedByStaffId { get; set; }
        public ItemType? ItemType { get; set; }
        public DateTime? ItemDate { get; set; }
        public string MergeXmlKeys { get; set; }

        public string CaseIdsCsv => string.Join(",", CaseIds ?? Enumerable.Empty<int>());
    }
}