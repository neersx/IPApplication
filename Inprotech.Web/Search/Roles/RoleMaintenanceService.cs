using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Extentions;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Search.Roles
{
    public interface IRoleMaintenanceService
    {
        Task<dynamic> MaintainRoleDetails(RoleSaveDetails roleSaveDetails);
        Task<RolesDeleteResponseModel> Delete(RolesDeleteRequestModel deleteRequestModel);
        Task<dynamic> CreateRole(OverviewDetails overviewDetails);
        Task<dynamic> DuplicateRole(OverviewDetails overviewDetails, int roleId);
    }

    public class RoleMaintenanceService : IRoleMaintenanceService
    {
        readonly IDbContext _dbContext;
        readonly IRolesValidator _rolesValidator;

        public RoleMaintenanceService(IDbContext dbContext, IRolesValidator rolesValidator)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _rolesValidator = rolesValidator ?? throw new ArgumentNullException(nameof(rolesValidator));
        }

        public async Task<dynamic> MaintainRoleDetails(RoleSaveDetails roleSaveDetails)
        {
            if (roleSaveDetails.OverviewDetails == null)
            {
                throw new ArgumentNullException(nameof(roleSaveDetails));
            }

            var validationErrors = _rolesValidator.Validate(roleSaveDetails.OverviewDetails.RoleId, roleSaveDetails.OverviewDetails.RoleName, Operation.Update).ToArray();
            if (validationErrors.Any()) return validationErrors.AsErrorResponse();
            var role = _dbContext.Set<Role>()
                                 .Single(_ => _.Id == roleSaveDetails.OverviewDetails.RoleId);

            role.Description = roleSaveDetails.OverviewDetails.Description;
            role.RoleName = roleSaveDetails.OverviewDetails.RoleName;

            using (var t = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                if (roleSaveDetails.TaskDetails != null)
                {
                    UpdatePermissions(roleSaveDetails.TaskDetails);
                    DeletePermissions(roleSaveDetails.TaskDetails);
                    InsertPermissions(roleSaveDetails.TaskDetails);
                }

                if (roleSaveDetails.WebPartDetails != null)
                {
                    if (roleSaveDetails.WebPartDetails.Any(i => i.State == PermissionItemState.Deleted.ToString()))
                    {
                        DeletePermissions(roleSaveDetails.WebPartDetails);
                        var itemsToInsert = roleSaveDetails.WebPartDetails.Where(_ => _.State == PermissionItemState.Deleted.ToString());
                        foreach (var item in itemsToInsert)
                        {
                            var permissionToAdd = _dbContext.GetPermission(item.LevelTable, item.LevelKey, item.ObjectTable, item.ObjectIntegerKey.GetValueOrDefault(),
                                                                           item.ObjectStringKey, item.SelectPermission, item.MandatoryPermission, item.InsertPermission,
                                                                           item.UpdatePermission, item.DeletePermission, item.ExecutePermission)
                                                            .ToArray().First();

                            _dbContext.Set<Permission>().Add(new Permission(item.ObjectTable, permissionToAdd.GrantPermission, permissionToAdd.DenyPermission)
                            {
                                LevelKey = item.LevelKey,
                                LevelTable = item.LevelTable,
                                ObjectIntegerKey = item.ObjectIntegerKey,
                                ObjectStringKey = item.ObjectStringKey
                            });
                        }
                    }

                    InsertPermissions(roleSaveDetails.WebPartDetails);
                    UpdatePermissions(roleSaveDetails.WebPartDetails);
                }

                if (roleSaveDetails.SubjectDetails != null)
                {
                    UpdatePermissions(roleSaveDetails.SubjectDetails);
                    DeletePermissions(roleSaveDetails.SubjectDetails);
                    InsertPermissions(roleSaveDetails.SubjectDetails);
                }

                await _dbContext.SaveChangesAsync();

                t.Complete();
            }

            return new
            {
                Result = "success"
            };
        }

        public async Task<RolesDeleteResponseModel> Delete(RolesDeleteRequestModel deleteRequestModel)
        {
            if (deleteRequestModel == null) throw new ArgumentNullException(nameof(deleteRequestModel));

            var response = new RolesDeleteResponseModel();
            var role = _dbContext.Set<Role>().Where(_ => deleteRequestModel.Ids.Contains(_.Id)).ToArray();
            if (!role.Any()) throw new InvalidDataException(nameof(role));
            using (var txScope = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                response.InUseIds = new List<int>();
                foreach (var r in role)
                {
                    try
                    {
                        _dbContext.Set<Role>().Remove(r);
                        await _dbContext.SaveChangesAsync();
                    }
                    catch (Exception e)
                    {
                        var sqlException = e.FindInnerException<SqlException>();
                        if (sqlException != null && sqlException.Number == (int)SqlExceptionType.ForeignKeyConstraintViolationsOnDelete)
                        {
                            response.InUseIds.Add(r.Id);
                        }

                        _dbContext.Detach(r);
                    }
                }

                txScope.Complete();
                if (response.InUseIds.Any())
                {
                    response.HasError = true;
                    response.Message = ConfigurationResources.InUseErrorMessage;
                    return response;
                }
            }

            return response;
        }

        public async Task<dynamic> CreateRole(OverviewDetails overviewDetails)
        {
            if (overviewDetails == null)
            {
                throw new ArgumentNullException(nameof(overviewDetails));
            }

            var validationErrors = _rolesValidator.Validate(overviewDetails.RoleId, overviewDetails.RoleName, Operation.Add).ToArray();
            if (validationErrors.Any())
            {
                return validationErrors.AsErrorResponse();
            }

            var role = new Role
            {
                RoleName = overviewDetails.RoleName,
                Description = overviewDetails.Description,
                IsExternal = overviewDetails.IsExternal
            };

            _dbContext.Set<Role>().Add(role);

            await _dbContext.SaveChangesAsync();

            return new
            {
                Result = "success",
                RoleId = role.Id
            };
        }

        public async Task<dynamic> DuplicateRole(OverviewDetails overviewDetails, int roleId)
        {
            var createResult = await CreateRole(overviewDetails);

            if (createResult.GetType().GetProperty("Errors") != null)
            {
                return createResult;
            }

            var permissions = _dbContext.Set<Permission>().Where(x => x.LevelTable == "ROLE" && x.LevelKey == roleId).ToArray();

            foreach (var permission in permissions)
            {
                permission.LevelKey = createResult.RoleId;
                _dbContext.Set<Permission>().Add(permission);
            }

            await _dbContext.SaveChangesAsync();

            return new
            {
                Result = "success",
                createResult.RoleId
            };
        }

        void UpdatePermissions<T>(IReadOnlyCollection<T> items) where T : PermissionItem
        {
            if (items.Any(i => i.State == PermissionItemState.Modified.ToString()))
            {
                var itemsToModify = items.Where(_ => _.State == PermissionItemState.Modified.ToString());

                foreach (var item in itemsToModify)
                {
                    var newPermissions = _dbContext.GetPermission(item.LevelTable, item.LevelKey, item.ObjectTable, item.ObjectIntegerKey.GetValueOrDefault(),
                                                                  item.ObjectStringKey, item.SelectPermission, item.MandatoryPermission, item.InsertPermission,
                                                                  item.UpdatePermission, item.DeletePermission, item.ExecutePermission).ToArray().First();

                    var oldPermissions = _dbContext.GetPermission(item.LevelTable, item.LevelKey, item.ObjectTable, item.ObjectIntegerKey.GetValueOrDefault(),
                                                                  item.ObjectStringKey, item.OldSelectPermission, item.OldMandatoryPermission, item.OldInsertPermission,
                                                                  item.OldUpdatePermission, item.OldDeletePermission, item.OldExecutePermission).ToArray().First();

                    var permissionToUpdate = _dbContext.Set<Permission>().Single(p => p.GrantPermission == oldPermissions.GrantPermission
                                                                                      && p.DenyPermission == oldPermissions.DenyPermission
                                                                                      && p.ObjectTable == item.ObjectTable
                                                                                      && p.ObjectIntegerKey == item.ObjectIntegerKey
                                                                                      && p.ObjectStringKey == item.ObjectStringKey
                                                                                      && p.LevelTable == item.LevelTable
                                                                                      && p.LevelKey == item.LevelKey);

                    permissionToUpdate.GrantPermission = newPermissions.GrantPermission;
                    permissionToUpdate.DenyPermission = newPermissions.DenyPermission;
                }
            }
        }

        void DeletePermissions<T>(IReadOnlyCollection<T> items) where T : PermissionItem
        {
            if (items.Any(i => i.State == PermissionItemState.Deleted.ToString()))
            {
                var itemsToDelete = items.Where(_ => _.State == PermissionItemState.Deleted.ToString());
                foreach (var item in itemsToDelete)
                {
                    var oldPermissions = _dbContext.GetPermission(item.LevelTable, item.LevelKey, item.ObjectTable, item.ObjectIntegerKey.GetValueOrDefault(),
                                                                  item.ObjectStringKey, item.OldSelectPermission, item.OldMandatoryPermission, item.OldInsertPermission,
                                                                  item.OldUpdatePermission, item.OldDeletePermission, item.OldExecutePermission)
                                                   .ToArray().First();

                    var permissionToDelete = _dbContext.Set<Permission>().Single(p => p.GrantPermission == oldPermissions.GrantPermission
                                                                                      && p.DenyPermission == oldPermissions.DenyPermission
                                                                                      && p.ObjectTable == item.ObjectTable
                                                                                      && p.ObjectIntegerKey == item.ObjectIntegerKey
                                                                                      && p.ObjectStringKey == item.ObjectStringKey
                                                                                      && p.LevelTable == item.LevelTable
                                                                                      && p.LevelKey == item.LevelKey);
                    _dbContext.Set<Permission>().Remove(permissionToDelete);
                }
            }
        }

        void InsertPermissions<T>(IReadOnlyCollection<T> items) where T : PermissionItem
        {
            if (items.Any(i => i.State == PermissionItemState.Added.ToString()))
            {
                var itemsToAdd = items.Where(_ => _.State == PermissionItemState.Added.ToString());

                foreach (var item in itemsToAdd)
                {
                    var permissionToAdd = _dbContext.GetPermission(item.LevelTable, item.LevelKey, item.ObjectTable, item.ObjectIntegerKey.GetValueOrDefault(),
                                                                   item.ObjectStringKey, item.SelectPermission, item.MandatoryPermission, item.InsertPermission,
                                                                   item.UpdatePermission, item.DeletePermission, item.ExecutePermission)
                                                    .ToArray().First();

                    _dbContext.Set<Permission>().Add(new Permission(item.ObjectTable, permissionToAdd.GrantPermission, permissionToAdd.DenyPermission)
                    {
                        LevelKey = item.LevelKey,
                        LevelTable = item.LevelTable,
                        ObjectIntegerKey = item.ObjectIntegerKey,
                        ObjectStringKey = item.ObjectStringKey
                    });
                }
            }
        }
    }

    public enum PermissionItemState
    {
        Modified,
        Deleted,
        Added
    }

    public class RoleSaveDetails
    {
        public OverviewDetails OverviewDetails { get; set; }
        public List<TaskDetails> TaskDetails { get; set; }
        public List<WebPartDetails> WebPartDetails { get; set; }
        public List<SubjectDetails> SubjectDetails { get; set; }
    }

    public class OverviewDetails
    {
        public int RoleId { get; set; }

        [Required]
        [MaxLength(254)]
        public string RoleName { get; set; }

        [MaxLength(1000)]
        public string Description { get; set; }

        public bool IsExternal { get; set; }
    }

    public class RolesDeleteResponseModel
    {
        public List<int> InUseIds { get; set; }
        public bool HasError { get; set; }
        public string Message { get; set; }
    }

    public class RolesDeleteRequestModel
    {
        public List<int> Ids { get; set; }
    }
}