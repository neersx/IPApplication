using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Name;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Name
{
    public class NameSearchResultViewControllerFacts : FactBase
    {
        [Fact]
        public async Task GetViewData()
        {
            var id = Fixture.Integer();
            var query = new Query {Id = id, Name = Fixture.String("Query")}.In(Db);

            var f = new NameSearchResultViewControllerFixture(Db);
            f.TaskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>()).Returns(true);
            f.TaskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>(), Arg.Any<ApplicationTaskAccessLevel>()).Returns(true);
            var results = await f.Subject.Get(id, QueryContext.NameSearch);
            Assert.NotNull(results);
            Assert.Equal(query.Name, results.QueryName);
            Assert.False(results.isExternal);
            Assert.True(results.Permissions.CanMaintainNameNotes);
            Assert.True(results.Permissions.CanMaintainNameAttributes);
            Assert.True(results.Permissions.CanMaintainName);
            Assert.True(results.Permissions.CanMaintainOpportunity);
            Assert.True(results.Permissions.CanMaintainAdHocDate);
            Assert.True(results.Permissions.CanMaintainContactActivity);
        }
    }

    public class NameSearchResultViewControllerFixture : IFixture<NameSearchResultViewController>
    {
        public NameSearchResultViewControllerFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            ListPrograms = Substitute.For<IListPrograms>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            User = new UserBuilder(db) {Profile = new ProfileBuilder().Build().In(db)}.Build().In(db);
            SecurityContext.User.Returns(User);
            SiteControlReader = Substitute.For<ISiteControlReader>();
            Subject = new NameSearchResultViewController(db, SecurityContext, ListPrograms, TaskSecurityProvider, SiteControlReader);
        }

        public User User { get; set; }
        public ISecurityContext SecurityContext { get; set; }

        public ITaskSecurityProvider TaskSecurityProvider { get; set; }

        public IListPrograms ListPrograms { get; set; }
        public NameSearchResultViewController Subject { get; }
        public ISiteControlReader SiteControlReader { get; set; }
    }
}