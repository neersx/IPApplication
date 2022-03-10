using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Security
{
    [Table("DATATOPIC")]
    public class DataTopic
    {
        [Obsolete("For persistence only.")]
        public DataTopic()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public DataTopic(short id, string name)
        {
            Id = id;
            Name = name;
        }

        [Key]
        [Column("TOPICID")]
        public short Id { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("TOPICNAME")]
        public string Name { get; set; }

        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("TOPICNAME_TID")]
        public int? TopicNameTId { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }

        [Column("ISINTERNAL")]
        public bool IsInternal { get; set; }

        [Column("ISEXTERNAL")]
        public bool IsExternal { get; set; }
    }
}