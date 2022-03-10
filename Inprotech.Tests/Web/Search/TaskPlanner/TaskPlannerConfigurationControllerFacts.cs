using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Common;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Tests.Web.Builders.Model.TaskPlanner;
using Inprotech.Web.Configuration.TaskPlanner;
using Inprotech.Web.Search.TaskPlanner;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.TaskPlanner
{
    public class TaskPlannerConfigurationControllerFacts : FactBase
    {
        [Fact]
        public async Task SearchMethod()
        {
            var fixture = new TaskPlannerConfigurationControllerFixture(Db);
            var data = PrepareData();
            var results = await fixture.Subject.Search();
            Assert.Equal(results.Count, 2);
            var defaultProfile = results.Single(_ => _.Profile == null);
            Assert.Equal(defaultProfile.Tab1.SearchName, data.query1.Name);
            Assert.Equal(defaultProfile.Tab2.SearchName, data.query3.Name);
            Assert.Equal(defaultProfile.Tab3.SearchName, data.query2.Name);
            Assert.True(defaultProfile.Tab1Locked);
            Assert.True(defaultProfile.Tab2Locked);
            Assert.False(defaultProfile.Tab3Locked);

            var profile = results.Single(_ => _.Profile != null);
            Assert.Equal(profile.Tab1.SearchName, data.query1.Name);
            Assert.Equal(profile.Tab2.SearchName, data.query2.Name);
            Assert.Equal(profile.Tab3.SearchName, data.query3.Name);
            Assert.False(profile.Tab1Locked);
            Assert.False(profile.Tab2Locked);
            Assert.True(profile.Tab3Locked);
        }

        [Fact]
        public async Task SaveMethod()
        {
            var fixture = new TaskPlannerConfigurationControllerFixture(Db);
            var data = PrepareData();

            var items = new List<TaskPlannerTabConfigItem>
            {
                new TaskPlannerTabConfigItem
                {
                    Tab1 = new QueryData { Key = data.query3.Id, SearchName = data.query3.Name },
                    Tab2 = new QueryData { Key = data.query2.Id, SearchName = data.query2.Name },
                    Tab3 = new QueryData { Key = data.query1.Id, SearchName = data.query1.Name },
                    Tab3Locked = true
                },
                new TaskPlannerTabConfigItem
                {
                    IsDeleted = true,
                    Profile = new ProfileData { Key = data.profile1.Id, Name = data.profile1.Name }
                },
                new TaskPlannerTabConfigItem
                {
                    Profile = new ProfileData { Key = data.profile2.Id, Name = data.profile2.Name },
                    Tab1 = new QueryData { Key = data.query1.Id, SearchName = data.query1.Name },
                    Tab2 = new QueryData { Key = data.query2.Id, SearchName = data.query2.Name },
                    Tab3 = new QueryData { Key = data.query3.Id, SearchName = data.query3.Name }
                }
            };
            var hasSaved = await fixture.Subject.Save(items);
            Assert.True(hasSaved);
            var result = await fixture.Subject.Search();

            Assert.Equal(result.Count, 2);
            var defaultProfile = result.Single(_ => _.Profile == null);
            Assert.Equal(defaultProfile.Tab1.SearchName, data.query3.Name);
            Assert.Equal(defaultProfile.Tab2.SearchName, data.query2.Name);
            Assert.Equal(defaultProfile.Tab3.SearchName, data.query1.Name);
            Assert.False(defaultProfile.Tab1Locked);
            Assert.False(defaultProfile.Tab2Locked);
            Assert.True(defaultProfile.Tab3Locked);

            var profile = result.Single(_ => _.Profile != null);
            Assert.Equal(profile.Tab1.SearchName, data.query1.Name);
            Assert.Equal(profile.Tab2.SearchName, data.query2.Name);
            Assert.Equal(profile.Tab3.SearchName, data.query3.Name);

            profile = result.SingleOrDefault(_ => _.Profile?.Key == data.profile1.Id);
            Assert.Null(profile);
        }

        dynamic PrepareData()
        {
            var profile1 = new ProfileBuilder().Build().In(Db);
            var profile2 = new ProfileBuilder().Build().In(Db);

            var query1 = new QueryBuilder { ContextId = (int)QueryContext.TaskPlanner, SearchName = "My Reminders" }.Build().In(Db);
            var query2 = new QueryBuilder { ContextId = (int)QueryContext.TaskPlanner, SearchName = "My Due Date's" }.Build().In(Db);
            var query3 = new QueryBuilder { ContextId = (int)QueryContext.TaskPlanner, SearchName = "My Team Task's" }.Build().In(Db);

            var tab1 = new TaskPlannerTabsByProfileBuilder { TabSequence = 1, QueryId = query1.Id, IsLocked = true }.Build().In(Db);
            var tab2 = new TaskPlannerTabsByProfileBuilder { TabSequence = 2, QueryId = query3.Id, IsLocked = true }.Build().In(Db);
            var tab3 = new TaskPlannerTabsByProfileBuilder { TabSequence = 3, QueryId = query2.Id }.Build().In(Db);

            new TaskPlannerTabsByProfileBuilder { TabSequence = 1, QueryId = query1.Id, ProfileId = profile1.Id }.Build().In(Db);
            new TaskPlannerTabsByProfileBuilder { TabSequence = 2, QueryId = query2.Id, ProfileId = profile1.Id }.Build().In(Db);
            new TaskPlannerTabsByProfileBuilder { TabSequence = 3, QueryId = query3.Id, ProfileId = profile1.Id, IsLocked = true }.Build().In(Db);

            return new
            {
                profile1,
                profile2,
                query1,
                query2,
                query3
            };
        }
    }

    public class TaskPlannerConfigurationControllerFixture : IFixture<TaskPlannerConfigurationController>
    {
        public TaskPlannerConfigurationControllerFixture(InMemoryDbContext db = null)
        {
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            DbContext = db ?? Substitute.For<InMemoryDbContext>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            TaskPlannerTabResolver = Substitute.For<ITaskPlannerTabResolver>();
            Subject = new TaskPlannerConfigurationController(DbContext, PreferredCultureResolver, TaskPlannerTabResolver);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }

        public IDbContext DbContext { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; }

        public ITaskPlannerTabResolver TaskPlannerTabResolver { get; }
        public TaskPlannerConfigurationController Subject { get; }
    }
}