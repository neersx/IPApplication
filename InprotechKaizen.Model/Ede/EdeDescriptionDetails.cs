using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDEDESCRIPTIONDETAILS")]
    public class EdeDescriptionDetails
    {
        [Key]
        [Column("ROWID")]
        public int Id { get; set; }

        [Column("BATCHNO")]
        public int? BatchId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("TRANSACTIONIDENTIFIER")]
        public string TransactionIdentifier { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("DESCRIPTIONCODE")]
        public string DescriptionCode { get; set; }

        [Column("DESCRIPTIONTEXT")]
        public string DescriptionText { get; set; }
    }
}