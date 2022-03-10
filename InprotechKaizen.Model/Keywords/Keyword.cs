using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Keywords
{
    [Table("KEYWORDS")]
    public class Keyword
    {
        [Column("KEYWORDNO")]
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int KeywordNo { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("KEYWORD")]
        public string KeyWord { get; set; }
        
        [Column("STOPWORD")]
        public decimal StopWord { get; set; }
    }
}
