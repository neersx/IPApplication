using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("NARRATIVESUBSTITUT")]
    public class NarrativeSubstitute
    {
        [Key]
        [Column("NARRATIVENO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short NarrativeNo { get; set; }

        [Key]
        [Column("SEQUENCE", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short Sequence { get; set; }

        [Column("ALTERNATENARRATIVE")]
        public short? AlternateNarrative { get; set; }

        [Column("NAMENO")]
        public int? NameId { get; set; }

        [Column("LANGUAGE")]
        public int? LanguageId { get; set; }
    }
}