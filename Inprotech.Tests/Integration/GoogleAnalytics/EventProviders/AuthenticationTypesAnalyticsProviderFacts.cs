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
    public class AuthenticationTypesAnalyticsProviderFacts : FactBase
    {
        [Fact]
        public async Task OnlySendsUserSinceLastChecked()
        {
            var f = Subject();
            NewUserIdentityAccessLog(AuthenticationModeKeys.Forms);
            var r = (await f.Provide(Fixture.FutureDate())).ToArray();
            Assert.Empty(r);
        }

        [Fact]
        public async Task ReturnsUsersByEachAuthMode()
        {
            var f = Subject();
            NewUserIdentityAccessLog(AuthenticationModeKeys.Forms);
            NewUserIdentityAccessLog(AuthenticationModeKeys.Forms);
            NewUserIdentityAccessLog(AuthenticationModeKeys.Windows);
            NewUserIdentityAccessLog(AuthenticationModeKeys.Sso);
            NewUserIdentityAccessLog("Centura");

            var r = (await f.Provide(Fixture.PastDate())).ToArray();
            Assert.Equal(4, r.Length);
            Assert.Equal(2, ToInt(r.Single(_ => _.Name == WithSuffix(AuthenticationModeKeys.Forms)).Value));
            Assert.Equal(1, ToInt(r.Single(_ => _.Name == WithSuffix(AuthenticationModeKeys.Windows)).Value));
            Assert.Equal(1, ToInt(r.Single(_ => _.Name == WithSuffix(AuthenticationModeKeys.Sso)).Value));
            Assert.Equal(1, ToInt(r.Single(_ => _.Name == WithSuffix("Centura")).Value));
        }

        AuthenticationTypesAnalyticsProvider Subject() => new AuthenticationTypesAnalyticsProvider(Db);
        string WithSuffix(string text) => AnalyticsEventCategories.AuthenticationTypesPrefix + text;
        int ToInt(string text) => Convert.ToInt32(text);

        void NewUserIdentityAccessLog(string provider, int? identityId = null)
        {
            new UserIdentityAccessLog(identityId ?? Fixture.Integer(), provider, Fixture.String(), Fixture.Today())
            {
                LastChanged = Fixture.Today()
            }.In(Db);
        }
    }
}