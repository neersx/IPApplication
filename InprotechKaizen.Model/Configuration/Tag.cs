using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration
{
    [Table("TAGS")]
    public class Tag
    {
        [Key]
        [Column("TAGID")]
        public int Id { get; set; }

        [MaxLength(30)]
        [Column("TAGNAME")]
        public string TagName { get; set; }
    }
}