using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Banking
{
    [Table("BANKACCOUNT")]
    public class BankAccount
    {
        [Key]
        [Column("ACCOUNTOWNER", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int AccountOwner { get; set; }

        [Key]
        [Column("BANKNAMENO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int BankNameNo { get; set; }

        [Key]
        [Column("SEQUENCENO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int SequenceNo { get; set; }

        [Column("ISOPERATIONAL")]
        public decimal? IsOperational { get; set; }

        [StringLength(50)]
        [Column("BANKBRANCHNO")]
        public string BankBranchNo { get; set; }

        [Column("BRANCHNAMENO")]
        public int? BranchNameNo { get; set; }

        [Required]
        [StringLength(50)]
        [Column("ACCOUNTNO")]
        public string AccountNo { get; set; }

        [Required]
        [StringLength(80)]
        [Column("ACCOUNTNAME")]
        public string AccountName { get; set; }

        [Required]
        [StringLength(3)]
        [Column("CURRENCY")]
        public string Currency { get; set; }

        [Required]
        [StringLength(80)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("ACCOUNTTYPE")]
        public int? AccountType { get; set; }

        [Column("DRAWCHEQUESFLAG")]
        public decimal DrawChequesFlag { get; set; }

        [StringLength(30)]
        [Column("LASTMANUALCHEQUE")]
        public string LastManualCheque { get; set; }

        [StringLength(30)]
        [Column("LASTAUTOCHEQUE")]
        public string LastAutoCheque { get; set; }

        [Column("ACCOUNTBALANCE")]
        public decimal? AccountBalance { get; set; }

        [Column("LOCALBALANCE")]
        public decimal? LocalBalance { get; set; }

        [Column("DATECEASED")]
        public DateTime? DateCeased { get; set; }

        [StringLength(4)]
        [Column("BICBANKCODE")]
        public string BicBankCode { get; set; }

        [StringLength(2)]
        [Column("BICCOUNTRYCODE")]
        public string BicCountryCode { get; set; }

        [StringLength(2)]
        [Column("BICLOCATIONCODE")]
        public string BicLocationCode { get; set; }

        [StringLength(3)]
        [Column("BICBRANCHCODE")]
        public string BicBranchCode { get; set; }

        [StringLength(34)]
        [Column("IBAN")]
        public string Iban { get; set; }

        [Column("BANKOPERATIONCODE")]
        public int? BankOperationCode { get; set; }

        [Column("DETAILSOFCHARGES")]
        public int? DetailsOfCharges { get; set; }

        [Column("EFTFILEFORMATUSED")]
        public int? EftFileFormatUsed { get; set; }

        [StringLength(6)]
        [Column("CABPROFITCENTRE")]
        public string CabProfitCentre { get; set; }

        [Column("CABACCOUNTID")]
        public int? CabAccountId { get; set; }

        [StringLength(6)]
        [Column("CABCPROFITCENTRE")]
        public string CabCProfitCentre { get; set; }

        [Column("CABCACCOUNTID")]
        public int? CabCAccountId { get; set; }

        [StringLength(128)]
        [Column("PROCAMOUNTTOWORDS")]
        public string ProcAmountTowards { get; set; }

        [Column("TRUSTACCTFLAG")]
        public bool TrustAcctFlag { get; set; }
    }
}