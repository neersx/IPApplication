using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Billing
{
    [Table("BILLRULE")]
    public class BillRule
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("RULESEQNO")]
        public int RuleId { get; set; }

        [Column("RULETYPE", TypeName = "numeric")]
        public BillRuleType RuleTypeId { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("DEBTORNO")]
        public int? DebtorId { get; set; }

        [Column("ENTITYNO")]
        public int? EntityId { get; set; }

        [Column("NAMECATEGORY")]
        public int? NameCategoryId { get; set; }

        [Column("LOCALCLIENTFLAG")]
        public decimal? LocalClientFlag { get; set; }

        [Column("CASETYPE")]
        public string CaseTypeId { get; set; }

        [Column("CASECOUNTRY")]
        public string CountryId { get; set; }

        [Column("PROPERTYTYPE")]
        public string PropertyTypeId { get; set; }

        [Column("CASEACTION")]
        public string CaseActionId { get; set; }

        [Column("WIPCODE")]
        public string WipCode { get; set; }
        
        [Column("MINIMUMNETBILL")]
        public decimal? MinimumNetBill { get; set; }

        [Column("BILLINGENTITY")]
        public int? BillingEntityId { get; set; }
    }
}
