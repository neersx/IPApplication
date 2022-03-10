using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Search.Roles;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;
using Permissions = Inprotech.Web.Search.Roles.Permissions;

namespace Inprotech.Tests.Web.Search.Roles
{
    public class RolesSearchServiceFacts : FactBase
    {
        public class ViewRoles : FactBase
        {
            readonly IPreferredCultureResolver _preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            [Fact]
            public void ThrowNullExceptionWhenSearchOptionIsNull()
            {
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());
                var f = new RolesSearchServiceFixture(Db);

                Assert.Throws<ArgumentNullException>(() => f.Subject.DoSearch(null, cultureResolver.ToString()));
            }

            [Fact]
            public void ShouldReturnAllRoles()
            {
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());

                new Role(1) { RoleName = "internal", Description = "all internal", IsExternal = false }.In(Db);
                new Role(2) { RoleName = "r1", Description = "Desc", IsExternal = true }.In(Db);
                new Role(3) { RoleName = "r2", Description = "Desc1", IsExternal = true }.In(Db);
                new Role(4) { RoleName = "r3", Description = "Desc2", IsExternal = false }.In(Db);

                var searchOptions = new RolesSearchOptions
                {
                    IsExternal = null,
                    PermissionsGroup = new PermissionsGroup()
                };
                var f = new RolesSearchServiceFixture(Db);
                var result = f.Subject.DoSearch(searchOptions, cultureResolver.ToString());
                var roles = result.ToArray();

                Assert.NotNull(result);
                Assert.Equal(roles.Length, 4);
            }

            [Fact]
            public void ShouldReturnRolesMatchingWithRoleName()
            {
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());

                new Role { RoleName = "internal", Description = "all internal", IsExternal = false }.In(Db);

                var searchOptions = new RolesSearchOptions
                {
                    RoleName = "internal",
                    Description = "all",
                    IsExternal = false,
                    PermissionsGroup = new PermissionsGroup()
                };
                var f = new RolesSearchServiceFixture(Db);

                var result = f.Subject.DoSearch(searchOptions, cultureResolver.ToString());
                Assert.NotNull(result);
                var roles = result.ToArray();
                Assert.Equal(roles.Count(), 1);
                Assert.Equal(roles[0].Description, "all internal");
                Assert.Equal(roles[0].RoleName, "internal");
            }

            [Fact]
            public void ShouldReturnDefaultSortedRoles()
            {
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());

                new Role { RoleName = "a1", IsExternal = false }.In(Db);
                new Role { RoleName = "a2", IsExternal = false }.In(Db);
                new Role { RoleName = "a3", IsExternal = false }.In(Db);
                new Role { RoleName = "a4", IsExternal = false }.In(Db);
                var searchOptions = new RolesSearchOptions
                {
                    IsExternal = false,
                    PermissionsGroup = new PermissionsGroup()
                };
                var f = new RolesSearchServiceFixture(Db);

                var result = f.Subject.DoSearch(searchOptions, cultureResolver.ToString());
                Assert.NotNull(result);
                var roles = result.ToArray();
                Assert.Equal(roles.Count(), 4);
                Assert.Equal(roles.First().RoleName, "a1");
                Assert.Equal(roles.Last().RoleName, "a4");
            }

            [Fact]
            public void ShouldReturnRolesMatchingWithWebPart()
            {
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());

                new Role(1) { RoleName = "r1", Description = "Desc", IsExternal = false }.In(Db);
                new WebpartModule { Title = "Custom Content", Description = "View external content within the web part", Id = 1 }.In(Db);
                new PermissionsRuleItem { DeletePermission = 0, MandatoryPermission = 1, InsertPermission = 0, LevelKey = 1, UpdatePermission = 0 }.In(Db);
                new PermissionsRuleItem { DeletePermission = 0, MandatoryPermission = 0, InsertPermission = 0, LevelKey = 2, UpdatePermission = 0 }.In(Db);

                var permissions = new Permissions
                {
                    ObjectIntegerKey = 1,
                    PermissionLevel = new PermissionLevel { IsMandatory = true, CanSelect = false },
                    ObjectTable = ObjectTable.MODULE,
                    PermissionType = PermissionType.Granted
                };
                var permissionsGroup = new List<Permissions> { permissions };
                var searchOptions = new RolesSearchOptions
                {
                    IsExternal = false,
                    PermissionsGroup = new PermissionsGroup { Permissions = permissionsGroup }
                };
                var f = new RolesSearchServiceFixture(Db);

                var result = f.Subject.DoSearch(searchOptions, cultureResolver.ToString());
                var roles = result.ToArray();
                Assert.Equal(roles.Length, 1);
                Assert.Equal(roles[0].RoleName, "r1");
            }

            [Fact]
            public void ShouldReturnGrantedPermissionRolesMatchingWithTask()
            {
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());

                new Role(1) { RoleName = "r1", Description = "Desc", IsExternal = false }.In(Db);
                new Role(2) { RoleName = "r2", Description = "Desc1", IsExternal = false }.In(Db);
                new Role(3) { RoleName = "r3", Description = "Desc2", IsExternal = false }.In(Db);
                new SecurityTask { Name = "Task1", Description = "Description of task", Id = 1 }.In(Db);

                new PermissionsRuleItem { DeletePermission = 2, InsertPermission = 2, LevelKey = 1, UpdatePermission = 2 }.In(Db);
                new PermissionsRuleItem { DeletePermission = 1, InsertPermission = 1, LevelKey = 2, UpdatePermission = 1 }.In(Db);
                new PermissionsRuleItem { DeletePermission = 1, InsertPermission = 1, LevelKey = 3, UpdatePermission = 1 }.In(Db);

                var permissions = new Permissions
                {
                    ObjectIntegerKey = 1,
                    PermissionLevel = new PermissionLevel { CanDelete = true, CanInsert = true, CanUpdate = true },
                    ObjectTable = ObjectTable.TASK,
                    PermissionType = PermissionType.Granted
                };
                var permissionsGroup = new List<Permissions> { permissions };
                var searchOptions = new RolesSearchOptions
                {
                    IsExternal = false,
                    PermissionsGroup = new PermissionsGroup { Permissions = permissionsGroup }
                };
                var f = new RolesSearchServiceFixture(Db);

                var result = f.Subject.DoSearch(searchOptions, cultureResolver.ToString());
                var roles = result.ToArray();
                Assert.Equal(roles.Length, 2);
                Assert.Equal(roles[0].RoleName, "r2");
                Assert.Equal(roles[1].RoleName, "r3");
            }

            [Fact]
            public void ShouldReturnDeniedPermissionRolesMatchingWithTask()
            {
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());

                new Role(1) { RoleName = "r1", Description = "Desc", IsExternal = false }.In(Db);
                new Role(2) { RoleName = "r2", Description = "Desc1", IsExternal = false }.In(Db);
                new Role(3) { RoleName = "r3", Description = "Desc2", IsExternal = false }.In(Db);
                new SecurityTask { Name = "Task1", Description = "Description of task", Id = 1 }.In(Db);
                new PermissionsRuleItem { DeletePermission = 0, InsertPermission = 0, LevelKey = 3, UpdatePermission = 0 }.In(Db);
                new PermissionsRuleItem { DeletePermission = 2, InsertPermission = 2, LevelKey = 2, UpdatePermission = 2 }.In(Db);
                new PermissionsRuleItem { DeletePermission = 2, InsertPermission = 2, LevelKey = 1, UpdatePermission = 2 }.In(Db);

                var permissions = new Permissions
                {
                    ObjectIntegerKey = 1,
                    PermissionLevel = new PermissionLevel { CanDelete = true, CanInsert = true, CanUpdate = true },
                    ObjectTable = ObjectTable.TASK,
                    PermissionType = PermissionType.Denied
                };
                var permissionsGroup = new List<Permissions> { permissions };
                var searchOptions = new RolesSearchOptions
                {
                    IsExternal = false,
                    PermissionsGroup = new PermissionsGroup { Permissions = permissionsGroup }
                };
                var f = new RolesSearchServiceFixture(Db);

                var result = f.Subject.DoSearch(searchOptions, cultureResolver.ToString());
                var roles = result.ToArray();
                Assert.Equal(roles.Length, 2);
                Assert.Equal(roles[0].RoleName, "r1");
                Assert.Equal(roles[1].RoleName, "r2");
            }

            [Fact]
            public void ShouldReturnRolesMatchingWithSubject()
            {
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());

                new Role(1) { RoleName = "r1", Description = "Desc", IsExternal = false }.In(Db);
                new Role(2) { RoleName = "r2", Description = "Desc2", IsExternal = false }.In(Db);
                new DataTopic { Name = "Attachments", Description = "Physical files that are attached by references to cases and names", Id = 1 }.In(Db);
                new DataTopic { Name = "Renewals", Description = "Information regarding renewals for external users", Id = 2 }.In(Db);
                new DataTopic { Name = "Prepayments", Description = "Information regarding money paid by a debtor in advance of the work being performed", Id = 3 }.In(Db);
                new PermissionsRuleItem { SelectPermission = 1, LevelKey = 1 }.In(Db);
                new PermissionsRuleItem { SelectPermission = 1, LevelKey = 2 }.In(Db);
                new PermissionsRuleItem { SelectPermission = 2, LevelKey = 3 }.In(Db);

                var permission = new Permissions
                {
                    ObjectIntegerKey = 1,
                    PermissionLevel = new PermissionLevel { CanSelect = true },
                    ObjectTable = ObjectTable.DATATOPIC,
                    PermissionType = PermissionType.Granted
                };

                var permissionsGroup = new List<Permissions> { permission };
                var searchOptions = new RolesSearchOptions
                {
                    IsExternal = false,
                    PermissionsGroup = new PermissionsGroup { Permissions = permissionsGroup }
                };
                var f = new RolesSearchServiceFixture(Db);

                var result = f.Subject.DoSearch(searchOptions, cultureResolver.ToString());
                var roles = result.ToArray();
                Assert.Equal(roles.Length, 2);
                Assert.Equal(roles[0].RoleName, "r1");
                Assert.Equal(roles[1].RoleName, "r2");
            }

            [Fact]
            public void ShouldReturnNotAssignedPermissionRolesMatchingWithTask()
            {
                var cultureResolver = _preferredCultureResolver.Resolve().Returns(Fixture.String());

                new Role(5) { RoleName = "r1", Description = "Desc", IsExternal = false }.In(Db);

                new SecurityTask { Name = "Task1", Description = "Description of task1", Id = 14 }.In(Db);

                new PermissionsRuleItem { DeletePermission = 1, InsertPermission = 1, LevelKey = -1, UpdatePermission = 1, ObjectIntegerKey = 14 }.In(Db);
                new PermissionsRuleItem { DeletePermission = 1, InsertPermission = 1, LevelKey = 4, UpdatePermission = 1, ObjectIntegerKey = 14 }.In(Db);
                new PermissionsRuleItem { DeletePermission = 0, InsertPermission = 0, LevelKey = 5, UpdatePermission = 0, ObjectIntegerKey = 14 }.In(Db);

                new Permission { ObjectTable = "TASK", LevelKey = null, ObjectIntegerKey = 14, LevelTable = null, GrantPermission = 26 }.In(Db);
                new Permission { ObjectTable = "TASK", LevelKey = -1, ObjectIntegerKey = 14, LevelTable = "ROLE", GrantPermission = 26 }.In(Db);
                new Permission { ObjectTable = "TASK", LevelKey = 4, ObjectIntegerKey = 14, LevelTable = "ROLE", GrantPermission = 26 }.In(Db);
                new Permission { ObjectTable = "TASK", LevelKey = 5, ObjectIntegerKey = 14, LevelTable = "ROLE", GrantPermission = 0 }.In(Db);

                var permissions = new Permissions
                {
                    ObjectIntegerKey = 14,
                    PermissionLevel = new PermissionLevel { CanDelete = true, CanInsert = true, CanUpdate = true },
                    ObjectTable = ObjectTable.TASK,
                    PermissionType = PermissionType.NotAssigned
                };
                var permissionsGroup = new List<Permissions> { permissions };
                var searchOptions = new RolesSearchOptions
                {
                    IsExternal = false,
                    PermissionsGroup = new PermissionsGroup { Permissions = permissionsGroup }
                };
                var f = new RolesSearchServiceFixture(Db);

                var result = f.Subject.DoSearch(searchOptions, cultureResolver.ToString());
                var roles = result.ToArray();
                Assert.Equal(roles.Length, 1);
                Assert.Equal(roles[0].RoleName, "r1");
            }
        }
    }

    public class RolesSearchServiceFixture : IFixture<IRoleSearchService>
    {
        public RolesSearchServiceFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            Subject = new RoleSearchService(db, SecurityContext, Fixture.TodayUtc);
            SecurityContext.User.Returns(new User(Fixture.String(), false));
        }

        public ISecurityContext SecurityContext { get; set; }
        public IRoleSearchService Subject { get; }
    }
}