using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    public class BillRuleRow
    {
        [Column("RULESEQNO")]
        public int RuleId { get; set; }

        [Column("RULETYPE", TypeName = "numeric")]
        public BillRuleType RuleType { get; set; }

        public int? CaseId { get; set; }

        public int? DebtorNo { get; set; }

        public int? EntityNo { get; set; }

        public decimal? LocalClientFlag { get; set; }

        public string CaseType { get; set; }

        public string PropertyType { get; set; }

        public string CaseAction { get; set; }

        public string CaseCountry { get; set; }

        public int? BillingEntity { get; set; }

        public decimal? MinimumNetBill { get; set; }

        public string WipCode { get; set; }

        public string BestFitScore { get; set; }
    }
}