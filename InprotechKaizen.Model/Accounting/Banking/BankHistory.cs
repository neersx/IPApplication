using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Banking
{
    [Table("BANKHISTORY")]
    public class BankHistory
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
        [Column("HISTORYLINENO", Order = 3)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int HistoryLineNo { get; set; }

        [Column("TRANSDATE")]
        public DateTime TransactionDate { get; set; }

        [Column("POSTDATE")]
        public DateTime? PostDate { get; set; }

        [Column("POSTPERIOD")]
        public int? PostPeriodId { get; set; }

        [Column("PAYMENTMETHOD")]
        public int? PaymentMethodId { get; set; }

        [StringLength(30)]
        [Column("WITHDRAWALCHEQUENO")]
        public string WithdrawalChequeNo { get; set; }

        [Column("TRANSTYPE", TypeName = "numeric")]
        public TransactionType TransactionType { get; set; }

        [Column("MOVEMENTCLASS", TypeName = "numeric")]
        public MovementClass MovementClass { get; set; }

        [Column("COMMANDID", TypeName = "numeric")]
        public CommandId CommandId { get; set; }

        [Column("REFENTITYNO")]
        public int RefEntityId { get; set; }

        [Column("REFTRANSNO")]
        public int? RefTransactionId { get; set; }

        [Column("STATUS", TypeName = "numeric")]
        public TransactionStatus? Status { get; set; }

        [StringLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("ASSOCLINENO")]
        public int? AssociatedLineNo { get; set; }

        [StringLength(3)]
        [Column("PAYMENTCURRENCY")]
        public string PaymentCurrency { get; set; }

        [Column("PAYMENTAMOUNT")]
        public decimal? PaymentAmount { get; set; }

        [Column("BANKEXCHANGERATE")]
        public decimal? BankExchangeRate { get; set; }

        [Column("BANKAMOUNT")]
        public decimal? BankAmount { get; set; }

        [Column("BANKCHARGES")]
        public decimal? BankCharges { get; set; }

        [Column("BANKNET")]
        public decimal? BankNet { get; set; }

        [Column("LOCALAMOUNT")]
        public decimal? LocalAmount { get; set; }

        [Column("LOCALCHARGES")]
        public decimal? LocalCharges { get; set; }

        [Column("LOCALEXCHANGERATE")]
        public decimal? LocalExchangeRate { get; set; }

        [Column("LOCALNET")]
        public decimal? LocalNet { get; set; }

        [Column("BANKCATEGORY")]
        public short? BankCategory { get; set; }

        [StringLength(30)]
        [Column("REFERENCE")]
        public string Reference { get; set; }

        [Column("ISRECONCILED")]
        public decimal IsReconciled { get; set; }

        [Column("GLMOVEMENTNO")]
        public int? GlMovementNo { get; set; }
    }
}
