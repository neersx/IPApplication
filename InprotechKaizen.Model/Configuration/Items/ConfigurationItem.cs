using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Configuration.Items
{
    [Table("CONFIGURATIONITEM")]
    public class ConfigurationItem
    {
        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public ConfigurationItem()
        {
            Components = new Collection<Component>();

            Tags = new Collection<Tag>();
        }

        [Key]
        [Column("CONFIGITEMID")]
        public int Id { get; set; }

        [Column("TASKID")]
        public short TaskId { get; set; }

        [Column("CONTEXTID")]
        public int? ContextId { get; set; }

        [Required]
        [MaxLength(512)]
        [Column("TITLE")]
        public string Title { get; set; }

        [Column("TITLE_TID")]
        public int? TitleTId { get; set; }

        [MaxLength(2000)]
        [Column("Description")]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }

        [MaxLength(15)]
        [Column("GENERICPARAM")]
        public string GenericParameter { get; set; }

        [Column("GROUPID")]
        public int? GroupId { get; set; }

        [MaxLength(2000)]
        [Column("URL")]
        public string Url { get; set; }

        [Column("IEONLY")]
        public bool IeOnly { get; set; }

        public virtual ICollection<Component> Components { get; set; }

        public virtual ICollection<Tag> Tags { get; set; }
    }
}
