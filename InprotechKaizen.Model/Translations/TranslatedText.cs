using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Translations
{
    [Table("TRANSLATEDTEXT")]
    public class TranslatedText
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly", MessageId = "Tid")]
        [Key]
        [Column("TID", Order = 0)]
        public int Tid { get; set; }

        [Key]
        [MaxLength(10)]
        [Column("CULTURE", Order = 1)]
        public string CultureId { get; set; }

        [MaxLength(3900)]
        [Column("SHORTTEXT")]
        public string ShortText { get; set; }

        [Column("LONGTEXT")]
        public string LongText { get; set; }

        [Column("HASSOURCECHANGED")]
        public bool HasSourceChanged { get; set; }
    }
}