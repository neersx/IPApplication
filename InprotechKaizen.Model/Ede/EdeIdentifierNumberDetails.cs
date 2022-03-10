using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDEIDENTIFIERNUMBERDETAILS")]
    public class EdeIdentifierNumberDetails
    {
        [Key]
        [Column("ROWID")]
        public int RowId { get; set; }

        [Column("BATCHNO")]
        public int? BatchId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("TRANSACTIONIDENTIFIER")]
        public string TransactionIdentifier { get; set; }

        [MaxLength(50)]
        [Column("ASSOCIATEDCASERELATIONSHIPCODE")]
        public string AssociatedCaseRelationshipCode { get; set; }
        
        [Required]
        [MaxLength(254)]
        [Column("IDENTIFIERNUMBERTEXT")]
        public string IdentifierNumberText { get; set; }

        public virtual NumberType NumberType { get; set; }
    }
}
