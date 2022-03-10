using System.Collections.ObjectModel;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using Inprotech.Infrastructure.Security;
using Microsoft.Owin;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Security
{
    public class SessionValidationFilterFacts
    {
        HttpActionContext CreateActionContext(bool withOwinContext = true, bool withLogId = true, bool withAuthorizationRequired = true, bool isSecure = false)
        {
            var request = new HttpRequestMessage(HttpMethod.Get, isSecure ? "https://anywhere" : "http://anywhere");
            if (withOwinContext)
            {
                request.Properties["MS_OwinContext"] = withLogId
                    ? new OwinContext {Environment = {{"LogId", (long) 1}}}
                    : new OwinContext();
            }

            var controllerDescriptor = Substitute.For<HttpControllerDescriptor>();
            controllerDescriptor.GetCustomAttributes<AuthorizeAttribute>()
                                .Returns(withAuthorizationRequired
                                             ? new Collection<AuthorizeAttribute> {new AuthorizeAttribute()}
                                             : new Collection<AuthorizeAttribute>());

            var controllerContext = new HttpControllerContext {Request = request, ControllerDescriptor = controllerDescriptor};

            var actionDescriptor = Substitute.For<ReflectedHttpActionDescriptor>();
            actionDescriptor.ControllerDescriptor = controllerDescriptor;
            actionDescriptor.GetCustomAttributes<AuthorizeAttribute>().Returns(new Collection<AuthorizeAttribute>());

            return new HttpActionContext(controllerContext, actionDescriptor);
        }

        [Fact]
        public async Task ReturnsIfActionDoesNotRequireAuthorization()
        {
            var actionContext = CreateActionContext(true, true, false);
            var f = new SessionValidationFilterFixture();

            await f.Subject.OnAuthorizationAsync(actionContext, CancellationToken.None);
            Assert.Null(actionContext.Response);
        }

        [Fact]
        public async Task ReturnsIfLogIdNotFoundInEnvironment()
        {
            var actionContext = CreateActionContext(true, false);
            var f = new SessionValidationFilterFixture();

            await f.Subject.OnAuthorizationAsync(actionContext, CancellationToken.None);
            Assert.Null(actionContext.Response);
        }

        [Fact]
        public async Task ReturnsIfOwinContextNotFound()
        {
            var actionContext = CreateActionContext(false);
            var f = new SessionValidationFilterFixture();

            await f.Subject.OnAuthorizationAsync(actionContext, CancellationToken.None);
            Assert.Null(actionContext.Response);
        }

        [Fact]
        public async Task ReturnsIfSessionIsValid()
        {
            var actionContext = CreateActionContext();
            var f = new SessionValidationFilterFixture();

            f.SessionValidator.IsSessionValid(Arg.Any<long>()).Returns(true);

            await f.Subject.OnAuthorizationAsync(actionContext, CancellationToken.None);
            Assert.Null(actionContext.Response);
        }

        [Theory]
        [InlineData(true, 2)]
        [InlineData(false, 0)]
        public async Task ReturnsUnauthorizedIfSessionIsInvalid(bool secureFlag, int expectedSecureCookieCount)
        {
            var actionContext = CreateActionContext(isSecure: secureFlag);
            var f = new SessionValidationFilterFixture();

            f.SessionValidator.IsSessionValid(Arg.Any<long>()).Returns(false);
            f.AuthSettings.SessionCookieName.Returns("appscookie");

            await f.Subject.OnAuthorizationAsync(actionContext, CancellationToken.None);

            Assert.NotNull(actionContext.Response);
            Assert.Equal(HttpStatusCode.Unauthorized, actionContext.Response.StatusCode);

            var cookies = actionContext.Response.Headers.GetValues("Set-Cookie").ToList();
            
            Assert.Single(cookies.Where(_ => _.Contains("appscookie=;")));
            Assert.Single(cookies.Where(_ => _.Contains("XSRF-TOKEN=;")));
            Assert.Equal(expectedSecureCookieCount, cookies.Count(_ => _.Contains("secure")));
        }
    }

    public class SessionValidationFilterFixture : IFixture<SessionValidationFilter>
    {
        public SessionValidationFilterFixture()
        {
            SessionValidator = Substitute.For<ISessionValidator>();
            AuthSettings = Substitute.For<IAuthSettings>();

            Subject = new SessionValidationFilter(SessionValidator, AuthSettings);
        }

        public ISessionValidator SessionValidator { get; }

        public IAuthSettings AuthSettings { get; }

        public SessionValidationFilter Subject { get; }
    }
}