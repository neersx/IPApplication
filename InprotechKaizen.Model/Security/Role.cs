using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Security
{
    [Table("ROLE")]
    public class Role
    {
        [Obsolete("For persistence only.")]
        public Role()
        {
        }

        public Role(int id)
        {
            Id = id;
        }

        [Key]
        [Column("ROLEID")]
        public int Id { get; protected set; }

        [MaxLength(254)]
        [Column("ROLENAME")]
        public string RoleName { get; set; }

        [Column("ROLENAME_TID")]
        public int? RoleNameTId { get; set; }

        [MaxLength(1000)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Column("ISEXTERNAL")]
        public bool? IsExternal { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }

        public virtual ICollection<User> Users { get; set; }
    }
}