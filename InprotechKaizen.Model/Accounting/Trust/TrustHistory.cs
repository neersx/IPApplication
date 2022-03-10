using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Trust
{
    [Table("TRUSTHISTORY")]
    public class TrustHistory
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
        [Column("TACCTENTITYNO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int TrustAccountEntityId { get; set; }

        [Key]
        [Column("TACCTNAMENO", Order = 3)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int TrustAccountNameId { get; set; }

        [Key]
        [Column("HISTORYLINENO", Order = 4)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short HistoryLineNo { get; set; }

        [Required]
        [StringLength(20)]
        [Column("ITEMNO")]
        public string ItemNo { get; set; }

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

        [Column("LOCALVALUE")]
        public decimal? LocalValue { get; set; }

        [Column("EXCHVARIANCE")]
        public decimal? ExchangeVariance { get; set; }

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

        [Column("LONGDESCRIPTION", TypeName = "nText")]
        public string LongDescription { get; set; }
    }
}
