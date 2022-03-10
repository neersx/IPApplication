using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Search.Roles;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Roles
{
    public class RolesMaintenanceControllerFacts
    {
        public class RolesSearch : FactBase
        {
            [Fact]
            public void ShouldReturnAllResult()
            {
                var f = new RolesMaintenanceControllerFixture(Db);

                var result = f.Subject.Search(null, new CommonQueryParameters());

                Assert.NotNull(result);
            }

            [Fact]
            public void ShouldReturnMatchingRoles()
            {
                new Role { RoleName = "internal", Description = "All internal", IsExternal = false }.In(Db);

                var searchOptions = new RolesSearchOptions
                {
                    RoleName = "internal",
                    Description = "all",
                    IsExternal = false,
                    PermissionsGroup = new PermissionsGroup()
                };
                var f = new RolesMaintenanceControllerFixture(Db);

                var result = f.Subject.Search(searchOptions);
                var roles = ((IEnumerable<dynamic>)result.Roles).ToArray();
                Assert.NotNull(result);
                Assert.Equal(0, result.Ids.Count());
                Assert.Empty(roles);
            }

            [Fact]
            public void ReturnsRolesSortedByRoleDescription()
            {
                var f = new RolesMaintenanceControllerFixture(Db);
                var r1 = new Role { RoleName = "internal", Description = "all internal", IsExternal = false };
                var r2 = new Role { RoleName = "admin", Description = "admin", IsExternal = false };
                var r3 = new Role { RoleName = "abc", Description = "desc", IsExternal = false };
                var r4 = new Role { RoleName = "external", Description = "all external", IsExternal = true };
                var queryParams = new CommonQueryParameters { SortBy = "Description", SortDir = "desc" };
                var searchOptions = new RolesSearchOptions
                {
                    IsExternal = false,
                    PermissionsGroup = new PermissionsGroup()
                };
                var roles = new List<Role> { r1, r2, r3, r4 };
                f.RoleSearchService.DoSearch(searchOptions, Fixture.String()).ReturnsForAnyArgs(roles.AsDbAsyncEnumerble());
                var result = f.Subject.Search(searchOptions, queryParams);

                Assert.Equal(4, result.Ids.Count());
                Assert.Equal(result.Roles.First().Description, "desc");
                Assert.Equal(result.Roles.Last().Description, "admin");
            }
        }

        public class DeleteRoles : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionWhenAlertNotFound()
            {
                var f = new RolesMaintenanceControllerFixture(Db);

                var exception = await Record.ExceptionAsync(async () => await f.Subject.Delete(null));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException)exception).Response.StatusCode);
            }

            [Fact]
            public async Task ShouldDeleteRole()
            {
                var fixture = new RolesMaintenanceControllerFixture(Db);
                var response = new RolesDeleteResponseModel
                {
                    InUseIds = new List<int> { 1 },
                    Message = "role deleted successfully"
                };

                fixture.RoleMaintenanceService.Delete(Arg.Any<RolesDeleteRequestModel>()).ReturnsForAnyArgs(response);

                var result = await fixture.Subject.Delete(new RolesDeleteRequestModel());
                Assert.Equal(false, result.HasError);
                Assert.Equal(1, result.InUseIds[0]);
                Assert.Equal("role deleted successfully", result.Message);
            }
        }

        public class MaintainRoleDetails : FactBase
        {
            [Fact]
            public async Task ThrowNullExceptionWhenRoleSaveDetailsIsNull()
            {
                var f = new RolesMaintenanceControllerFixture(Db);

                await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.MaintainRoleDetails(new RoleSaveDetails()));
            }

            [Fact]
            public async Task ThrowNullExceptionForInvalidRole()
            {
                var f = new RolesMaintenanceControllerFixture(Db);
                var overviewDetails = new OverviewDetails
                {
                    IsExternal = false,
                    Description = Fixture.String(),
                    RoleName = Fixture.String(),
                    RoleId = -1
                };

                await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.MaintainRoleDetails(new RoleSaveDetails { OverviewDetails = overviewDetails }));
            }

            [Fact]
            public async Task ShouldMaintainRoleDetails()
            {
                var fixture = new RolesMaintenanceControllerFixture(Db);
                var r = new Role(-1) { RoleName = Fixture.String(), Description = Fixture.String(), IsExternal = Fixture.Boolean() }.In(Db);
                var overviewDetails = new OverviewDetails
                {
                    Description = r.Description,
                    RoleName = r.RoleName,
                    RoleId = -1
                };
                fixture.RoleMaintenanceService.MaintainRoleDetails(Arg.Any<RoleSaveDetails>()).ReturnsForAnyArgs("success");

                var result = await fixture.Subject.MaintainRoleDetails(new RoleSaveDetails { OverviewDetails = overviewDetails });
                Assert.Equal("success", result);
            }
        }

        public class CreateRole : FactBase
        {
            [Fact]
            public async Task ShouldCreateRole()
            {
                var fixture = new RolesMaintenanceControllerFixture(Db);
                var status = new
                {
                    Result = "success",
                    RoleId = 1
                };
                fixture.RoleMaintenanceService.CreateRole(Arg.Any<OverviewDetails>()).ReturnsForAnyArgs(status);
                var result = await fixture.Subject.CreateRole(new OverviewDetails()
                {
                    RoleName = Fixture.String(),
                    Description = Fixture.String(),
                    IsExternal = Fixture.Boolean()
                });
                Assert.Equal(status, result);
            }
        }

        public class DuplicateRole : FactBase
        {
            [Fact]
            public async Task ShouldDuplicateRole()
            {
                var fixture = new RolesMaintenanceControllerFixture(Db);
                var roleId = 1;
                var status = new
                {
                    Result = "success",
                    RoleId = roleId
                };
                fixture.RoleMaintenanceService.DuplicateRole(Arg.Any<OverviewDetails>(),roleId).ReturnsForAnyArgs(status);
                var result = await fixture.Subject.CreateDuplicateRole(new OverviewDetails(){RoleName = Fixture.String()},roleId);
                Assert.Equal(status, result);
            }
        }
    }

    public class RolesMaintenanceControllerFixture : IFixture<RolesMaintenanceController>
    {
        public RolesMaintenanceControllerFixture(InMemoryDbContext db)
        {
            var cultureResolver = Substitute.For<IPreferredCultureResolver>();
            RoleSearchService = Substitute.For<IRoleSearchService>();
            RoleDetailService = Substitute.For<IRoleDetailsService>();
            RoleMaintenanceService = Substitute.For<IRoleMaintenanceService>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            DbContext = db ?? Substitute.For<InMemoryDbContext>();
            Subject = new RolesMaintenanceController(RoleSearchService, cultureResolver, RoleDetailService, DbContext, TaskSecurityProvider, RoleMaintenanceService);
            DefaultQueryParameter = new CommonQueryParameters
            {
                SortBy = "RoleName"
            };
        }

        public CommonQueryParameters DefaultQueryParameter { get; set; }
        public IRoleSearchService RoleSearchService { get; }
        public IRoleDetailsService RoleDetailService { get; }
        public IRoleMaintenanceService RoleMaintenanceService { get; set; }
        public InMemoryDbContext DbContext { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; }
        public RolesMaintenanceController Subject { get; }
    }
}