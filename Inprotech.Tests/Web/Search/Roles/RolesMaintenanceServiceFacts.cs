using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web;
using Inprotech.Web.Search.Roles;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Roles
{
    public class RolesMaintenanceServiceFacts : FactBase
    {
        public class DeleteRoles : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionWhenRoleNotFound()
            {
                var f = new RoleMaintenanceServiceFixture(Db);

                var exception = await Record.ExceptionAsync(async () => await f.Subject.Delete(null));

                Assert.NotNull(exception);
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldDeleteRole()
            {
                new Role(1) { RoleName = "r1", Description = "Desc", IsExternal = true }.In(Db);
                new Role(2) { RoleName = "r2", Description = "Desc1", IsExternal = true }.In(Db);
                var f = new RoleMaintenanceServiceFixture(Db);

                var deleteRequest = new RolesDeleteRequestModel
                {
                    Ids = new List<int> { 1 }
                };

                var result = await f.Subject.Delete(deleteRequest);

                Assert.Equal(false, result.HasError);
            }

            [Fact]
            public async Task ShouldBulkDeleteRoles()
            {
                new Role(1) { RoleName = "r1" }.In(Db);
                new Role(2) { RoleName = "r2" }.In(Db);
                new Role(3) { RoleName = "r3" }.In(Db);
                new Role(4) { RoleName = "r4" }.In(Db);
                new Role(5) { RoleName = "r5" }.In(Db);
                var f = new RoleMaintenanceServiceFixture(Db);

                var deleteRequest = new RolesDeleteRequestModel
                {
                    Ids = new List<int> { 1, 2, 3, 4, 5 }
                };

                var result = await f.Subject.Delete(deleteRequest);

                Assert.Equal(false, result.HasError);
            }
        }

        public class MaintainRoleDetails : FactBase
        {
            public static IEnumerable<object[]> RoleTaskData =>
                new[]
                {
                    new object[]
                    {
                        new FakePermissionSet
                        {
                            ObjectTable = "TASK",
                            GrantPermission = 0,
                            DenyPermission = 32,
                            ExpectedGrantPermission = 32,
                            ExpectedDenyPermission = 0,
                            State = PermissionItemState.Modified.ToString(),
                            OldExecutePermission = 2,
                            ExecutePermission = 1
                        }
                    },
                    new object[]
                    {
                        new FakePermissionSet
                        {
                            ObjectTable = "TASK",
                            GrantPermission = 0,
                            DenyPermission = 32,
                            ExpectedGrantPermission = 0,
                            ExpectedDenyPermission = 0,
                            State = PermissionItemState.Deleted.ToString(),
                            OldExecutePermission = 2,
                            ExecutePermission = 0
                        }
                    },
                    new object[]
                    {
                        new FakePermissionSet
                        {
                            ObjectTable = "TASK",
                            GrantPermission = 0,
                            DenyPermission = 0,
                            ExpectedGrantPermission = 32,
                            ExpectedDenyPermission = 0,
                            State = PermissionItemState.Added.ToString(),
                            OldExecutePermission = 0,
                            ExecutePermission = 1
                        }
                    },
                    new object[]
                    {
                        new FakePermissionSet
                        {
                            ObjectTable = "TASK",
                            GrantPermission = 0,
                            DenyPermission = 26,
                            ExpectedGrantPermission = 26,
                            ExpectedDenyPermission = 0,
                            State = PermissionItemState.Modified.ToString(),
                            OldInsertPermission = 1,
                            InsertPermission = 2,
                            OldUpdatePermission = 1,
                            UpdatePermission = 2,
                            OldDeletePermission = 1,
                            DeletePermission = 2
                        }
                    }
                };

            public static IEnumerable<object[]> RoleSubjectData =>
                new[]
                {
                    new object[]
                    {
                        new FakePermissionSet
                        {
                            ObjectTable = "DATATOPIC",
                            GrantPermission = 1,
                            DenyPermission = 0,
                            ExpectedGrantPermission = 0,
                            ExpectedDenyPermission = 1,
                            State = PermissionItemState.Modified.ToString(),
                            OldSelectPermission = 2,
                            SelectPermission = 1
                        }
                    },
                    new object[]
                    {
                        new FakePermissionSet
                        {
                            ObjectTable = "DATATOPIC",
                            GrantPermission = 0,
                            DenyPermission = 1,
                            ExpectedGrantPermission = 0,
                            ExpectedDenyPermission = 0,
                            State = PermissionItemState.Deleted.ToString(),
                            OldSelectPermission = 2,
                            SelectPermission = 0
                        }
                    },
                    new object[]
                    {
                        new FakePermissionSet
                        {
                            ObjectTable = "DATATOPIC",
                            GrantPermission = 0,
                            DenyPermission = 0,
                            ExpectedGrantPermission = 1,
                            ExpectedDenyPermission = 0,
                            State = PermissionItemState.Added.ToString(),
                            OldSelectPermission = 0,
                            SelectPermission = 1
                        }
                    }
                };

            public static IEnumerable<object[]> RoleWebPartData =>
                new[]
                {
                    new object[]
                    {
                        new FakePermissionSet
                        {
                            ObjectTable = "MODULE",
                            GrantPermission = 1,
                            DenyPermission = 0,
                            ExpectedGrantPermission = 0,
                            ExpectedDenyPermission = 65,
                            State = PermissionItemState.Modified.ToString(),
                            OldSelectPermission = 2,
                            SelectPermission = 1
                        }
                    },
                    new object[]
                    {
                        new FakePermissionSet
                        {
                            ObjectTable = "MODULE",
                            GrantPermission = 0,
                            DenyPermission = 65,
                            ExpectedGrantPermission = 0,
                            ExpectedDenyPermission = 0,
                            State = PermissionItemState.Deleted.ToString(),
                            OldSelectPermission = 2,
                            SelectPermission = 0,
                            OldMandatoryPermission = 2,
                            MandatoryPermission = null
                        }
                    },
                    new object[]
                    {
                        new FakePermissionSet
                        {
                            ObjectTable = "MODULE",
                            GrantPermission = 0,
                            DenyPermission = 0,
                            ExpectedGrantPermission = 1,
                            ExpectedDenyPermission = 0,
                            State = PermissionItemState.Added.ToString(),
                            OldSelectPermission = 0,
                            SelectPermission = 1
                        }
                    },
                    new object[]
                    {
                        new FakePermissionSet
                        {
                            ObjectTable = "MODULE",
                            GrantPermission = 65,
                            DenyPermission = 0,
                            ExpectedGrantPermission = 65,
                            ExpectedDenyPermission = 0,
                            State = PermissionItemState.Modified.ToString(),
                            OldMandatoryPermission = 1,
                            MandatoryPermission = 2
                        }
                    }
                };

            [Fact]
            public async Task ThrowNullExceptionWhenRoleSaveDetailsIsNull()
            {
                var f = new RoleMaintenanceServiceFixture(Db);

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.MaintainRoleDetails(new RoleSaveDetails()));
            }

            [Theory]
            [MemberData(nameof(RoleTaskData))]
            public async Task ShouldMaintainTaskDetails(FakePermissionSet inputData)
            {
                var role = new Role { RoleName = "All Internal", IsExternal = false, Description = Fixture.String("RoleDescription") }.In(Db);

                var taskSecurity = new SecurityTaskBuilder
                {
                    Name = Fixture.String("MaintainTask"),
                    TaskId = Fixture.Short()
                }.Build().In(Db);

                ConfigurePermissions(taskSecurity.Id, role.Id, inputData);

                var roleSaveDetails = new RoleSaveDetails
                {
                    OverviewDetails = new OverviewDetails
                    {
                        RoleId = role.Id,
                        RoleName = role.RoleName,
                        Description = role.Description
                    },
                    TaskDetails = new List<TaskDetails>
                    {
                        new()
                        {
                            LevelTable = "ROLE",
                            ObjectTable = inputData.ObjectTable,
                            LevelKey = role.Id,
                            ObjectIntegerKey = taskSecurity.Id,
                            OldExecutePermission = inputData.OldExecutePermission,
                            OldInsertPermission = inputData.OldInsertPermission,
                            OldUpdatePermission = inputData.OldUpdatePermission,
                            OldDeletePermission = inputData.OldDeletePermission,
                            ExecutePermission = inputData.ExecutePermission,
                            InsertPermission = inputData.InsertPermission,
                            UpdatePermission = inputData.UpdatePermission,
                            DeletePermission = inputData.DeletePermission,
                            State = inputData.State
                        }
                    }
                };

                var fixture = new RoleMaintenanceServiceFixture(Db);
                fixture.WithValidation();
                var result = await fixture.Subject.MaintainRoleDetails(roleSaveDetails);

                Assert.Equal(result.Result, "success");

                if (inputData.State == PermissionItemState.Modified.ToString())
                {
                    var modifiedTaskPermissions = Db.Set<Permission>().Single(_ => _.LevelKey == role.Id
                                                                                   && _.LevelTable == "ROLE"
                                                                                   && _.ObjectIntegerKey == taskSecurity.Id
                                                                                   && _.ObjectTable == inputData.ObjectTable);

                    Assert.Equal(inputData.ExpectedGrantPermission, modifiedTaskPermissions.GrantPermission);
                    Assert.Equal(inputData.ExpectedDenyPermission, modifiedTaskPermissions.DenyPermission);
                }

                if (inputData.State == PermissionItemState.Deleted.ToString())
                {
                    Assert.Empty(Db.Set<Permission>().Where(_ => _.LevelKey == role.Id
                                                                 && _.LevelTable == "ROLE"
                                                                 && _.ObjectIntegerKey == taskSecurity.Id
                                                                 && _.ObjectTable == inputData.ObjectTable));
                }

                if (inputData.State == PermissionItemState.Added.ToString())
                {
                    Assert.Equal(1, Db.Set<Permission>().Count(_ => _.LevelKey == role.Id
                                                                    && _.LevelTable == "ROLE"
                                                                    && _.ObjectIntegerKey == taskSecurity.Id
                                                                    && _.ObjectTable == inputData.ObjectTable));
                }
            }

            [Theory]
            [MemberData(nameof(RoleSubjectData))]
            public async Task ShouldMaintainSubjectDetails(FakePermissionSet inputData)
            {
                var role = new Role { RoleName = "All Internal", IsExternal = false, Description = Fixture.String("RoleDescription") }.In(Db);

                var subject = new DataTopic
                {
                    Name = Fixture.String("MaintainSubject"),
                    Id = Fixture.Short()
                }.In(Db);

                ConfigurePermissions(subject.Id, role.Id, inputData);

                var roleSaveDetails = new RoleSaveDetails
                {
                    OverviewDetails = new OverviewDetails
                    {
                        RoleId = role.Id,
                        RoleName = role.RoleName,
                        Description = role.Description
                    },
                    SubjectDetails = new List<SubjectDetails>
                    {
                        new()
                        {
                            LevelTable = "ROLE",
                            ObjectTable = inputData.ObjectTable,
                            LevelKey = role.Id,
                            ObjectIntegerKey = subject.Id,
                            OldSelectPermission = inputData.OldSelectPermission,
                            SelectPermission = inputData.SelectPermission,
                            State = inputData.State
                        }
                    }
                };

                var fixture = new RoleMaintenanceServiceFixture(Db);
                fixture.WithValidation();
                var result = await fixture.Subject.MaintainRoleDetails(roleSaveDetails);

                Assert.Equal(result.Result, "success");

                if (inputData.State == PermissionItemState.Modified.ToString())
                {
                    var modifiedTaskPermissions = Db.Set<Permission>().Single(_ => _.LevelKey == role.Id
                                                                                   && _.LevelTable == "ROLE"
                                                                                   && _.ObjectIntegerKey == subject.Id
                                                                                   && _.ObjectTable == inputData.ObjectTable);

                    Assert.Equal(inputData.ExpectedGrantPermission, modifiedTaskPermissions.GrantPermission);
                    Assert.Equal(inputData.ExpectedDenyPermission, modifiedTaskPermissions.DenyPermission);
                }

                if (inputData.State == PermissionItemState.Deleted.ToString())
                {
                    Assert.Empty(Db.Set<Permission>().Where(_ => _.LevelKey == role.Id
                                                                 && _.LevelTable == "ROLE"
                                                                 && _.ObjectIntegerKey == subject.Id
                                                                 && _.ObjectTable == inputData.ObjectTable));
                }

                if (inputData.State == PermissionItemState.Added.ToString())
                {
                    Assert.Equal(1, Db.Set<Permission>().Count(_ => _.LevelKey == role.Id
                                                                    && _.LevelTable == "ROLE"
                                                                    && _.ObjectIntegerKey == subject.Id
                                                                    && _.ObjectTable == inputData.ObjectTable));
                }
            }

            [Theory]
            [MemberData(nameof(RoleWebPartData))]
            public async Task ShouldMaintainWebPartDetails(FakePermissionSet inputData)
            {
                var role = new Role { RoleName = "All Internal", IsExternal = false, Description = Fixture.String("RoleDescription") }.In(Db);

                var webPart = new WebpartModule
                {
                    Title = Fixture.String("MaintainWebpart"),
                    Id = Fixture.Short()
                }.In(Db);

                ConfigurePermissions(webPart.Id, role.Id, inputData);

                var roleSaveDetails = new RoleSaveDetails
                {
                    OverviewDetails = new OverviewDetails
                    {
                        RoleId = role.Id,
                        RoleName = role.RoleName,
                        Description = role.Description
                    },
                    SubjectDetails = new List<SubjectDetails>
                    {
                        new()
                        {
                            LevelTable = "ROLE",
                            ObjectTable = inputData.ObjectTable,
                            LevelKey = role.Id,
                            ObjectIntegerKey = webPart.Id,
                            OldSelectPermission = inputData.OldSelectPermission,
                            SelectPermission = inputData.SelectPermission,
                            State = inputData.State
                        }
                    }
                };

                var fixture = new RoleMaintenanceServiceFixture(Db);
                fixture.WithValidation();
                var result = await fixture.Subject.MaintainRoleDetails(roleSaveDetails);

                Assert.Equal(result.Result, "success");

                if (inputData.State == PermissionItemState.Modified.ToString())
                {
                    var modifiedTaskPermissions = Db.Set<Permission>().Single(_ => _.LevelKey == role.Id
                                                                                   && _.LevelTable == "ROLE"
                                                                                   && _.ObjectIntegerKey == webPart.Id
                                                                                   && _.ObjectTable == inputData.ObjectTable);

                    Assert.Equal(inputData.ExpectedGrantPermission, modifiedTaskPermissions.GrantPermission);
                    Assert.Equal(inputData.ExpectedDenyPermission, modifiedTaskPermissions.DenyPermission);
                }

                if (inputData.State == PermissionItemState.Deleted.ToString())
                {
                    Assert.Empty(Db.Set<Permission>().Where(_ => _.LevelKey == role.Id
                                                                 && _.LevelTable == "ROLE"
                                                                 && _.ObjectIntegerKey == webPart.Id
                                                                 && _.ObjectTable == inputData.ObjectTable));
                }

                if (inputData.State == PermissionItemState.Added.ToString())
                {
                    Assert.Equal(1, Db.Set<Permission>().Count(_ => _.LevelKey == role.Id
                                                                    && _.LevelTable == "ROLE"
                                                                    && _.ObjectIntegerKey == webPart.Id
                                                                    && _.ObjectTable == inputData.ObjectTable));
                }
            }

            [Fact]
            public async Task ShouldReturnErrorWhenRoleNameIsAlreadyExists()
            {
                var f = new RoleMaintenanceServiceFixture(Db);
                new Role(1) { RoleName = "Role", Description = "Desc", IsExternal = true }.In(Db);

                var roleSaveDetails = new RoleSaveDetails
                {
                    OverviewDetails = new OverviewDetails
                    {
                        RoleId = 1,
                        RoleName = "Role"
                    },
                };
                f.WithUniqueValidationError("rolename");
                var result = await f.Subject.MaintainRoleDetails(roleSaveDetails);
                Assert.NotNull(result.Errors);
                Assert.Single((IEnumerable<ValidationError>)result.Errors);
                Assert.Equal("rolename", ((IEnumerable<ValidationError>)result.Errors).First().Field);
                Assert.Equal("field.errors.notunique", ((IEnumerable<ValidationError>)result.Errors).First().Message);
            }

            void ConfigurePermissions(int taskSecurityId, int roleId, FakePermissionSet inputData)
            {
                if (inputData.State != PermissionItemState.Added.ToString())
                {
                    new Permission
                    {
                        DenyPermission = inputData.DenyPermission,
                        GrantPermission = inputData.GrantPermission,
                        LevelKey = roleId,
                        LevelTable = "ROLE",
                        ObjectIntegerKey = taskSecurityId,
                        ObjectTable = inputData.ObjectTable
                    }.In(Db);
                }

                if (inputData.State != PermissionItemState.Added.ToString())
                {
                    new FakePermissionsSet
                    {
                        GrantPermission = inputData.GrantPermission,
                        DenyPermission = inputData.DenyPermission,
                        ObjectIntegerKey = taskSecurityId,
                        ObjectTable = inputData.ObjectTable,
                        LevelTable = "ROLE",
                        ExecutePermission = inputData.OldExecutePermission.HasValue ? Convert.ToByte(inputData.OldExecutePermission) : null,
                        InsertPermission = inputData.OldInsertPermission.HasValue ? Convert.ToByte(inputData.OldInsertPermission) : null,
                        UpdatePermission = inputData.OldUpdatePermission.HasValue ? Convert.ToByte(inputData.OldUpdatePermission) : null,
                        DeletePermission = inputData.OldDeletePermission.HasValue ? Convert.ToByte(inputData.OldDeletePermission) : null,
                        SelectPermission = inputData.OldSelectPermission.HasValue ? Convert.ToByte(inputData.OldSelectPermission) : null,
                        LevelKey = roleId
                    }.In(Db);
                }

                if (inputData.State == PermissionItemState.Modified.ToString()
                    || inputData.State == PermissionItemState.Added.ToString())
                {
                    new FakePermissionsSet
                    {
                        GrantPermission = inputData.ExpectedGrantPermission,
                        DenyPermission = inputData.ExpectedDenyPermission,
                        ObjectIntegerKey = taskSecurityId,
                        ObjectTable = inputData.ObjectTable,
                        LevelTable = "ROLE",
                        ExecutePermission = inputData.ExecutePermission,
                        InsertPermission = inputData.InsertPermission,
                        UpdatePermission = inputData.UpdatePermission,
                        DeletePermission = inputData.DeletePermission,
                        SelectPermission = inputData.SelectPermission,
                        LevelKey = roleId
                    }.In(Db);
                }
            }
        }

        public class CreateRole : FactBase
        {
            [Fact]
            public async Task ThrowNullExceptionWhenSaveRoleIsNull()
            {
                var f = new RoleMaintenanceServiceFixture(Db);

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.CreateRole(null));
            }

            [Fact]
            public async Task ShouldCreateRole()
            {
                var f = new RoleMaintenanceServiceFixture(Db);

                var saveRole = new OverviewDetails
                {
                    RoleName = Fixture.String(),
                    Description = Fixture.String(),
                    IsExternal = Fixture.Boolean()
                };
                f.WithValidation();
                var result = await f.Subject.CreateRole(saveRole);
                Assert.Equal(1, result.RoleId);
            }

            [Fact]
            public async Task ShouldReturnErrorWhenRoleNameIsAlreadyExists()
            {
                var f = new RoleMaintenanceServiceFixture(Db);
                new Role(1) { RoleName = "Role", Description = "Desc", IsExternal = true }.In(Db);

                var overviewDetails = new OverviewDetails
                {
                    RoleName = "Role",
                    RoleId = 1
                };
                f.WithUniqueValidationError("rolename");
                var result = await f.Subject.CreateRole(overviewDetails);
                Assert.NotNull(result.Errors);
                Assert.Single((IEnumerable<ValidationError>)result.Errors);
                Assert.Equal("rolename", ((IEnumerable<ValidationError>)result.Errors).First().Field);
                Assert.Equal("field.errors.notunique", ((IEnumerable<ValidationError>)result.Errors).First().Message);
            }
        }

        public class DuplicateRole : FactBase
        {
            [Fact]
            public async Task ThrowNullExceptionWhenDuplicateRoleIsNull()
            {
                var f = new RoleMaintenanceServiceFixture(Db);

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.DuplicateRole(null, 0));
            }

            [Fact]
            public async Task ShouldDuplicateRole()
            {
                var f = new RoleMaintenanceServiceFixture(Db);
                new Permission { ObjectTable = "MODULE", ObjectIntegerKey = Fixture.Integer(), LevelKey = 1, LevelTable = "ROLE", GrantPermission = 1, DenyPermission = 0 }.In(Db);
                new Permission { ObjectTable = "TASK", ObjectIntegerKey = Fixture.Integer(), LevelKey = 1, LevelTable = "ROLE", GrantPermission = 26, DenyPermission = 0 }.In(Db);
                new Permission { ObjectTable = "DATATOPIC", ObjectIntegerKey = Fixture.Integer(), LevelKey = 1, LevelTable = "ROLE", GrantPermission = 0, DenyPermission = 1 }.In(Db);

                var overviewDetails = new OverviewDetails
                {
                    RoleName = Fixture.String()
                };
                f.WithValidation();
                var result = await f.Subject.DuplicateRole(overviewDetails, 1);
                Assert.Equal(4, result.RoleId);
            }

            [Fact]
            public async Task ShouldReturnErrorWhenRoleNameIsAlreadyExists()
            {
                var f = new RoleMaintenanceServiceFixture(Db);
                new Role(1) { RoleName = "Role1", Description = "Desc", IsExternal = true }.In(Db);

                var overviewDetails = new OverviewDetails
                {
                    RoleName = "Role1",
                    RoleId = 1
                };
                f.WithUniqueValidationError("rolename");
                var result = await f.Subject.DuplicateRole(overviewDetails, 1);
                Assert.NotNull(result.Errors);
                Assert.Single((IEnumerable<ValidationError>)result.Errors);
                Assert.Equal("rolename", ((IEnumerable<ValidationError>)result.Errors).First().Field);
                Assert.Equal("field.errors.notunique", ((IEnumerable<ValidationError>)result.Errors).First().Message);
            }
        }
    }

    public class RoleMaintenanceServiceFixture : IFixture<IRoleMaintenanceService>
    {
        public RoleMaintenanceServiceFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            RolesValidator = Substitute.For<IRolesValidator>();
            Subject = new RoleMaintenanceService(db, RolesValidator);
            SecurityContext.User.Returns(new User(Fixture.String(), false));
        }

        public ISecurityContext SecurityContext { get; set; }
        public IRolesValidator RolesValidator { get; set; }
        public IRoleMaintenanceService Subject { get; }

        public RoleMaintenanceServiceFixture WithValidation()
        {
            RolesValidator.Validate(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<Operation>()).Returns(Enumerable.Empty<ValidationError>());
            return this;
        }

        public RoleMaintenanceServiceFixture WithUniqueValidationError(string forField)
        {
            RolesValidator.Validate(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<Operation>()).Returns(new[] { ValidationErrors.NotUnique(forField) });
            return this;
        }
    }

    public class FakePermissionSet : PermissionItem
    {
        public byte GrantPermission { get; set; }
        public byte DenyPermission { get; set; }
        public byte ExpectedGrantPermission { get; set; }
        public byte ExpectedDenyPermission { get; set; }
    }
}