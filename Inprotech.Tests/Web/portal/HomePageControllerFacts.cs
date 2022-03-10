using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Portal;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.portal
{
    public class HomePageControllerFacts : FactBase
    {
        [Fact]
        public void SetsHomePagePreference()
        {
            var newPage = new {Name = Fixture.String(), Params = Fixture.String()};
            var newSetting = JsonConvert.SerializeObject(newPage);
            var f = new HomePageControllerFixture(Db);
            f.Subject.SetHomePage(JObject.FromObject(newPage));
            f.UserPreferenceManager.Received(1).SetPreference(f.SecurityContext.User.Id, KnownSettingIds.AppsHomePage, newSetting);
        }

        [Fact]
        public void ResetsHomePagePreference()
        {
            var f = new HomePageControllerFixture(Db);
            f.Subject.ResetHomePage();
            f.UserPreferenceManager.Received(1).ResetUserPreferences(f.SecurityContext.User.Id, Arg.Is<int[]>(_ => _.Contains(KnownSettingIds.AppsHomePage)));
        }
    }

    public class HomePageControllerFixture : IFixture<HomePageController>
    {
        public HomePageControllerFixture(InMemoryDbContext db)
        {
            var user = new UserBuilder(db).Build().In(db);
            SecurityContext = Substitute.For<ISecurityContext>();
            SecurityContext.User.Returns(user);
            UserPreferenceManager = Substitute.For<IUserPreferenceManager>();
            Subject = new HomePageController(SecurityContext, UserPreferenceManager);
        }

        public IUserPreferenceManager UserPreferenceManager { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public HomePageController Subject { get; }
    }
}