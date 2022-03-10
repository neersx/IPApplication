using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Search.TaskPlanner;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using InprotechKaizen.Model.TaskPlanner;
using NSubstitute;
using Xunit;
using Query = InprotechKaizen.Model.Queries.Query;

namespace Inprotech.Tests.Web.Search.TaskPlanner
{
    public class TaskPlannerTabResolverFacts : FactBase
    {
        static dynamic SetupTaskPlannerTabData(InMemoryDbContext db)
        {
            var user = new User("internal", false)
            {
                Name = new InprotechKaizen.Model.Names.Name(Fixture.Integer())
                {
                    NameCode = Fixture.UniqueName()
                }
            };

            var q1 = new Query
            {
                ContextId = (int)QueryContext.TaskPlanner,
                Id = Fixture.Integer()
            }.In(db);
            var q2 = new Query
            {
                ContextId = (int)QueryContext.TaskPlanner,
                Id = Fixture.Integer()
            }.In(db);
            var q3 = new Query
            {
                ContextId = (int)QueryContext.TaskPlanner,
                Id = Fixture.Integer()
            }.In(db);
            var q4 = new Query
            {
                ContextId = (int)QueryContext.TaskPlanner,
                Id = Fixture.Integer()
            }.In(db);
            var q5 = new Query
            {
                ContextId = (int)QueryContext.TaskPlanner,
                Id = Fixture.Integer()
            }.In(db);

            var tab1 = new TaskPlannerTab
            {
                TabSequence = 1,
                IdentityId = user.Id,
                QueryId = q1.Id
            }.In(db);
            new TaskPlannerTab
            {
                TabSequence = 2,
                IdentityId = user.Id,
                QueryId = q2.Id
            }.In(db);
            var profileTab1 = new TaskPlannerTabsByProfile
            {
                TabSequence = 1,
                QueryId = q3.Id
            }.In(db);
            var profileTab2 = new TaskPlannerTabsByProfile
            {
                TabSequence = 2,
                QueryId = q4.Id,
                IsLocked = true
            }.In(db);
            var profileTab3 = new TaskPlannerTabsByProfile
            {
                TabSequence = 3,
                QueryId = q5.Id,
                IsLocked = false
            }.In(db);

            return new { user, tab1, profileTab1, profileTab2, profileTab3 };
        }

        [Fact]
        public async Task VerifyResolveUserConfiguration()
        {
            var fixture = new TaskPlannerTabResolverFixture(Db);
            var data = SetupTaskPlannerTabData(Db);
            fixture.SecurityContext.User.Returns(data.user as User);
            var result = await fixture.Subject.ResolveUserConfiguration();
            Assert.Equal(data.tab1.QueryId, result[0].SavedSearch.Key);
            Assert.Equal(data.profileTab2.QueryId, result[1].SavedSearch.Key);
            Assert.Equal(data.profileTab3.QueryId, result[2].SavedSearch.Key);
        }

        [Fact]
        public async Task VerifyResolveProfileConfiguration()
        {
            var fixture = new TaskPlannerTabResolverFixture(Db);
            var data = SetupTaskPlannerTabData(Db);
            fixture.SecurityContext.User.Returns(data.user as User);
            var result = await fixture.Subject.ResolveProfileConfiguration();
            Assert.Equal(data.profileTab1.QueryId, result[0].SavedSearch.Key);
            Assert.Equal(data.profileTab2.QueryId, result[1].SavedSearch.Key);
            Assert.Equal(data.profileTab3.QueryId, result[2].SavedSearch.Key);
        }

        [Fact]
        public async Task VerifyInvalidateUserConfiguration()
        {
            var fixture = new TaskPlannerTabResolverFixture(Db);
            var data = SetupTaskPlannerTabData(Db);
            fixture.SecurityContext.User.Returns(data.user as User);
            await fixture.Subject.ResolveUserConfiguration();
            var result = await fixture.Subject.InvalidateUserConfiguration();
            Assert.True(result);
        }
        
        [Fact]
        public async Task VerifyInvalidateProfileConfiguration()
        {
            var fixture = new TaskPlannerTabResolverFixture(Db);
            var result = await fixture.Subject.Clear();
            Assert.True(result);
        }
    }

    public class TaskPlannerTabResolverFixture : IFixture<TaskPlannerTabResolver>
    {
        public TaskPlannerTabResolverFixture(InMemoryDbContext db = null)
        {
            DbContext = db ?? Substitute.For<InMemoryDbContext>();
            SecurityContext = Substitute.For<ISecurityContext>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            Subject = new TaskPlannerTabResolver(PreferredCultureResolver, SecurityContext, DbContext);
        }

        public ISecurityContext SecurityContext { get; set; }
        public IDbContext DbContext { get; set; }
        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public TaskPlannerTabResolver Subject { get; }
    }
}