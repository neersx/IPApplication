using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Web.Search.Roles
{
    public class RolesSearchOptions
    {
        public string RoleName { get; set; }

        public string Description { get; set; }

        public bool? IsExternal { get; set; }

        public PermissionsGroup PermissionsGroup { get; set; }
    }

    public class PermissionLevel
    {
        public bool? CanSelect { get; set; }

        public bool? IsMandatory { get; set; }

        public bool? CanInsert { get; set; }

        public bool? CanUpdate { get; set; }

        public bool? CanDelete { get; set; }

        public bool? CanExecute { get; set; }
    }

    public class Permissions
    {
        public ObjectTable ObjectTable { get; set; }

        public int ObjectIntegerKey { get; set; }

        public PermissionLevel PermissionLevel { get; set; }

        public PermissionType PermissionType { get; set; }
    }

    public class PermissionsGroup
    {
        public PermissionsGroup()
        {
            Permissions = Enumerable.Empty<Permissions>();
        }

        public IEnumerable<Permissions> Permissions { get; set; }
    }

    public enum ObjectTable
    {
        MODULE,
        TASK,
        DATATOPIC
    }

    public enum PermissionType
    {
        Granted = 1,
        Denied = 2,
        NotAssigned = 3
    }
}