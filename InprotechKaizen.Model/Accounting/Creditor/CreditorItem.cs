using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Creditor
{
    [Table("CREDITORITEM")]
    public class CreditorItem
    {
        [Key]
        [Column("ITEMENTITYNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int ItemEntityId { get; set; }

        [Key]
        [Column("ITEMTRANSNO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int ItemTransactionId { get; set; }

        [Key]
        [Column("ACCTENTITYNO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int AccountEntityId { get; set; }

        [Key]
        [Column("ACCTCREDITORNO", Order = 3)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int AccountCreditorId { get; set; }

        [Required]
        [StringLength(20)]
        [Column("DOCUMENTREF")]
        public string DocumentRef { get; set; }

        [Column("ITEMDATE")]
        public DateTime ItemDate { get; set; }

        [Column("ITEMDUEDATE")]
        public DateTime? ItemDueDate { get; set; }

        [Column("POSTDATE")]
        public DateTime? PostDate { get; set; }

        [Column("POSTPERIOD")]
        public int? PostPeriodId { get; set; }

        [Column("CLOSEPOSTDATE")]
        public DateTime? ClosePostDate { get; set; }

        [Column("CLOSEPOSTPERIOD")]
        public int? ClosePostPeriodId { get; set; }

        [Column("ITEMTYPE")]
        public ItemType? ItemType { get; set; }

        [StringLength(3)]
        [Column("CURRENCY")]
        public string Currency { get; set; }

        [Column("EXCHRATE")]
        public decimal? ExchangeRate { get; set; }

        [Column("LOCALPRETAXVALUE")]
        public decimal? LocalPreTaxValue { get; set; }

        [Column("LOCALVALUE")]
        public decimal? LocalValue { get; set; }

        [Column("LOCALTAXAMOUNT")]
        public decimal? LocalTaxAmount { get; set; }

        [Column("FOREIGNVALUE")]
        public decimal? ForeignValue { get; set; }

        [Column("FOREIGNTAXAMT")]
        public decimal? ForeignTaxAmount { get; set; }

        [Column("LOCALBALANCE")]
        public decimal? LocalBalance { get; set; }

        [Column("FOREIGNBALANCE")]
        public decimal? ForeignBalance { get; set; }

        [Column("EXCHVARIANCE")]
        public decimal? ExchangeVariance { get; set; }

        [Column("STATUS", TypeName = "numeric")]
        public TransactionStatus? Status { get; set; }

        [StringLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("LONGDESCRIPTION", TypeName = "ntext")]
        public string LongDescription { get; set; }

        [Column("RESTRICTIONID")]
        public int? RestrictionId { get; set; }

        [StringLength(2)]
        [Column("RESTNREASONCODE")]
        public string RestAndReasonCode { get; set; }

        [StringLength(20)]
        [Column("PROTOCOLNO")]
        public string ProtocolNo { get; set; }

        [Column("PROTOCOLDATE")]
        public DateTime? ProtocolDate { get; set; }
    }
}
