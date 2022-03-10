using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDEADDRESSBOOK")]
    public class EdeAddressBook
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

        [Column("NAMENO")]
        public int? NameId { get; set; }

        [Column("NAMESEQUENCENUMBER")]
        public int? NamesSequenceNo { get; set; }

        [Column("UNRESOLVEDNAMENO")]
        public int? UnresolvedNameId { get; set; }

    }
}
