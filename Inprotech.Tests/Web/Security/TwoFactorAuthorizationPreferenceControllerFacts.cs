using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Hosting;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Security;
using Inprotech.Web.Security.TwoFactorAuth;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class TwoFactorAuthorizationPreferenceControllerFacts : FactBase
    {
        TwoFactorAuthorizationPreferenceControllerFixture _f;

        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData("notApp")]
        [InlineData("failExample")]
        public async Task InvalidPreferenceShouldReturnInvalid(string invalidValue)
        {
            _f = new TwoFactorAuthorizationPreferenceControllerFixture();

            var r = await _f.Subject.UpdatePreference(new TwoFactorAuthorizationPreferenceController.TwoFactorPreferenceRequest
            {
                Preference = invalidValue
            });

            var d = (TwoFactorAuthorizationPreferenceController.TwoFactorPreferenceUpdateResponse)((ObjectContent)r.Content).Value;
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal(TwoFactorAuthorizationPreferenceController.TwoFactorAuthPreferenceUpdateStatus.InvalidPreference, d.Status);
        }

        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData(" ")]
        public async Task SettingToTwoFactorAppShouldFailIfAppNotConfigured(string emptyValue)
        {
            _f = new TwoFactorAuthorizationPreferenceControllerFixture();
            _f.TwoFactorPreference.ResolveAppSecretKey(Arg.Any<int>()).Returns(emptyValue);
            _f.SecurityContext.User.Returns(new User());

            var r = await _f.Subject.UpdatePreference(new TwoFactorAuthorizationPreferenceController.TwoFactorPreferenceRequest
            {
                Preference = TwoFactorAuthVerify.App
            });

            var d = (TwoFactorAuthorizationPreferenceController.TwoFactorPreferenceUpdateResponse)((ObjectContent)r.Content).Value;
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal(TwoFactorAuthorizationPreferenceController.TwoFactorAuthPreferenceUpdateStatus.NoApp, d.Status);
        }

        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData(" ")]
        public async Task SettingToTwoFactorEmailShouldNotFailIfAppNotConfigured(string emptyValue)
        {
            _f = new TwoFactorAuthorizationPreferenceControllerFixture();
            _f.TwoFactorPreference.ResolveAppSecretKey(Arg.Any<int>()).Returns(emptyValue);
            _f.SecurityContext.User.Returns(new User());

            var r = await _f.Subject.UpdatePreference(new TwoFactorAuthorizationPreferenceController.TwoFactorPreferenceRequest
            {
                Preference = TwoFactorAuthVerify.Email
            });

            var d = (TwoFactorAuthorizationPreferenceController.TwoFactorPreferenceUpdateResponse)((ObjectContent)r.Content).Value;
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.NotEqual(TwoFactorAuthorizationPreferenceController.TwoFactorAuthPreferenceUpdateStatus.NoApp, d.Status);
        }

        public class TwoFactorAuthorizationPreferenceControllerFixture : IFixture<TwoFactorAuthorizationPreferenceController>
        {
            public readonly ITwoFactorAuthVerify TwoFactorAuthVerify;
            public IAuthSettings AuthSettings { get; set; }
            public ISecurityContext SecurityContext { get; set; }
            public IUserTwoFactorAuthPreference TwoFactorPreference { get; set; }
            public TwoFactorAuthorizationPreferenceController Subject { get; }
            public TwoFactorAuthorizationPreferenceControllerFixture(bool isSecure = false)
            {
                TwoFactorAuthVerify = Substitute.For<ITwoFactorAuthVerify>();

                var request = new HttpRequestMessage(HttpMethod.Post, isSecure ? "https://localhost/cpainproma/apps/signin" : "http://localhost/cpainproma/apps/signin");
                request.Properties[HttpPropertyKeys.HttpConfigurationKey] = new HttpConfiguration();
                TwoFactorPreference = Substitute.For<IUserTwoFactorAuthPreference>();
                SecurityContext = Substitute.For<ISecurityContext>();
                AuthSettings = Substitute.For<IAuthSettings>();
                TwoFactorApp = Substitute.For<ITwoFactorApp>();
                Subject = new TwoFactorAuthorizationPreferenceController(TwoFactorPreference, SecurityContext, AuthSettings, TwoFactorApp)
                {
                    Request = request
                };
            }

            public ITwoFactorApp TwoFactorApp { get; set; }
        }
    }
}