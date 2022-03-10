using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Case;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case
{
    public class CaseSearchResultViewControllerFacts : FactBase
    {
        [Fact]
        public async Task GetViewData()
        {
            var id = Fixture.Integer();
            var query = new Query { Id = id, Name = Fixture.String("Query"), ContextId = (int)QueryContext.CaseSearch }.In(Db);

            var f = new CaseSearchResultViewControllerFixture(Db);

            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.GlobalNameChange).Returns(true);
            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.RecordWip, Arg.Any<ApplicationTaskAccessLevel>()).Returns(true);
            f.TaskSecurityProvider.HasAccessTo(ApplicationTask.ShowLinkstoWeb).Returns(true);

            f.ListCasePrograms.GetCasePrograms().Returns(new List<ProfileProgramModel>()
            {
                new ProfileProgramModel("Casentry", "Case", true),
                new ProfileProgramModel("Casenquiry", "Case Enquiry", true)
            });

            var results = await f.Subject.Get(id, QueryContext.CaseSearch);
            Assert.NotNull(results);
            Assert.Equal(query.Name, results.QueryName);
            Assert.False(results.HasOffices);
            Assert.False(results.HasFileLocation);
            Assert.False(results.isExternal);
            Assert.Equal(2, ((IEnumerable<ProfileProgramModel>)results.Programs).ToArray().Length);
            Assert.Equal(true, results.Permissions.CanMaintainGlobalNameChange);
            Assert.Equal(false, results.Permissions.CanMaintainFileTracking);
            Assert.Equal(true, results.Permissions.CanOpenWipRecord);
            Assert.Equal(true, results.Permissions.CanShowLinkforInprotechWeb);
        }

        [Fact]
        public async Task ShouldNotReturnQueryNameIfIncorrectQueryContextIsPassed()
        {
            var id = Fixture.Integer();
            new Query { Id = id, Name = Fixture.String("Query"), ContextId = (int)QueryContext.CaseSearchExternal }.In(Db);

            var f = new CaseSearchResultViewControllerFixture(Db);
            f.ListCasePrograms.GetCasePrograms().Returns(new List<ProfileProgramModel>()
            {
                new ProfileProgramModel("Casentry", "Case", true)
            });

            var results = await f.Subject.Get(id, QueryContext.CaseSearch);
            Assert.NotNull(results);
            Assert.Null(results.QueryName);
        }
    }

    public class CaseSearchResultViewControllerFixture : IFixture<CaseSearchResultViewController>
    {
        public CaseSearchResultViewControllerFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            User = new UserBuilder(db) { Profile = new ProfileBuilder().Build().In(db) }.Build().In(db);
            SecurityContext.User.Returns(User);
            ListCasePrograms = Substitute.For<IListPrograms>();
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
            Subject = new CaseSearchResultViewController(db, SecurityContext, ListCasePrograms, TaskSecurityProvider,  SiteControlReader);
        }

        public User User { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public IListPrograms ListCasePrograms { get; set; }
        public CaseSearchResultViewController Subject { get; }

        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        
        public ISiteControlReader SiteControlReader { get; set; }
    }
}
