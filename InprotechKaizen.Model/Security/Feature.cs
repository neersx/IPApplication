using System;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.Security
{
    [Table("FEATURE")]
    public class Feature
    {
        [Obsolete("For persistence only.")]
        public Feature()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public Feature(short id, string name, TableCode category, bool? isExternal = null, bool? isInternal = null)
        {
            if (name == null) throw new ArgumentNullException("name");

            Id = id;
            Name = name;
            Category = category;
            IsExternal = isExternal;
            IsInternal = isInternal;
            SecurityTasks = new Collection<SecurityTask>();
            WebpartModules = new Collection<WebpartModule>();
        }

        [Key]
        [Column("FEATUREID")]
        public short Id { get; protected set; }

        [Required]
        [MaxLength(50)]
        [Column("FEATURENAME")]
        public string Name { get; protected set; }

        [Column("CATEGORYID")]
        [ForeignKey("Category")]
        public int CategoryId { get; set; }

        [Column("ISEXTERNAL")]
        public bool? IsExternal { get; protected set; }

        [Column("ISINTERNAL")]
        public bool? IsInternal { get; protected set; }

        public virtual TableCode Category { get; protected set; }

        public virtual Collection<SecurityTask> SecurityTasks { get; protected set; }
        public virtual Collection<WebpartModule> WebpartModules { get; protected set; }
    }
}