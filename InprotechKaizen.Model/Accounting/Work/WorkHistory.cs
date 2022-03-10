using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Work
{
    [Table("WORKHISTORY")]
    public class WorkHistory
    {
        [Key]
        [Column("ENTITYNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int EntityId { get; set; }

        [Key]
        [Column("TRANSNO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int TransactionId { get; set; }

        [Key]
        [Column("WIPSEQNO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short WipSequenceNo { get; set; }

        [Key]
        [Column("HISTORYLINENO", Order = 3)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short HistoryLineNo { get; set; }

        [Column("ACCTENTITYNO")]
        public int? AccountEntityId { get; set; }

        [Column("ACCTCLIENTNO")]
        public int? AccountClientId { get; set; }

        [Column("EMPLOYEENO")]
        public int? StaffId { get; set; }

        [Column("ASSOCIATENO")]
        public int? AssociateId { get; set; }

        [Column("REFENTITYNO")]
        public int? RefEntityId { get; set; }

        [Column("REFTRANSNO")]
        public int? RefTransactionId { get; set; }

        [Column("REFACCTENTITYNO")]
        public int? RefAccountEntityId { get; set; }

        [Column("REFACCTDEBTORNO")]
        public int? RefAccountDebtorId { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("STATUS", TypeName = "numeric")]
        public TransactionStatus? Status { get; set; }

        [Column("LOCALTRANSVALUE")]
        public decimal? LocalValue { get; set; }

        [Column("FOREIGNTRANVALUE")]
        public decimal? ForeignValue { get; set; }

        [Column("FOREIGNCURRENCY")]
        public string ForeignCurrency { get; set; }

        [Column("EXCHRATE")]
        public decimal? ExchangeRate { get; set; }

        [Column("MOVEMENTCLASS", TypeName = "numeric")]
        public MovementClass? MovementClass { get; set; }
        
        [Column("COMMANDID", TypeName = "numeric")]
        public CommandId? CommandId { get; set; }

        [Column("ITEMIMPACT", TypeName = "numeric")]
        public ItemImpact? ItemImpact { get; set; }

        [Column("TRANSDATE")]
        public DateTime? TransDate { get; set; }

        [Column("POSTDATE")]
        public DateTime? PostDate { get; set; }

        [Column("POSTPERIOD")]
        public int? PostPeriodId { get; set; }

        [Column("BILLLINENO")]
        public short? BillLineNo { get; set; }

        [MaxLength(6)]
        [Column("WIPCODE")]
        public string WipCode { get; set; }

        [Column("TRANSTYPE", TypeName = "numeric")]
        public TransactionType? TransactionType { get; set; }

        [Column("DISCOUNTFLAG")]
        public decimal? DiscountFlag { get; set; }

        [Column("TOTALUNITS")]
        public short? TotalUnits { get; set; }

        [MaxLength(254)]
        [Column("SHORTNARRATIVE")]
        public string ShortNarrative { get; set; }

        [Column("LONGNARRATIVE")]
        public string LongNarrative { get; set; }

        public bool IsDiscount => DiscountFlag == 1;
        
        [Column("REASONCODE")]
        public string ReasonCode { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LogDateTimeStamp { get; set; }
    }
}