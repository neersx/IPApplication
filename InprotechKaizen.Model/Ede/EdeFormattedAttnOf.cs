using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDEFORMATTEDATTNOF")]
    public class EdeFormattedAttnOf
    {
        [Key]
        [Column("ROWID")]
        public int Id { get; set; }

        [Column("BATCHNO")]
        public int? BatchId { get; set; }

        [MaxLength(50)]
        [Column("USERID")]
        public string UserId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("TRANSACTIONIDENTIFIER")]
        public string TransactionIdentifier { get; set; }

        [MaxLength(50)]
        [Column("NAMETYPECODE")]
        public string NameTypeCode { get; set; }

        [Column("NAMESEQUENCENUMBER")]
        public int? NameSequenceNumber { get; set; }

        [MaxLength(254)]
        [Column("PAYMENTIDENTIFIER")]
        public string PaymentIdentifier { get; set; }

        [MaxLength(50)]
        [Column("NAMEPREFIX")]
        public string NamePrefix { get; set; }

        [MaxLength(254)]
        [Column("FIRSTNAME")]
        public string FirstName { get; set; }

        [MaxLength(254)]
        [Column("LASTNAME")]
        public string LastName { get; set; }

        [Column("NAMENO")]
        public int? NameId { get; set; }
    }
}