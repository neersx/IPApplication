using System;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Security
{
    [Table("TASK")]
    public class SecurityTask
    {
        [Obsolete("For persistence only.")]
        public SecurityTask()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public SecurityTask(short id, string name)
        {
            Id = id;
            Name = name;

            ProvidedByFeatures = new Collection<Feature>();
        }

        [Key]
        [Column("TASKID")]
        public short Id { get; set; }

        [Required]
        [MaxLength(254)]
        [Column("TASKNAME")]
        public string Name { get; set; }

        [Column("TASKNAME_TID")]
        public int? TaskNameTId { get; set; }
        
        [MaxLength(1000)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }

        [Column("VERSIONID")]
        public int? VersionId { get; set; }

        public virtual Collection<Feature> ProvidedByFeatures { get; protected set; }
    }
}