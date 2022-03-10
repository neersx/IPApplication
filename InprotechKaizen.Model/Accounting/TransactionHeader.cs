using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("TRANSACTIONHEADER")]
    public class TransactionHeader
    {
        [Key]
        [Column("ENTITYNO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int EntityId { get; set; }

        [Key]
        [Column("TRANSNO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int TransactionId { get; set; }

        [Column("EMPLOYEENO")]
        public int? StaffId { get; set; }

        [Column("TRANSDATE")]
        public DateTime TransactionDate { get; set; }

        [Column("TRANSTYPE", TypeName = "numeric")]
        public TransactionType TransactionType { get; set; }

        [Required]
        [MaxLength(30)]
        [Column("USERID")]
        public string UserLoginId { get; set; }

        [Column("IDENTITYID")]
        public int IdentityId { get; set; }

        [Column("ENTRYDATE")]
        public DateTime EntryDate { get; set; }

        [Column("SOURCE", TypeName = "numeric")]
        public SystemIdentifier Source { get; set; }

        [Column("TRANPOSTPERIOD")]
        public int? PostPeriodId { get; set; }

        [Column("TRANSTATUS", TypeName = "numeric")]
        public TransactionStatus? TransactionStatus { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LogDateTimeStamp { get; set; }
    }
}