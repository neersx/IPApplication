using System;
using System.Linq;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Search.Roles
{
    public interface IRoleSearchService
    {
        IQueryable<Role> DoSearch(RolesSearchOptions searchOptions, string culture);
    }

    public class RoleSearchService : IRoleSearchService
    {
        readonly Func<DateTime> _clock;
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public RoleSearchService(IDbContext dbContext, ISecurityContext securityContext, Func<DateTime> clock)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _clock = clock;
        }

        public IQueryable<Role> DoSearch(RolesSearchOptions searchOptions, string culture)
        {
            if (searchOptions == null)
            {
                throw new ArgumentNullException(nameof(searchOptions));
            }

            var roles = _dbContext.Set<Role>().AsQueryable();

            if (_securityContext.User.IsExternalUser)
            {
                roles = roles.Where(_ => !_.IsExternal.HasValue || _.IsExternal.HasValue && _.IsExternal.Value);
            }

            if (!string.IsNullOrEmpty(searchOptions.RoleName))
            {
                roles = roles.Where(_ => DbFuncs.GetTranslation(_.RoleName, null, _.RoleNameTId, culture)
                                                .Contains(searchOptions.RoleName));
            }

            if (!string.IsNullOrEmpty(searchOptions.Description))
            {
                roles = roles.Where(_ => DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
                                                .Contains(searchOptions.Description));
            }

            if (searchOptions.IsExternal.HasValue)
            {
                roles = roles.Where(_ => _.IsExternal == searchOptions.IsExternal);
            }

            if (!searchOptions.PermissionsGroup.Permissions.Any())
            {
                return roles;
            }

            roles = ModulePermissions(searchOptions, roles);
            roles = TaskPermissions(searchOptions, roles);
            roles = DataTopicPermissions(searchOptions, roles);

            return roles;
        }

        IQueryable<Role> ModulePermissions(RolesSearchOptions searchOptions, IQueryable<Role> roles)
        {
            if (searchOptions.PermissionsGroup.Permissions.All(_ => _.ObjectTable != ObjectTable.MODULE)) return roles;
            {
                var p = searchOptions.PermissionsGroup.Permissions
                                     .Single(_ => _.ObjectTable == ObjectTable.MODULE);
                var permissionToCheck = p.PermissionType == PermissionType.Granted ? 1 : p.PermissionType == PermissionType.Denied ? 2 : 0;

                var applicable = from r in roles
                                 join pd in _dbContext.PermissionData("ROLE", null, ObjectTable.MODULE.ToString(), p.ObjectIntegerKey, null, _clock().Date) on r.Id equals pd.LevelKey into pdi
                                 from pdItems in pdi.DefaultIfEmpty()
                                 select new
                                 {
                                     Roles = r,
                                     PermissionData = pdItems
                                 };

                if (p.PermissionLevel.CanSelect.GetValueOrDefault())
                {
                    applicable = applicable.Where(_ => _.PermissionData != null && (int)_.PermissionData.SelectPermission == permissionToCheck);
                }

                if (p.PermissionLevel.IsMandatory.GetValueOrDefault())
                {
                    applicable = applicable.Where(_ => _.PermissionData != null && (int)_.PermissionData.MandatoryPermission == permissionToCheck);
                }

                roles = applicable.Select(_ => _.Roles);
            }

            return roles;
        }

        IQueryable<Role> TaskPermissions(RolesSearchOptions searchOptions, IQueryable<Role> roles)
        {
            if (searchOptions.PermissionsGroup.Permissions.All(_ => _.ObjectTable != ObjectTable.TASK)) return roles;
            {
                var p = searchOptions.PermissionsGroup.Permissions
                                     .Single(_ => _.ObjectTable == ObjectTable.TASK);
                var permissionToCheck = p.PermissionType == PermissionType.Granted ? 1 : p.PermissionType == PermissionType.Denied ? 2 : (int?)null;

                var applicable = from r in roles
                                 join pd in _dbContext.PermissionData("ROLE", null, ObjectTable.TASK.ToString(), p.ObjectIntegerKey, null, _clock().Date) on r.Id equals pd.LevelKey into pdi
                                 from pdItems in pdi.DefaultIfEmpty()
                                 select new
                                 {
                                     Roles = r,
                                     PermissionData = pdItems
                                 };

                if (p.PermissionType == PermissionType.NotAssigned)
                {
                    var taskPermissionLevel = _dbContext.Set<Permission>().Single(_ => _.ObjectTable == "TASK"
                                                                                       && _.ObjectIntegerKey == p.ObjectIntegerKey
                                                                                       && _.LevelKey == null
                                                                                       && _.LevelTable == null).GrantPermission;

                    if (taskPermissionLevel != 32)
                    {
                        permissionToCheck = 0;
                    }
                }

                if (p.PermissionLevel.CanExecute.GetValueOrDefault())
                {
                    applicable = applicable.Where(_ => (int)_.PermissionData.ExecutePermission == permissionToCheck);
                }

                if (p.PermissionLevel.CanInsert.GetValueOrDefault())
                {
                    applicable = applicable.Where(_ => (int)_.PermissionData.InsertPermission == permissionToCheck);
                }

                if (p.PermissionLevel.CanUpdate.GetValueOrDefault())
                {
                    applicable = applicable.Where(_ => (int)_.PermissionData.UpdatePermission == permissionToCheck);
                }

                if (p.PermissionLevel.CanDelete.GetValueOrDefault())
                {
                    applicable = applicable.Where(_ => (int)_.PermissionData.DeletePermission == permissionToCheck);
                }

                roles = applicable.Select(_ => _.Roles);
            }

            return roles;
        }

        IQueryable<Role> DataTopicPermissions(RolesSearchOptions searchOptions, IQueryable<Role> roles)
        {
            if (searchOptions.PermissionsGroup.Permissions.All(_ => _.ObjectTable != ObjectTable.DATATOPIC)) return roles;
            {
                var p = searchOptions.PermissionsGroup.Permissions
                                     .Single(_ => _.ObjectTable == ObjectTable.DATATOPIC);
                var permissionToCheck = p.PermissionType == PermissionType.Granted ? 1 : p.PermissionType == PermissionType.Denied ? 2 : (int?)null;

                var applicable = from r in roles
                                 join pd in _dbContext.PermissionData("ROLE", null, ObjectTable.DATATOPIC.ToString(), p.ObjectIntegerKey, null, _clock().Date) on r.Id equals pd.LevelKey into pdi
                                 from pdItems in pdi.DefaultIfEmpty()
                                 select new
                                 {
                                     Roles = r,
                                     PermissionData = pdItems
                                 };

                if (p.PermissionLevel.CanSelect.GetValueOrDefault())
                {
                    applicable = applicable.Where(_ => (int)_.PermissionData.SelectPermission == permissionToCheck);
                }

                roles = applicable.Select(_ => _.Roles);
            }

            return roles;
        }
    }
}