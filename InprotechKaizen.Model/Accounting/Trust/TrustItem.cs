using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Trust
{
    [Table("TRUSTITEM")]
    public class TrustItem
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

        [Required]
        [StringLength(20)]
        [Column("ITEMNO")]
        public string ItemNo { get; set; }

        [Column("ITEMDATE")]
        public DateTime ItemDate { get; set; }

        [Column("POSTDATE")]
        public DateTime? PostDate { get; set; }

        [Column("POSTPERIOD")]
        public int? PostPeriodId { get; set; }

        [Column("CLOSEPOSTDATE")]
        public DateTime? ClosePostDate { get; set; }

        [Column("CLOSEPOSTPERIOD")]
        public int? ClosePostPeriodId { get; set; }

        [Column("ITEMTYPE", TypeName = "numeric")]
        public ItemType? ItemType { get; set; }

        [Column("EMPLOYEENO")]
        public int? StaffId { get; set; }

        [StringLength(3)]
        [Column("CURRENCY")]
        public string Currency { get; set; }

        [Column("EXCHRATE")]
        public decimal? ExchangeRate { get; set; }

        [Column("LOCALVALUE")]
        public decimal? LocalValue { get; set; }

        [Column("FOREIGNVALUE")]
        public decimal? ForeignValue { get; set; }

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

        [Column("LONGDESCRIPTION", TypeName = "nText")]
        public string LongDescription { get; set; }
    }
}
