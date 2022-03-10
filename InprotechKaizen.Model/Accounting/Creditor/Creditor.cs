using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Creditor
{
    [Table("CREDITOR")]
    public class Creditor
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("NAMENO")]
        public int NameId { get; set; }

        [Column("SUPPLIERTYPE")]
        public int SupplierType { get; set; }

        [StringLength(3)]
        [Column("DEFAULTTAXCODE")]
        public string DefaultTaxCode { get; set; }

        [Column("TAXTREATMENT")]
        public int? TaxTreatment { get; set; }

        [StringLength(3)]
        [Column("PURCHASECURRENCY")]
        public string PurchaseCurrency { get; set; }

        [Column("PAYMENTTERMNO")]
        public int? PaymentTermNo { get; set; }

        [StringLength(254)]
        [Column("CHEQUEPAYEE")]
        public string ChequePayee { get; set; }

        [StringLength(254)]
        [Column("INSTRUCTIONS")]
        public string Instructions { get; set; }

        [Column("EXPENSEACCOUNT")]
        public int? ExpenseAccount { get; set; }

        [StringLength(6)]
        [Column("PROFITCENTRE")]
        public string ProfitCentre { get; set; }

        [Column("PAYMENTMETHOD")]
        public int? PaymentMethod { get; set; }
        
        [StringLength(60)]
        [Column("BANKNAME")]
        public string BankName { get; set; }

        [StringLength(10)]
        [Column("BANKBRANCHNO")]
        public string BankBranchNo { get; set; }

        [StringLength(20)]
        [Column("BANKACCOUNTNO")]
        public string BankAccountNo { get; set; }

        [StringLength(60)]
        [Column("BANKACCOUNTNAME")]
        public string BankAccountName { get; set; }

        [Column("BANKACCOUNTOWNER")]
        public int? BankAccountOwner { get; set; }

        [Column("BANKNAMENO")]
        public int? BankNameNo { get; set; }

        [Column("BANKSEQUENCENO")]
        public int? BankSequenceNo { get; set; }

        [Column("RESTRICTIONID")]
        public int? RestrictionId { get; set; }
        
        [StringLength(2)]
        [Column("RESTNREASONCODE")]
        public string RestrictionReasonCode { get; set; }

        [StringLength(254)]
        [Column("PURCHASEDESC")]
        public string PurchaseDescription { get; set; }

        [StringLength(6)]
        [Column("DISBWIPCODE")]
        public string DisbursementWipCode { get; set; }

        [StringLength(4)]
        [Column("BEIBANKCODE")]
        public string BeiBankCode { get; set; }

        [StringLength(2)]
        [Column("BEICOUNTRYCODE")]
        public string BeiCountryCode { get; set; }

        [StringLength(2)]
        [Column("BEILOCATIONCODE")]
        public string BeiLocationCode { get; set; }

        [StringLength(3)]
        [Column("BEIBRANCHCODE")]
        public string BeiBranchCode { get; set; }

        [Column("INSTRUCTIONS_TID")]
        public int? InstructionsTId { get; set; }

        [Column("EXCHSCHEDULEID")]
        public int? ExchangeScheduleId { get; set; }
    }
}