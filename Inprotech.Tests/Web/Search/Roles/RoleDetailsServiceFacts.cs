using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Search.Roles;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Roles
{
    public class RoleDetailsServiceFacts
    {
        public class GetTaskDetailsMethod : FactBase
        {
            [Fact]
            public async Task ShouldThrowExceptionIfRoleNotFound()
            {
                var f = new RoleDetailsServiceFixture(Db);
                var queryParameter = new CommonQueryParameters
                {
                    Filters = new List<CommonQueryParameters.FilterValue>()
                };
                var result = await f.Subject.GetTaskDetails(Fixture.Integer(), new TaskSearchCriteria(), queryParameter.Filters);

                Assert.Equal(Enumerable.Empty<TaskDetails>(), result);
            }

            [Fact]
            public async Task ReturnsTheTask()
            {
                var role = new Role().In(Db);
                var release = new ReleaseVersion { VersionName = Fixture.String() }.In(Db);
                var feature = new FeatureBuilder().Build().In(Db);
                var task = new SecurityTaskBuilder().Build().In(Db);
                task.VersionId = release.Id;

                task.ProvidedByFeatures.Add(feature);
                feature.SecurityTasks.Add(task);
                var queryParameter = new CommonQueryParameters
                {
                    Filters = new List<CommonQueryParameters.FilterValue>()
                };

                new ValidObjectItems { ObjectIntegerKey = task.Id.ToString(), InternalUse = true, ExternalUse = false }.In(Db);
                new PermissionsRuleItem { ObjectIntegerKey = task.Id, DeletePermission = 0, ExecutePermission = 1, InsertPermission = 0, UpdatePermission = 1 }.In(Db);

                var f = new RoleDetailsServiceFixture(Db);

                var result = await f.Subject.GetTaskDetails(role.Id, new TaskSearchCriteria(), queryParameter.Filters);

                var taskDetails = result as TaskDetails[] ?? result.ToArray();
                Assert.Equal(1, taskDetails.Length);

                var taskResult = taskDetails.First();

                Assert.Equal(taskResult.RoleKey, role.Id);
                Assert.Equal(taskResult.TaskKey, task.Id);
                Assert.Equal(taskResult.TaskName, task.Name);
                Assert.True(taskResult.DeletePermission == 0);
                Assert.True(taskResult.ExecutePermission == 1);
                Assert.True(taskResult.InsertPermission == 0);
                Assert.True(taskResult.UpdatePermission == 1);
                Assert.Equal(taskResult.SubFeature.First(), feature.Name);
                Assert.Equal(taskResult.Release, release.VersionName);
            }

            [Fact]
            public async Task ShouldNotReturnsAnyTaskForExternalRole()
            {
                var role = new Role { IsExternal = true }.In(Db);
                var release = new ReleaseVersion { VersionName = Fixture.String() }.In(Db);
                var feature = new FeatureBuilder { IsExternal = false, IsInternal = true }.Build()
                                                                                          .In(Db);
                var queryParameter = new CommonQueryParameters
                {
                    Filters = new List<CommonQueryParameters.FilterValue>()
                };
                var task = new SecurityTaskBuilder().Build().In(Db);
                task.VersionId = release.Id;

                task.ProvidedByFeatures.Add(feature);
                feature.SecurityTasks.Add(task);

                new ValidObjectItems { ObjectIntegerKey = task.Id.ToString(), InternalUse = true, ExternalUse = false }.In(Db);

                var f = new RoleDetailsServiceFixture(Db);

                var result = await f.Subject.GetTaskDetails(role.Id, new TaskSearchCriteria(), queryParameter.Filters);

                Assert.Equal(0, result.Count());
            }
        }

        public class GetModuleDetailsMethod : FactBase
        {
            [Fact]
            public async Task ShouldThrowExceptionIfRoleNotFound()
            {
                var f = new RoleDetailsServiceFixture(Db);
                var queryParameter = new CommonQueryParameters
                {
                    Filters = new List<CommonQueryParameters.FilterValue>()
                };
                var result = await f.Subject.GetModuleDetails(Fixture.Integer(), queryParameter.Filters);

                Assert.Equal(Enumerable.Empty<WebPartDetails>(), result);
            }

            [Fact]
            public async Task ShouldReturnModuleDetails()
            {
                var role = new Role { RoleName = Fixture.String(), IsExternal = false }.In(Db);
                var featureId = Fixture.Short();
                var moduleId = Fixture.Short();
                var feature = new FeatureBuilder { Id = featureId, IsInternal = true, IsExternal = false }.Build().In(Db);

                var module = new WebPartModuleBuilder { ModuleId = moduleId }.Build().In(Db);
                new ValidObjectItems { ObjectIntegerKey = moduleId.ToString(), InternalUse = true, ExternalUse = true }.In(Db);
                new PermissionsRuleItem { ObjectIntegerKey = moduleId, SelectPermission = 1, MandatoryPermission = 0, LevelKey = 5 }.In(Db);
                module.ProvidedByFeatures.Add(feature);
                feature.WebpartModules.Add(module);

                var f = new RoleDetailsServiceFixture(Db);
                var queryParameter = new CommonQueryParameters
                {
                    Filters = new List<CommonQueryParameters.FilterValue>()
                };
                var result = await f.Subject.GetModuleDetails(role.Id, queryParameter.Filters);

                var moduleDetails = result as WebPartDetails[] ?? result.ToArray();
                Assert.Equal(1, moduleDetails.Length);

                var moduleResult = moduleDetails.First();

                Assert.Equal(moduleResult.RoleKey, role.Id);
                Assert.Equal(moduleResult.ModuleKey, moduleId);
                Assert.Equal(moduleResult.ModuleTitle, module.Title);
                Assert.Equal(moduleResult.Description, module.Description);
                Assert.True(moduleResult.SelectPermission == 1);
                Assert.True(moduleResult.MandatoryPermission == 0);
            }

            [Fact]
            public async Task ShouldNotReturnTheModule()
            {
                var role = new Role { RoleName = Fixture.String(), IsExternal = true }.In(Db);
                var featureId = Fixture.Short();
                var moduleId = Fixture.Short();
                new FeatureBuilder { Id = featureId, IsInternal = true, IsExternal = false }.Build().In(Db);

                new WebpartModule { Id = moduleId, Title = Fixture.String(), Description = Fixture.String() }.In(Db);
                new ValidObjectItems { ObjectIntegerKey = moduleId.ToString(), InternalUse = true, ExternalUse = false }.In(Db);
                new PermissionsRuleItem { ObjectIntegerKey = moduleId, SelectPermission = 1, MandatoryPermission = 0, LevelKey = 5 }.In(Db);

                var f = new RoleDetailsServiceFixture(Db);
                var queryParameter = new CommonQueryParameters
                {
                    Filters = new List<CommonQueryParameters.FilterValue>()
                };
                var result = await f.Subject.GetModuleDetails(role.Id, queryParameter.Filters);
                Assert.Equal(0, result.Count());
            }
        }

        public class GetSubjectDetailsMethod : FactBase
        {
            [Fact]
            public async Task ShouldThrowExceptionIfRoleNotFound()
            {
                var f = new RoleDetailsServiceFixture(Db);
                var result = await f.Subject.GetSubjectDetails(Fixture.Integer());

                Assert.Equal(Enumerable.Empty<SubjectDetails>(), result);
            }

            [Fact]
            public async Task ReturnsTheSubject()
            {
                var role = new Role { IsExternal = false }.In(Db);

                var dataTopic = new DataTopic { Description = Fixture.String(), Name = Fixture.String() }.In(Db);

                new ValidObjectItems { ObjectIntegerKey = dataTopic.Id.ToString(), InternalUse = true, ExternalUse = false }.In(Db);
                new PermissionsRuleItem { ObjectIntegerKey = dataTopic.Id, SelectPermission = 1 }.In(Db);

                var f = new RoleDetailsServiceFixture(Db);

                var result = await f.Subject.GetSubjectDetails(role.Id);

                var subjects = result.ToArray();
                Assert.Equal(1, subjects.Count());

                var subjectResult = subjects.First();

                Assert.Equal(subjectResult.TopicKey, dataTopic.Id);
                Assert.Equal(subjectResult.TopicName, dataTopic.Name);
                Assert.Equal(subjectResult.Description, dataTopic.Description);
                Assert.True(subjectResult.SelectPermission == 1);
                Assert.Equal(subjectResult.RoleKey, role.Id);
            }

            [Fact]
            public async Task ShouldNotReturnTheSubject()
            {
                var role = new Role { IsExternal = true }.In(Db);

                var dataTopic = new DataTopic { Description = Fixture.String(), Name = Fixture.String() }.In(Db);

                new ValidObjectItems { ObjectIntegerKey = dataTopic.Id.ToString(), InternalUse = true, ExternalUse = false }.In(Db);
                new PermissionsRuleItem { ObjectIntegerKey = dataTopic.Id, SelectPermission = 1 }.In(Db);

                var f = new RoleDetailsServiceFixture(Db);

                var result = await f.Subject.GetSubjectDetails(role.Id);

                Assert.Equal(0, result.Count());
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnNullIfRoleNotFound()
            {
                var f = new RoleDetailsServiceFixture(Db);
                var result = await f.Subject.Get(Fixture.Integer());

                Assert.Equal(null, result);
            }

            [Fact]
            public async Task ReturnsTheRoleDetails()
            {
                var role = new Role
                {
                    Description = Fixture.String(),
                    RoleName = Fixture.String(),
                    IsExternal = false
                }.In(Db);

                var f = new RoleDetailsServiceFixture(Db);

                var result = await f.Subject.Get(role.Id);

                Assert.NotNull(result);
                Assert.Equal(result.Description, role.Description);
                Assert.Equal(result.RoleName, role.RoleName);
                Assert.Equal(result.IsExternal, role.IsExternal);
            }
        }
    }

    internal class RoleDetailsServiceFixture : IFixture<IRoleDetailsService>
    {
        public RoleDetailsServiceFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            DateFunc = Substitute.For<Func<DateTime>>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            DateFunc().Returns(Fixture.TodayUtc());

            Subject = new RoleDetailsService(db, DateFunc, PreferredCultureResolver);
        }

        public ISecurityContext SecurityContext { get; set; }
        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public Func<DateTime> DateFunc { get; set; }
        public IRoleDetailsService Subject { get; }
    }
}