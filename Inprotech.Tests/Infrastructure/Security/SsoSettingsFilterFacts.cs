using System.Collections.ObjectModel;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using Inprotech.Infrastructure.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Security
{
    public class SsoSettingsFilterFacts
    {
        readonly IAuthSettings _settings = Substitute.For<IAuthSettings>();
        readonly Collection<RequiresAuthenticationSettingsAttribute> _empty = new Collection<RequiresAuthenticationSettingsAttribute>();
        readonly Collection<RequiresAuthenticationSettingsAttribute> _attribute = new Collection<RequiresAuthenticationSettingsAttribute> {new RequiresAuthenticationSettingsAttribute(AuthenticationModeKeys.Sso)};

        static HttpActionContext CreateActionContext(HttpControllerDescriptor controllerDescriptor, HttpActionDescriptor descriptor)
        {
            var controllerContext = new HttpControllerContext
            {
                Request = new HttpRequestMessage(),
                ControllerDescriptor = controllerDescriptor
            };

            return new HttpActionContext(controllerContext, descriptor);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task NormalControllerHasNoEffect(bool isSsoEnabled)
        {
            _settings.AuthenticationModeEnabled(AuthenticationModeKeys.Sso).Returns(isSsoEnabled);

            var subject = new AuthenticationSettingsFilter(_settings);

            var controller = Substitute.For<HttpControllerDescriptor>();
            controller.GetCustomAttributes<RequiresAuthenticationSettingsAttribute>().Returns(_empty);

            var action = Substitute.For<HttpActionDescriptor>();
            action.GetCustomAttributes<RequiresAuthenticationSettingsAttribute>().Returns(_empty);

            await subject.OnAuthorizationAsync(CreateActionContext(controller, action), CancellationToken.None);
        }

        [Fact]
        public async Task SsoActionIsNotOkayWithSsoDisabled()
        {
            _settings.AuthenticationModeEnabled(AuthenticationModeKeys.Sso).Returns(false);

            var subject = new AuthenticationSettingsFilter(_settings);

            var controller = Substitute.For<HttpControllerDescriptor>();
            controller.GetCustomAttributes<RequiresAuthenticationSettingsAttribute>().Returns(_empty);

            var action = Substitute.For<HttpActionDescriptor>();
            action.GetCustomAttributes<RequiresAuthenticationSettingsAttribute>().Returns(_attribute);

            await Assert.ThrowsAsync<HttpResponseException>(
                                                            async () => await subject.OnAuthorizationAsync(CreateActionContext(controller, action), CancellationToken.None));
        }

        [Fact]
        public async Task SsoActionIsOkayWithSsoEnabled()
        {
            _settings.AuthenticationModeEnabled(AuthenticationModeKeys.Sso).Returns(true);

            var subject = new AuthenticationSettingsFilter(_settings);

            var controller = Substitute.For<HttpControllerDescriptor>();
            controller.GetCustomAttributes<RequiresAuthenticationSettingsAttribute>().Returns(_empty);

            var action = Substitute.For<HttpActionDescriptor>();
            action.GetCustomAttributes<RequiresAuthenticationSettingsAttribute>().Returns(_attribute);

            await subject.OnAuthorizationAsync(CreateActionContext(controller, action), CancellationToken.None);
        }

        [Fact]
        public async Task SsoControllerIsNotOkayWithSsoDisabled()
        {
            _settings.AuthenticationModeEnabled(AuthenticationModeKeys.Sso).Returns(false);

            var subject = new AuthenticationSettingsFilter(_settings);

            var controller = Substitute.For<HttpControllerDescriptor>();
            controller.GetCustomAttributes<RequiresAuthenticationSettingsAttribute>().Returns(_attribute);

            var action = Substitute.For<HttpActionDescriptor>();
            action.GetCustomAttributes<RequiresAuthenticationSettingsAttribute>().Returns(_empty);

            await Assert.ThrowsAsync<HttpResponseException>(
                                                            async () => await subject.OnAuthorizationAsync(CreateActionContext(controller, action), CancellationToken.None));
        }

        [Fact]
        public async Task SsoControllerIsOkayWithSsoEnabled()
        {
            _settings.AuthenticationModeEnabled(AuthenticationModeKeys.Sso).Returns(true);
            var subject = new AuthenticationSettingsFilter(_settings);

            var controller = Substitute.For<HttpControllerDescriptor>();
            controller.GetCustomAttributes<RequiresAuthenticationSettingsAttribute>().Returns(_attribute);

            var action = Substitute.For<HttpActionDescriptor>();
            action.GetCustomAttributes<RequiresAuthenticationSettingsAttribute>().Returns(_empty);

            await subject.OnAuthorizationAsync(CreateActionContext(controller, action), CancellationToken.None);
        }
    }
}