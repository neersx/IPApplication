using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration.Items
{
    [Table("CONFIGURATIONITEMGROUP")]
    public class ConfigurationItemGroup
    {
        [Column("ID")]
        public int Id { get; set; }

        [MaxLength(2000)]
        [Column("URL")]
        public string Url { get; set; }

        [Required]
        [MaxLength(512)]
        [Column("TITLE")]
        public string Title { get; set; }

        [Column("TITLE_TID")]
        public int? TitleTId { get; set; }

        [MaxLength(2000)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }
    }
}