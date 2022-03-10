using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("NARRATIVETRANSLATE")]
    public class NarrativeTranslation
    {
        [Key]
        [Column("NARRATIVENO", Order = 0)]
        public short NarrativeId { get; set; }

        [Key]
        [Column("LANGUAGE", Order = 1)]
        public int LanguageId { get; set; }

        [Column("TRANSLATEDTEXT")]
        public string TranslatedText { get; set; }
    }
}