using System.Linq;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders
{
    public class UserFormatterFacts
    {
        public class UserFormaterFixture : IFixture<UserFormatter>
        {
            public UserFormaterFixture(InMemoryDbContext db)
            {
                Subject = new UserFormatter(db, Fixture.Today);
            }

            public UserFormatter Subject { get; set; }
        }

        public class ExchangeUserMethod : FactBase
        {
            [Fact]
            public void GetExchangeUser()
            {
                decimal defaultAlertSetting = 54;
                var user = new User(Fixture.String(), false);

                var s1 = new SettingValues
                {
                    User = user,
                    SettingId = KnownSettingIds.PreferredCulture,
                    CharacterValue = Fixture.String()
                };
                var s2 = new SettingValues
                {
                    User = user,
                    SettingId = KnownSettingIds.IsExchangeInitialised,
                    BooleanValue = Fixture.Boolean()
                };
                var s3 = new SettingValues
                {
                    User = user,
                    SettingId = KnownSettingIds.AreExchangeAlertsRequired,
                    BooleanValue = Fixture.Boolean()
                };
                var s4 = new SettingValues
                {
                    User = user,
                    SettingId = KnownSettingIds.ExchangeMailbox,
                    CharacterValue = Fixture.String()
                };
                var settings = new[] {s1, s2, s3, s4}.AsQueryable();

                var f = new UserFormaterFixture(Db);
                var s = f.Subject.ExchangeUser(user.Id, settings, defaultAlertSetting);

                Assert.Equal(s1.CharacterValue, s.Culture);
                Assert.Equal(s2.BooleanValue, s.IsUserInitialised);
                Assert.Equal(s3.BooleanValue, s.IsAlertRequired);
                Assert.Equal(s4.CharacterValue, s.Mailbox);
            }
        }

        public class UsersMethod : FactBase
        {
            [Fact]
            public void GetUsers()
            {
                UserBuilder.AsInternalUser(Db).Build().In(Db);
                UserBuilder.AsExternalUser(Db, null).Build().In(Db);

                var n1 = new NameBuilder(Db).Build().In(Db);
                var user1 = UserBuilder.AsInternalUser(Db).Build().In(Db);
                user1.Name = n1;

                new SettingValues {DecimalValue = (decimal?) 20.1, SettingId = KnownSettingIds.ExchangeAlertTime, User = user1}.In(Db);

                var f = new UserFormaterFixture(Db);

                new PermissionsGrantedAllItem
                {
                    IdentityKey = user1.Id,
                    CanExecute = true
                }.In(Db);

                var s = f.Subject.Users(user1.Name.Id);

                Assert.Contains(s, v => v.UserIdentityId == user1.Id);
            }
        }
    }
}