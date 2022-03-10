using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("NAMEGROUPS")]
    public class NameGroup
    {
        [Obsolete("For Persistence Only")]
        public NameGroup()
        {
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public NameGroup(short id, string name)
        {
            if(name == null) throw new ArgumentNullException("name");

            Id = id;
            Value = name;

            Members = new Collection<NameGroupMember>();
        }

        [Column("NAMEGROUP")]
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short Id { get; private set; }

        [Column("GROUPDESCRIPTION")]
        [MaxLength(50)]
        public string Value { get; set; }

        [Column("GROUPDESCRIPTION_TID")]
        public int? NameTId { get; set; }

        public virtual ICollection<NameGroupMember> Members { get; protected set; }
    }
}