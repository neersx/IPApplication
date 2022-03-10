using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Translations
{
    [Table("TRANSLATIONSOURCE")]
    public class TranslationSource
    {
        [Key]
        [Column("TRANSLATIONSOURCEID")]
        public int Id { get; set; }

        [Required]
        [MaxLength(30)]
        [Column("TABLENAME")]
        public string TableName { get; set; }

        [MaxLength(30)]
        [Column("SHORTCOLUMN")]
        public string ShortColumn { get; set; }

        [MaxLength(30)]
        [Column("LONGCOLUMN")]
        public string LongColumn { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Tid")]
        [Required]
        [MaxLength(30)]
        [Column("TIDCOLUMN")]
        public string TidColumn { get; set; }

        [Column("INUSE")]
        public bool IsInUse { get; set; }
    }

    [Table("TRANSLATEDITEMS")]
    public class TranslatedItem
    {
        [Key]
        [Column("TID")]
        public int Id { get; set; }

        [Column("TRANSLATIONSOURCEID")]
        public int SourceId { get; set; }
    }
}