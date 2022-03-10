using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Configuration.Screens
{
    [Table("TOPICUSAGE")]
    public class TopicUsage
    {
        [Key]
        [Column("ID")]
        public int Id { get; set; }

        [Required]
        [MaxLength(250)]
        [Column("TOPICNAME")]
        public string TopicName { get; set; }
        
        [Required]
        [MaxLength(254)]
        [Column("TOPICTITLE")]
        public string TopicTitle { get; set; }

        [Required]
        [MaxLength(2)]
        [Column("TYPE")]
        public string TopicType { get; set; }

        [Column("TOPICTITLE_TID")]
        public int? TopicTitleTId { get; set; }
    }
}
