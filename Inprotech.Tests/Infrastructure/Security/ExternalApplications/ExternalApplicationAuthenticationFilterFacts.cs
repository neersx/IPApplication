using System;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using System.Web.Http.Hosting;
using System.Web.Http.Routing;
using Inprotech.Infrastructure.Security.ExternalApplications;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Security.ExternalApplications
{
    public class ExternalApplicationAuthenticationFilterFacts
    {
        public enum TokenAuthentication
        {
            OptedOut,
            OptedFor,
            OptedForWithUserNotRequired
        }

        public class ExternalAppAuthenticationFilterFixture : IFixture<ExternalApplicationAuthenticationFilter>
        {
            public ExternalAppAuthenticationFilterFixture()
            {
                ApiKeyValidator = Substitute.For<IApiKeyValidator>();
                ExternalApplicationContext = Substitute.For<IExternalApplicationContext>();
                UserValidator = Substitute.For<IUserValidator>();

                Subject = new ExternalApplicationAuthenticationFilter(ApiKeyValidator, UserValidator, ExternalApplicationContext);
            }

            public IApiKeyValidator ApiKeyValidator { get; set; }
            public IExternalApplicationContext ExternalApplicationContext { get; set; }
            public IUserValidator UserValidator { get; set; }

            public ExternalApplicationAuthenticationFilter Subject { get; }

            public HttpAuthenticationContext CreateAuthenticationContext(HttpRequestMessage request, TokenAuthentication withTokenAuthentication)
            {
                var whichType = typeof(DecoratedClass);
                switch (withTokenAuthentication)
                {
                    case TokenAuthentication.OptedOut:
                        whichType = typeof(NotDecoratedClass);
                        break;
                    case TokenAuthentication.OptedForWithUserNotRequired:
                        whichType = typeof(DecoratedUserNotRequiredClass);
                        break;
                }

                var controllerDescriptor = new HttpControllerDescriptor
                {
                    ControllerType = whichType
                };

                var config = new HttpConfiguration();
                var route = config.Routes.MapHttpRoute("DefaultApi", "api/{controller}/{action}/{id}");
                var routeData = new HttpRouteData(route, new HttpRouteValueDictionary {{"controller", "crm"}, {"action", "listcases"}});

                request.Properties[HttpPropertyKeys.HttpConfigurationKey] = config;

                var controllerContext = new HttpControllerContext(config, routeData, request) {ControllerDescriptor = controllerDescriptor};

                var actionContext =
                    new HttpActionContext(
                                          controllerContext, new ReflectedHttpActionDescriptor());

                var authenticationContext = new HttpAuthenticationContext(actionContext, null);

                return authenticationContext;
            }

            public class NotDecoratedClass
            {
            }

            [RequiresApiKey(ExternalApplicationName.Trinogy, true)]
            public class DecoratedClass
            {
            }

            [RequiresApiKey(ExternalApplicationName.Trinogy)]
            public class DecoratedUserNotRequiredClass
            {
            }
        }

        public class OnAuthenticateMethod : FactBase
        {
            const string UserName = "internal";

            HttpRequestMessage ConstructHttpRequest()
            {
                var httpRequest = new HttpRequestMessage(HttpMethod.Get, "http://localhost/api/products");

                httpRequest.Headers.Add("X-ApiKey", new Guid().ToString());
                httpRequest.Headers.Add("X-UserName", UserName);

                return httpRequest;
            }

            [Fact]
            public async Task DoesNotExtractHeaderValuesWhenTokenAuthenticationOptedOut()
            {
                var f = new ExternalAppAuthenticationFilterFixture();

                var authenticationContext = f.CreateAuthenticationContext(ConstructHttpRequest(), TokenAuthentication.OptedOut);

                await f.Subject.AuthenticateAsync(authenticationContext, CancellationToken.None);

                Assert.Null(authenticationContext.Principal);
            }

            [Fact]
            public async Task DoesSetExternalApplicationPrincipalWhenUserNameIsNotRequiredAndNotSupplied()
            {
                var f = new ExternalAppAuthenticationFilterFixture();

                var httpRequest = ConstructHttpRequest();
                httpRequest.Headers.Remove("X-UserName");

                var authenticationContext = f.CreateAuthenticationContext(httpRequest, TokenAuthentication.OptedForWithUserNotRequired);

                f.UserValidator.ValidateUser(Arg.Any<string>()).Returns(true);
                f.ApiKeyValidator.ValidateApiToken(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>()).Returns(true);

                await f.Subject.AuthenticateAsync(authenticationContext, CancellationToken.None);

                Assert.NotNull(authenticationContext.Principal);
                Assert.True(authenticationContext.Principal is ExternalApplicationPrincipal);
            }

            [Fact]
            public async Task ExternalApplicationPrincipalIdentityNameIsEmptyWhenUserNameIsNotRequiredAndNotSupplied()
            {
                var f = new ExternalAppAuthenticationFilterFixture();

                var httpRequest = ConstructHttpRequest();
                httpRequest.Headers.Remove("X-UserName");

                var authenticationContext = f.CreateAuthenticationContext(httpRequest, TokenAuthentication.OptedForWithUserNotRequired);

                f.UserValidator.ValidateUser(Arg.Any<string>()).Returns(true);
                f.ApiKeyValidator.ValidateApiToken(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>()).Returns(true);

                await f.Subject.AuthenticateAsync(authenticationContext, CancellationToken.None);

                Assert.Equal(string.Empty, authenticationContext.Principal.Identity.Name);
            }

            [Fact]
            public async Task ExtractUserNameWhenTokenAuthenticationOptedFor()
            {
                var f = new ExternalAppAuthenticationFilterFixture();

                var authenticationContext = f.CreateAuthenticationContext(ConstructHttpRequest(), TokenAuthentication.OptedFor);

                f.UserValidator.ValidateUser(Arg.Any<string>()).Returns(true);
                f.ApiKeyValidator.ValidateApiToken(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>()).Returns(true);

                await f.Subject.AuthenticateAsync(authenticationContext, CancellationToken.None);

                Assert.Equal(UserName, authenticationContext.Principal.Identity.Name);
            }

            [Fact]
            public async Task PrincipalIdentityAuthenticationTypeIsExternalApplicationWhenUserNameIsNotRequiredAndNotSupplied()
            {
                var f = new ExternalAppAuthenticationFilterFixture();

                var httpRequest = ConstructHttpRequest();
                httpRequest.Headers.Remove("X-UserName");

                var authenticationContext = f.CreateAuthenticationContext(httpRequest, TokenAuthentication.OptedForWithUserNotRequired);

                f.UserValidator.ValidateUser(Arg.Any<string>()).Returns(true);
                f.ApiKeyValidator.ValidateApiToken(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>()).Returns(true);

                await f.Subject.AuthenticateAsync(authenticationContext, CancellationToken.None);

                Assert.Equal("ExternalApplication", authenticationContext.Principal.Identity.AuthenticationType);
            }

            [Fact]
            public async Task PrincipalIdentityAuthenticationTypeIsExternalApplicationWithUserContextWhenUserNameIsNotRequiredAndIsSupplied()
            {
                var f = new ExternalAppAuthenticationFilterFixture();

                var httpRequest = ConstructHttpRequest();

                var authenticationContext = f.CreateAuthenticationContext(httpRequest, TokenAuthentication.OptedForWithUserNotRequired);

                f.UserValidator.ValidateUser(Arg.Any<string>()).Returns(true);
                f.ApiKeyValidator.ValidateApiToken(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>()).Returns(true);

                await f.Subject.AuthenticateAsync(authenticationContext, CancellationToken.None);

                Assert.Equal("ExternalApplicationWithUserContext", authenticationContext.Principal.Identity.AuthenticationType);
            }

            [Fact]
            public async Task PrincipalIdentityAuthenticationTypeIsExternalApplicationWithUserContextWhenUserNameIsRequiredAndIsSupplied()
            {
                var f = new ExternalAppAuthenticationFilterFixture();

                var httpRequest = ConstructHttpRequest();

                var authenticationContext = f.CreateAuthenticationContext(httpRequest, TokenAuthentication.OptedFor);

                f.UserValidator.ValidateUser(Arg.Any<string>()).Returns(true);
                f.ApiKeyValidator.ValidateApiToken(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>()).Returns(true);

                await f.Subject.AuthenticateAsync(authenticationContext, CancellationToken.None);

                Assert.Equal("ExternalApplicationWithUserContext", authenticationContext.Principal.Identity.AuthenticationType);
            }

            [Fact]
            public async Task ReturnsBadRequestWhenApiKeyIsNotSuppliedInRequest()
            {
                var f = new ExternalAppAuthenticationFilterFixture();

                var httpRequest = ConstructHttpRequest();
                httpRequest.Headers.Remove("X-ApiKey");

                var authenticationContext = f.CreateAuthenticationContext(httpRequest, TokenAuthentication.OptedFor);

                f.UserValidator.ValidateUser(Arg.Any<string>()).Returns(true);

                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () => await f.Subject.AuthenticateAsync(authenticationContext, CancellationToken.None));

                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ReturnsBadRequestWhenUserNameIsNotSuppliedInRequest()
            {
                var f = new ExternalAppAuthenticationFilterFixture();

                var httpRequest = ConstructHttpRequest();
                httpRequest.Headers.Remove("X-UserName");

                var authenticationContext = f.CreateAuthenticationContext(httpRequest, TokenAuthentication.OptedFor);

                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () => await f.Subject.AuthenticateAsync(authenticationContext, CancellationToken.None));

                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ReturnsNotFoundWhenUserIsInvalid()
            {
                var f = new ExternalAppAuthenticationFilterFixture();

                var authenticationContext = f.CreateAuthenticationContext(ConstructHttpRequest(), TokenAuthentication.OptedFor);

                f.UserValidator.ValidateUser(Arg.Any<string>()).Returns(false);

                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () => await f.Subject.AuthenticateAsync(authenticationContext, CancellationToken.None));

                Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ReturnsUnauthorizedWhenApiTokenIsInvalid()
            {
                var f = new ExternalAppAuthenticationFilterFixture();

                var authenticationContext = f.CreateAuthenticationContext(ConstructHttpRequest(), TokenAuthentication.OptedFor);

                f.UserValidator.ValidateUser(Arg.Any<string>()).Returns(true);
                f.ApiKeyValidator.ValidateApiToken(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>()).Returns(false);

                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () => await f.Subject.AuthenticateAsync(authenticationContext, CancellationToken.None));

                Assert.Equal(HttpStatusCode.Unauthorized, exception.Response.StatusCode);
            }

            [Fact]
            public async Task SetsApplicationNameWhenUserNameIsNotRequiredAndNotSupplied()
            {
                var f = new ExternalAppAuthenticationFilterFixture();

                var httpRequest = ConstructHttpRequest();
                httpRequest.Headers.Remove("X-UserName");

                var authenticationContext = f.CreateAuthenticationContext(httpRequest, TokenAuthentication.OptedForWithUserNotRequired);

                f.UserValidator.ValidateUser(Arg.Any<string>()).Returns(true);
                f.ApiKeyValidator.ValidateApiToken(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>()).Returns(true);

                await f.Subject.AuthenticateAsync(authenticationContext, CancellationToken.None);

                f.ExternalApplicationContext.Received(1).SetApplicationName(Arg.Is(ExternalApplicationName.Trinogy.ToString()));
            }

            [Fact]
            public async Task SetsPrincipalWhenUserNameIsNotRequiredButIsSupplied()
            {
                var f = new ExternalAppAuthenticationFilterFixture();

                var httpRequest = ConstructHttpRequest();

                var authenticationContext = f.CreateAuthenticationContext(httpRequest, TokenAuthentication.OptedForWithUserNotRequired);

                f.UserValidator.ValidateUser(Arg.Any<string>()).Returns(true);
                f.ApiKeyValidator.ValidateApiToken(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<bool>()).Returns(true);

                await f.Subject.AuthenticateAsync(authenticationContext, CancellationToken.None);

                Assert.Equal(UserName, authenticationContext.Principal.Identity.Name);
            }
        }
    }
}