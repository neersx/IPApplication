using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
namespace InprotechKaizen.Model.Keywords
{
    [Table("SYNONYMS")]
    public class Synonyms
    {
        [Column("KEYWORDNO", Order = 0)]
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int KeywordNo { get; set; }

        [Column("KWSYNONYM", Order = 1)]
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int KwSynonym { get; set; }
        
    }
}
