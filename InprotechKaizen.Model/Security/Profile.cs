using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Security
{
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1724:TypeNamesShouldNotMatchNamespaces")]
    [Table("PROFILES")]
    public class Profile
    {
        [Obsolete("For persistence only.")]
        public Profile()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public Profile(int id, string name, string description = null)
        {
            Id = id;
            Name = name;
            Description = description;
            ProfileAttributes = new Collection<ProfileAttribute>();
        }

        [Key]
        [Column("PROFILEID")]
        public int Id { get; protected set; }

        [Required]
        [MaxLength(50)]
        [Column("PROFILENAME")]
        public string Name { get; set; }

        [MaxLength(254)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        public virtual ICollection<ProfileAttribute> ProfileAttributes { get; protected set; }
    }
}