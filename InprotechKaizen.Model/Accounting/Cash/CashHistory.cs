using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Cash
{
    [Table("CASHHISTORY")]
    public class CashHistory
    {
        [Key]
        [Column("ENTITYNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int EntityId { get; set; }

        [Key]
        [Column("BANKNAMENO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int BankNameId { get; set; }

        [Key]
        [Column("SEQUENCENO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int SequenceNo { get; set; }

        [Key]
        [Column("TRANSENTITYNO", Order = 3)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int TransactionEntityId { get; set; }

        [Key]
        [Column("TRANSNO", Order = 4)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int TransactionId { get; set; }

        [Key]
        [Column("HISTORYLINENO", Order = 5)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short HistoryLineNo { get; set; }

        [Column("TRANSDATE")]
        public DateTime TransDate { get; set; }

        [Column("POSTDATE")]
        public DateTime? PostDate { get; set; }

        [Column("POSTPERIOD")]
        public int? PostPeriodId { get; set; }

        [Column("TRANSTYPE", TypeName = "numeric")]
        public TransactionType TransType { get; set; }

        [Column("MOVEMENTCLASS", TypeName = "numeric")]
        public MovementClass MovementClass { get; set; }

        [Column("COMMANDID", TypeName = "numeric")]
        public CommandId CommandId { get; set; }

        [Column("REFENTITYNO")]
        public int? RefEntityId { get; set; }

        [Column("REFTRANSNO")]
        public int? RefTransNo { get; set; }

        [Column("STATUS", TypeName = "numeric")]
        public TransactionStatus? Status { get; set; }

        [StringLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("ASSOCIATEDLINENO")]
        public int? AssociatedLineNo { get; set; }

        [StringLength(30)]
        [Column("ITEMREFNO")]
        public string ItemRefId { get; set; }

        [Column("ACCTENTITYNO")]
        public int? AccountEntityId { get; set; }

        [Column("ACCTNAMENO")]
        public int? AccountNameId { get; set; }

        [StringLength(100)]
        [Column("GLACCOUNTCODE")]
        public string GlAccountCode { get; set; }

        [StringLength(3)]
        [Column("DISSECTIONCURRENCY")]
        public string DissectionCurrency { get; set; }

        [Column("FOREIGNAMOUNT")]
        public decimal? ForeignAmount { get; set; }

        [Column("DISSECTIONEXCHANGE")]
        public decimal? DissectionExchange { get; set; }

        [Column("LOCALAMOUNT")]
        public decimal? LocalAmount { get; set; }

        [Column("ITEMIMPACT", TypeName = "numeric")]
        public ItemImpact? ItemImpact { get; set; }

        [Column("GLMOVEMENTNO")]
        public int? GlMovementNo { get; set; }
    }
}
