using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Security
{
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1711:IdentifiersShouldNotHaveIncorrectSuffix")]
    [Table("PERMISSIONS")]
    public class Permission
    {
        [Obsolete("For persistence only.")]
        public Permission()
        {
        }

        public Permission(string objectTable, byte grantPermission, byte denyPermission)
        {
            ObjectTable = objectTable;
            GrantPermission = grantPermission;
            DenyPermission = denyPermission;
        }

        [Key]
        [Column("PERMISSIONID", Order = 1)]
        public int Id { get; set; }

        [Required]
        [MaxLength(30)]
        [Column("OBJECTTABLE")]
        public string ObjectTable { get; set; }

        [Column("OBJECTINTEGERKEY")]
        public int? ObjectIntegerKey { get; set; }

        [MaxLength(30)]
        [Column("OBJECTSTRINGKEY")]
        public string ObjectStringKey { get; set; }

        [MaxLength(30)]
        [Column("LEVELTABLE")]
        public string LevelTable { get; set; }

        [Column("LEVELKEY")]
        public int? LevelKey { get; set; }

        [Column("GRANTPERMISSION")]
        public byte GrantPermission { get; set; }

        [Column("DENYPERMISSION")]
        public byte DenyPermission { get; set; }
    }
}
