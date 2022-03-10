using System;
using System.Collections.Generic;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.DisbursementDissection
{
    public class DisbursementDissectionParameter
    {
        public decimal? Amount { get; set; }
        public int CaseKey { get; set; }
        public string CurrencyCode { get; set; }
        public string DebitNoteText { get; set; }
        public string Description { get; set; }
        public decimal? Discount { get; set; }
        public decimal? ExchRate { get; set; }
        public decimal? ForeignAmount { get; set; }
        public decimal? ForeignDiscount { get; set; }
        public decimal? ForeignDiscountForMargin { get; set; }
        public decimal? ForeignMargin { get; set; }
        public decimal? LocalCost1 { get; set; }
        public decimal? LocalCost2 { get; set; }
        public decimal? LocalDiscountForMargin { get; set; }
        public decimal? Margin { get; set; }
        public int? MarginNo { get; set; }
        public int NameKey { get; set; }
        public string NarrativeCode { get; set; }
        public string NarrativeText { get; set; }
        public short NarrativeKey { get; set; }
        public int StaffKey { get; set; }
        public DateTime TransDate { get; set; }
        public string WipCode { get; set; }
        public int WipSeqNo { get; set; }
        public bool IsSplitDebtorWip { get; set; }
        public IEnumerable<dynamic> SplitWipItems { get; set; }
    }

    public class DisbursementWipParameter
    {
        public int CaseKey { get; set; }

        public string CurrencyCode { get; set; }

        public int EntityKey { get; set; }

        public decimal? ForeignValueBeforeMargin { get; set; }

        public decimal? LocalValueBeforeMargin { get; set; }

        public bool MarginRequired { get; set; }

        public int NameKey { get; set; }

        public int StaffKey { get; set; }

        public DateTime TransactionDate { get; set; }

        public string WIPCode { get; set; }
    }
}