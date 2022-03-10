using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.GoogleAnalytics;
using Inprotech.Integration.GoogleAnalytics.EventProviders;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Security;
using Xunit;

namespace Inprotech.Tests.Integration.GoogleAnalytics.EventProviders
{
    public class UsersProviderFacts : FactBase
    {
        [Fact]
        public async Task OnlySendsUserSinceLastChecked()
        {
            var f = Subject();
            NewUserIdentityAccessLog(AuthenticationModeKeys.Forms);
            var r = (await f.Provide(Fixture.FutureDate())).ToArray();
            Assert.Equal(4, r.Length);
            Assert.Equal(0, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.UsersActive).Value));
            Assert.Equal(0, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.UsersClientServer).Value));
            Assert.Equal(0, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.UsersExternal).Value));
            Assert.Equal(0, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.UsersWeb).Value));
        }

        [Fact]
        public async Task SendsDifferentTypesOfUserSinceLastChecked()
        {
            var f = Subject();
            NewUserIdentityAccessLog(AuthenticationModeKeys.Forms);
            NewUserIdentityAccessLog(AuthenticationModeKeys.Windows);
            NewUserIdentityAccessLog(AuthenticationModeKeys.Sso);
            NewUserIdentityAccessLog("Centura");
            var r = (await f.Provide(Fixture.PastDate())).ToArray();
            Assert.Equal(4, r.Length);
            Assert.Equal(4, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.UsersActive).Value));
            Assert.Equal(1, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.UsersClientServer).Value));
            Assert.Equal(0, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.UsersExternal).Value));
            Assert.Equal(3, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.UsersWeb).Value));
        }

        [Fact]
        public async Task SendsExternalUsers()
        {
            var f = Subject();
            var externalId = new User("external", true).In(Db).Id;
            NewUserIdentityAccessLog(AuthenticationModeKeys.Forms, externalId);
            NewUserIdentityAccessLog(AuthenticationModeKeys.Windows);
            NewUserIdentityAccessLog(AuthenticationModeKeys.Sso);

            var r = (await f.Provide(Fixture.PastDate())).ToArray();
            Assert.Equal(4, r.Length);
            Assert.Equal(3, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.UsersActive).Value));
            Assert.Equal(0, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.UsersClientServer).Value));
            Assert.Equal(1, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.UsersExternal).Value));
            Assert.Equal(3, ToInt(r.Single(_ => _.Name == AnalyticsEventCategories.UsersWeb).Value));
        }

        UsersProvider Subject() => new UsersProvider(Db);

        void NewUserIdentityAccessLog(string provider, int? identityId = null)
        {
            new UserIdentityAccessLog(identityId ?? Fixture.Integer(), provider, Fixture.String(), Fixture.Today())
            {
                LastChanged = Fixture.Today()
            }.In(Db);
        }

        int ToInt(string text) => Convert.ToInt32(text);
    }
}
