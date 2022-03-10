using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDENAME")]
    public class EdeName
    {
        [Key]
        [Column("ROWID")]
        public int Id { get; set; }

        [Column("BATCHNO")]
        public int? BatchId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("TRANSACTIONIDENTIFIER")]
        public string TransactionId { get; set; }

        [MaxLength(50)]
        [Column("NAMETYPECODE")]
        public string NameTypeCode { get; set; }

        [Column("NAMESEQUENCENUMBER")]
        public int? NamesSequenceNo { get; set; }

        [MaxLength(254)]
        [Column("RECEIVERNAMEIDENTIFIER")]
        public string ReceiverNameIdentifier { get; set; }

        [MaxLength(254)]
        [Column("SENDERNAMEIDENTIFIER")]
        public string SenderNameIdentifier { get; set; }
    }
}
