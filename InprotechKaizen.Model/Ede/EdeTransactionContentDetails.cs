using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDETRANSACTIONCONTENTDETAILS")]
    public class EdeTransactionContentDetails
    {
        [Column("BATCHNO")]
        public int? BatchId { get; set; }

        [MaxLength(50)]
        [Column("USERID")]
        public string UserID { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("TRANSACTIONIDENTIFIER")]
        public string TransactionIdentifier { get; set; }

        [MaxLength(254)]
        [Column("ALTERNATIVESENDER")]
        public string AlternativeSender { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("TRANSACTIONCODE")]
        public string TransactionCode { get; set; }

        [MaxLength(50)]
        [Column("TRANSACTIONSUBCODE")]
        public string TransactionSubcode { get; set; }

        [Column("TRANSACTIONCOMMENT")]
        public string TransactionComment { get; set; }

        [Column("ALTSENDERNAMENO")]
        public int? AlternateSenderNameId { get; set; }

        [Key]
        [Column("ROWID")]
        public int RowId { get; set; }
    }
}