using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Creditor
{
    [Table("CREDITORHISTORY")]
    public class CreditorHistory
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

        [Key]
        [Column("HISTORYLINENO", Order = 4)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short HistoryLineNo { get; set; }

        [Required]
        [StringLength(20)]
        [Column("DOCUMENTREF")]
        public string DocumentRef { get; set; }

        [Column("TRANSDATE")]
        public DateTime TransactionDate { get; set; }

        [Column("POSTDATE")]
        public DateTime? PostDate { get; set; }

        [Column("POSTPERIOD")]
        public int? PostPeriodId { get; set; }

        [Column("TRANSTYPE", TypeName = "numeric")]
        public TransactionType TransactionType { get; set; }

        [Column("MOVEMENTCLASS", TypeName = "numeric")]
        public MovementClass MovementClass { get; set; }

        [Column("COMMANDID", TypeName = "numeric")]
        public CommandId CommandId { get; set; }

        [Column("ITEMPRETAXVALUE")]
        public decimal? ItemPreTaxValue { get; set; }

        [Column("LOCALTAXAMT")]
        public decimal? LocalTaxAmount { get; set; }

        [Column("LOCALVALUE")]
        public decimal? LocalValue { get; set; }

        [Column("EXCHVARIANCE")]
        public decimal? ExchangeVariance { get; set; }

        [Column("FOREIGNTAXAMT")]
        public decimal? ForeignTaxAmount { get; set; }

        [Column("FOREIGNTRANVALUE")]
        public decimal? ForeignTranValue { get; set; }

        [Column("REFENTITYNO")]
        public int? RefEntityId { get; set; }

        [Column("REFTRANSNO")]
        public int? RefTransactionId { get; set; }

        [Column("LOCALBALANCE")]
        public decimal? LocalBalance { get; set; }

        [Column("FOREIGNBALANCE")]
        public decimal? ForeignBalance { get; set; }

        [Column("FORCEDPAYOUT")]
        public decimal? IsForcedPayout { get; set; }

        [StringLength(3)]
        [Column("CURRENCY")]
        public string Currency { get; set; }

        [Column("EXCHRATE")]
        public decimal? ExchangeRate { get; set; }

        [Column("STATUS", TypeName = "numeric")]
        public TransactionStatus? Status { get; set; }

        [Column("ASSOCLINENO")]
        public short? AssociatedLineNo { get; set; }

        [Column("ITEMIMPACT", TypeName = "numeric")]
        public ItemImpact? ItemImpact { get; set; }

        [StringLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("LONGDESCRIPTION", TypeName = "ntext")]
        public string LongDescription { get; set; }

        [Column("GLMOVEMENTNO")]
        public int? GlMovementNo { get; set; }

        [Column("GLSTATUS")]
        public int? GlStatus { get; set; }

        [Column("REMITTANCENAMENO")]
        public int? RemittanceNameNo { get; set; }
    }
}
