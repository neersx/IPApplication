using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model.Components.Profiles;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Profiles
{
    public class HomePageResolverFacts : FactBase
    {
        [Fact]
        public void ReturnsNullIfNoHomePageSet()
        {
            var f = new HomePageResolverFixture(Db);
            var result = f.Subject.Resolve();
            Assert.Null(result);
        }

        [Fact]
        public void ReturnsCorrectHomePageSetting()
        {
            var f = new HomePageResolverFixture(Db);
            var testProp = new {Key = 123, Data = Fixture.String()};
            var settingValue = JsonConvert.SerializeObject(testProp);
            var settingId = Fixture.Integer();
            var settingName = Fixture.String();
            var settingDefinition = new SettingDefinition { SettingId = settingId, Name = settingName, Description = settingName + "_Description" }.In(Db);
            new SettingValues { CharacterValue = settingValue, SettingId = settingId, Definition = settingDefinition, User = new UserBuilder(Db).Build() }.In(Db);
            new SettingValues { CharacterValue = settingValue, SettingId = KnownSettingIds.AppsHomePage, Definition = settingDefinition, User = new UserBuilder(Db).Build() }.In(Db);
            new SettingValues { CharacterValue = settingValue, SettingId = KnownSettingIds.AppsHomePage, Definition = settingDefinition, User = f.Staff }.In(Db);
            var result = f.Subject.Resolve();
            Assert.Equal(JsonConvert.SerializeObject(testProp), JsonConvert.SerializeObject(result));
        }
    }

    public class HomePageResolverFixture : IFixture<IHomeStateResolver>
    {
        public HomePageResolverFixture(InMemoryDbContext db)
        {
            Staff = new UserBuilder(db).Build().In(db);
            WebSecurityContext = Substitute.For<ISecurityContext>();
            WebSecurityContext.User.Returns(Staff);
            Subject = new HomePageResolver(db, WebSecurityContext);
        }

        public User Staff { get; set; }

        public ISecurityContext WebSecurityContext { get; set; }
        public IHomeStateResolver Subject { get; }
    }
}
