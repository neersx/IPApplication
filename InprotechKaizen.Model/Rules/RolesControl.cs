using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Rules
{
    [Table("ROLESCONTROL")]
    public class RolesControl
    {
        [Obsolete("For Persistence Only ...")]
        public RolesControl()
        {
        }

        public RolesControl(int roleId, int criteriaId, short dataEntryTaskId)
        {
            RoleId = roleId;
            CriteriaId = criteriaId;
            DataEntryTaskId = dataEntryTaskId;
        }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("ROLEID", Order = 2)]
        public int RoleId { get; set; }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("ENTRYNUMBER", Order = 1)]
        public short DataEntryTaskId { get; set; }

        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Key]
        [Column("CRITERIANO", Order = 0)]
        public int CriteriaId { get; set; }

        [Column("INHERITED")]
        public bool? Inherited { get; set; }

        [ForeignKey("RoleId")]
        public virtual Role Role { get; set; }

        public virtual DataEntryTask DataEntryTask { get; set; }
    }

    public static class RolesControlExt
    {
        public static RolesControl InheritRuleFrom(this RolesControl rolesControl, RolesControl from)
        {
            if (rolesControl == null) throw new ArgumentNullException(nameof(rolesControl));
            if (@from == null) throw new ArgumentNullException(nameof(@from));

            rolesControl.RoleId = from.RoleId;
            rolesControl.Inherited = true;
            return rolesControl;
        }
    }
}