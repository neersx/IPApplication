using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Search.PriorArt;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.PriorArt
{
    public class PriorArtSearchResultViewControllerFacts : FactBase
    {
        [Fact]
        public async Task GetViewData()
        {
            var id = Fixture.Integer();
            var query = new Query { Id = id, Name = Fixture.String("Query") }.In(Db);

            var f = new PriorArtSearchResultViewControllerFixture(Db);

            var results = await f.Subject.Get(id, QueryContext.PriorArtSearch);
            Assert.NotNull(results);
            Assert.Equal(query.Name, results.QueryName);
            Assert.False(results.isExternal);
        }
    }

    public class PriorArtSearchResultViewControllerFixture : IFixture<PriorArtSearchResultViewController>
    {
        public PriorArtSearchResultViewControllerFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            User = new UserBuilder(db) { Profile = new ProfileBuilder().Build().In(db) }.Build().In(db);
            SecurityContext.User.Returns(User);
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            Subject = new PriorArtSearchResultViewController(db, SecurityContext, TaskSecurityProvider, SiteControlReader);
        }

        public User User { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public PriorArtSearchResultViewController Subject { get; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }

        public ISiteControlReader SiteControlReader { get; set; }
    }
}