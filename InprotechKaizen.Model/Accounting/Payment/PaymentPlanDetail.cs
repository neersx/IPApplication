using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Payment
{
    [Table("PAYMENTPLANDETAIL")]
    public class PaymentPlanDetail
    {
        [Key]
        [Column("PLANID", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int PlanId { get; set; }

        [Key]
        [Column("ITEMENTITYNO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int ItemEntityId { get; set; }

        [Key]
        [Column("ITEMTRANSNO", Order = 2)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int ItemTransactionId { get; set; }

        [Key]
        [Column("ACCTENTITYNO", Order = 3)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int AccountEntityId { get; set; }

        [Key]
        [Column("ACCTCREDITORNO", Order = 4)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int AccountCreditorId { get; set; }

        [Column("REFENTITYNO")]
        public int? RefEntityId { get; set; }

        [Column("REFTRANSNO")]
        public int? RefTransactionId { get; set; }

        [Column("PAYMENTAMOUNT")]
        public decimal PaymentAmount { get; set; }

        [StringLength(16)]
        [Column("FXDEALERREF")]
        public string FxDealerRef { get; set; }

        [Column("ACCOUNTID")]
        public int? AccountId { get; set; }
        
    }
}
