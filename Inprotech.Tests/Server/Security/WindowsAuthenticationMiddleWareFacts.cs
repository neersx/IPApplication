using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Security.Principal;
using System.Threading.Tasks;
using System.Web.Security;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Security;
using Inprotech.Server.Security;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Security;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using Microsoft.Owin;
using Microsoft.Owin.Security;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Server.Security
{
    public class WindowsAuthenticationMiddlewareFacts
    {
        public class InvokeMethod
        {
            static string SerialisedJson(dynamic data)
            {
                return JsonConvert.SerializeObject(data,
                                                   Formatting.Indented,
                                                   new JsonSerializerSettings
                                                   {
                                                       ContractResolver = new CamelCasePropertyNamesContractResolver()
                                                   });
            }

            [Theory]
            [InlineData("cpainpro/winAuth")]
            [InlineData("cpainpro/winAuth/endpoint")]
            public async Task DefaultsRedirectUrlToAppsPortal(string path)
            {
                var user = new User("bob", false)
                {
                    IsValid = true
                };

                var fixture = new WindowsAuthenticationMiddlewareFixture()
                              .WithIdentity("bob", true)
                              .WithPrincipalUser(user);

                fixture.UserValidation
                       .HasConfiguredAccess(user)
                       .Returns(ValidationResponse.Validated());

                fixture.LicenseAuthorization.TryAuthorize(user, out _)
                       .Returns(x =>
                       {
                           x[1] = AuthorizationResponse.Authorized();
                           return true;
                       });

                fixture.OwinRequest.Uri.Returns(new Uri($"http://localhost/{path}"));
                fixture.OwinResponse.Context.Request.Uri.Returns(new Uri($"http://localhost/{path}"));

                fixture.SourceIpAddressResolver.Resolve(fixture.OwinContext).Returns("167.67.78.99");

                await fixture.Subject.Invoke(fixture.OwinContext);

                var result = SerialisedJson(new
                {
                    Status = "success",
                    UserName = "bob",
                    ReturnUrl = new Uri("http://localhost/cpainpro/apps/#/home").ToString()
                });

                fixture.UserIdentityManager.Received(1).StartSession(user.Id, AuthenticationModeKeys.Windows, null, string.Empty, "167.67.78.99");
                fixture.OwinResponse.Received(1).WriteAsync(result).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task PreventIncompleteUserFromSigningIn()
            {
                var user = new User("bob", false)
                {
                    IsValid = false
                };

                var fixture = new WindowsAuthenticationMiddlewareFixture()
                              .WithIdentity("bob", true)
                              .WithPrincipalUser(user);

                fixture.UserValidation.HasConfiguredAccess(user)
                       .Returns(new ValidationResponse("incomplete-user"));

                await fixture.Subject.Invoke(fixture.OwinContext);

                var result = SerialisedJson(new
                {
                    failReasonCode = "incomplete-user",
                    accepted = false
                });

                fixture.OwinResponse.Received(1).WriteAsync(result).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task PreventLockedUserFromSigningIn()
            {
                var user = new User("bob", false)
                {
                    IsValid = true,
                    IsLocked = true
                };

                var fixture = new WindowsAuthenticationMiddlewareFixture()
                              .WithIdentity("bob", true)
                              .WithPrincipalUser(user);

                fixture.UserValidation.HasConfiguredAccess(user)
                       .Returns(ValidationResponse.Validated());

                await fixture.Subject.Invoke(fixture.OwinContext);

                var result = SerialisedJson(new
                {
                    parameter = (string) null,
                    failReasonCode = "unauthorised-accounts-locked",
                    accepted = false
                });

                fixture.OwinResponse.Received(1).WriteAsync(result).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task PreventUnlicensedUserFromSigningIn()
            {
                var user = new User("bob", false)
                {
                    IsValid = true
                };

                var fixture = new WindowsAuthenticationMiddlewareFixture()
                              .WithIdentity("bob", true)
                              .WithPrincipalUser(user);

                fixture.UserValidation
                       .HasConfiguredAccess(user)
                       .Returns(ValidationResponse.Validated());

                fixture.LicenseAuthorization.TryAuthorize(user, out _)
                       .Returns(x =>
                       {
                           x[1] = new AuthorizationResponse("some-failure-code", "some-parameter");
                           return false;
                       });

                await fixture.Subject.Invoke(fixture.OwinContext);

                var result = SerialisedJson(new
                {
                    parameter = "some-parameter",
                    failReasonCode = "some-failure-code",
                    accepted = false
                });

                fixture.OwinResponse.Received(1).WriteAsync(result).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ReturnAuthorisedResponse()
            {
                var user = new User("bob", false)
                {
                    IsValid = true
                };

                var fixture = new WindowsAuthenticationMiddlewareFixture()
                              .WithIdentity("bob", true)
                              .WithPrincipalUser(user);

                fixture.UserValidation
                       .HasConfiguredAccess(user)
                       .Returns(ValidationResponse.Validated());

                fixture.LicenseAuthorization.TryAuthorize(user, out _)
                       .Returns(x =>
                       {
                           x[1] = AuthorizationResponse.Authorized();
                           return true;
                       });

                fixture.OwinRequest.Query["redirectUrl"].Returns("http://somewhere.com");
                fixture.OwinResponse.Context.Request.Uri.Returns(new Uri($"http://somewhere.com"));
                fixture.SourceIpAddressResolver.Resolve(fixture.OwinContext).Returns("167.67.78.99");

                await fixture.Subject.Invoke(fixture.OwinContext);

                var result = SerialisedJson(new
                {
                    Status = "success",
                    UserName = "bob",
                    ReturnUrl = new Uri("http://somewhere.com")
                });

                fixture.UserIdentityManager.Received(1).StartSession(user.Id, AuthenticationModeKeys.Windows, null, string.Empty, "167.67.78.99");
                fixture.OwinResponse.Received(1).WriteAsync(result).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ReturnUnauthorisedResponseForUnauthenticatedUser()
            {
                var fixture = new WindowsAuthenticationMiddlewareFixture();

                await fixture.Subject.Invoke(fixture.OwinContext);

                var result = SerialisedJson(new
                {
                    Status = "unauthorised-windows-user",
                    UserName = (string) null,
                    ReturnUrl = (string) null
                });

                fixture.OwinResponse.Received(1).WriteAsync(result).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ReturnUnauthorisedResponseForUnmatchedUser()
            {
                var fixture = new WindowsAuthenticationMiddlewareFixture()
                              .WithIdentity("bob", true)
                              .WithPrincipalUser(null);

                await fixture.Subject.Invoke(fixture.OwinContext);

                var result = SerialisedJson(new
                {
                    Status = "unauthorised-windows-user",
                    UserName = (string) null,
                    ReturnUrl = (string) null
                });

                fixture.OwinResponse.Received(1).WriteAsync(result).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task TryExtendingTheSessionIfExtendRequested()
            {
                var user = new User("bob", false)
                {
                    IsValid = true
                };

                var fixture = new WindowsAuthenticationMiddlewareFixture()
                              .WithIdentity("bob", true)
                              .WithPrincipalUser(user)
                              .WithCookie();

                fixture.UserValidation
                       .HasConfiguredAccess(user)
                       .Returns(ValidationResponse.Validated());

                fixture.TokenExtender.ShouldExtend(Arg.Any<AuthCookieData>())
                       .Returns((true, true));

                fixture.OwinRequest.Query["extend"].Returns("true");
                fixture.OwinResponse.Context.Request.Uri.Returns(new Uri($"http://localhost/"));
                fixture.SourceIpAddressResolver.Resolve(fixture.OwinContext).Returns("167.67.78.99");

                await fixture.Subject.Invoke(fixture.OwinContext);

                var result = SerialisedJson(new
                {
                    Status = "success",
                    UserName = "bob",
                    ReturnUrl = (string) null
                });

                fixture.OwinResponse.Received(1).WriteAsync(result).IgnoreAwaitForNSubstituteAssertion();

                fixture.LicenseAuthorization.Received(0).TryAuthorize(Arg.Any<User>(), out _);
                fixture.UserIdentityManager.Received(0).StartSession(user.Id, AuthenticationModeKeys.Windows, null, null, "167.67.78.99");
            }
        }

        public class WindowsAuthenticationMiddlewareFixture : IFixture<WindowsAuthenticationMiddleware>
        {
            public WindowsAuthenticationMiddlewareFixture()
            {
                OwinContext = Substitute.For<IOwinContext>();
                OwinResponse = Substitute.For<IOwinResponse>();
                OwinRequest = Substitute.For<IOwinRequest>();

                PrincipalUser = Substitute.For<IPrincipalUser>();
                Logger = Substitute.For<IUserAuditLogger<WindowsAuthenticationMiddleware>>();
                LicenseAuthorization = Substitute.For<ILicenseAuthorization>();
                UserValidation = Substitute.For<IUserValidation>();
                AuthSettings = Substitute.For<IAuthSettings>();
                TokenExtender = Substitute.For<ITokenExtender>();

                OwinContext.Response.Returns(OwinResponse);
                OwinContext.Request.Returns(OwinRequest);

                OwinRequest.Cookies.Returns(new RequestCookieCollection(Substitute.For<IDictionary<string, string>>()));
                OwinResponse.Cookies.Returns(new ResponseCookieCollection(Substitute.For<IHeaderDictionary>()));

                SourceIpAddressResolver = Substitute.For<ISourceIpAddressResolver>();

                UserIdentityManager = Substitute.For<IUserIdentityAccessManager>();
                Subject = new WindowsAuthenticationMiddleware(null, PrincipalUser, AuthSettings, LicenseAuthorization, 
                                                              UserValidation, Logger, UserIdentityManager, TokenExtender, SourceIpAddressResolver);
            }

            public IOwinContext OwinContext { get; set; }
            public IOwinResponse OwinResponse { get; set; }
            public IOwinRequest OwinRequest { get; set; }
            public IPrincipalUser PrincipalUser { get; set; }
            public IUserAuditLogger<WindowsAuthenticationMiddleware> Logger { get; set; }
            public ILicenseAuthorization LicenseAuthorization { get; set; }
            public IUserValidation UserValidation { get; set; }
            public IAuthSettings AuthSettings { get; set; }
            public ITokenExtender TokenExtender { get; set; }
            public IUserIdentityAccessManager UserIdentityManager { get; set; }
            public ISourceIpAddressResolver SourceIpAddressResolver { get; set; }
            public WindowsAuthenticationMiddleware Subject { get; }

            public WindowsAuthenticationMiddlewareFixture WithIdentity(string name, bool authenticated)
            {
                var identity = Substitute.For<IIdentity>();
                var claimsPrincipal = Substitute.For<ClaimsPrincipal>();
                var auth = Substitute.For<IAuthenticationManager>();
                claimsPrincipal.Identity.Returns(identity);
                auth.User.Returns(claimsPrincipal);
                identity.Name.Returns(name);
                identity.IsAuthenticated.Returns(authenticated);

                OwinContext.Authentication.Returns(auth);
                return this;
            }

            public WindowsAuthenticationMiddlewareFixture WithPrincipalUser(User user)
            {
                PrincipalUser.From(Arg.Any<IPrincipal>()).Returns(user);

                return this;
            }

            public WindowsAuthenticationMiddlewareFixture WithCookie()
            {
                var ticket = FormsAuthentication.Encrypt(new FormsAuthenticationTicket(1, "a", DateTime.Now, DateTime.Now.AddHours(1), false,
                                                                                       JsonConvert.SerializeObject(new AuthCookieData(new AuthUser("user", 1, AuthenticationModeKeys.Windows, 1), false))));

                AuthSettings.SessionCookieName.Returns("a");
                OwinRequest.Cookies.Returns(new RequestCookieCollection(new Dictionary<string, string>
                {
                    {"a", ticket}
                }));

                return this;
            }
        }
    }
}