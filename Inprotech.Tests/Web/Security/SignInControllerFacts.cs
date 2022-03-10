using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Security.Principal;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using System.Web.Http.Hosting;
using System.Web.Security;
using CPA.SingleSignOn.Client.Models;
using CPA.SingleSignOn.Client.Services;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Analytics;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Security;
using Inprotech.Web.Security.ResetPassword;
using Inprotech.Web.Security.TwoFactorAuth;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.Security.SingleSignOn;
using InprotechKaizen.Model.Security;
using Microsoft.Owin;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class SignInControllerFacts : FactBase
    {
        SignInControllerFixture _f;

        [Theory]
        [InlineData(null)]
        [InlineData("")]
        public async Task EmptyUserNameAndPasswordShouldReturnUnauthorised(string emptyValue)
        {
            _f = new SignInControllerFixture(Db);

            var r = await _f.Subject.Post(JObject.FromObject(new SigninCredentials
            {
                Username = emptyValue,
                Password = emptyValue
            }));

            var d = (SignInResponse)((ObjectContent)r.Content).Value;
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("unauthorised-credentials", d.Status);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ReturnUnauthorisedWhenFailedUserValidation(bool passwordMd5)
        {
            _f = new SignInControllerFixture(Db);

            var user = CreateUser("bob", "dabadee", passwordMd5);

            _f.UserValidation.Validate(user, "guessme")
              .Returns(new AuthorizationResponse("unauthorised-credentials"));

            var r = await _f.Subject.Post(JObject.FromObject(new SigninCredentials
            {
                Username = "bob",
                Password = "guessme"
            }));

            var d = (AuthorizationResponse)((ObjectContent)r.Content).Value;
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("unauthorised-credentials", d.FailReasonCode);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ValidUserNameAndPasswordShouldReturnSuccess(bool passwordMd5)
        {
            _f = new SignInControllerFixture(Db);

            var user = CreateUser("bob", "dabadee", passwordMd5);

            var validated = AuthorizationResponse.Authorized();

            _f.UserValidation.Validate(user, "dabadee")
              .Returns(validated);

            _f.LicenseAuthorization.TryAuthorize(Arg.Any<User>(), out _)
              .Returns(x =>
              {
                  x[1] = AuthorizationResponse.Authorized();
                  return true;
              });

            var r = await _f.Subject.Post(JObject.FromObject(new SigninCredentials
            {
                Username = "bob",
                Password = "dabadee"
            }));

            var d = (SignInResponse)((ObjectContent)r.Content).Value;
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("success", d.Status);
            Assert.Contains("; path=a/b/c; httponly", r.Headers.GetValues("Set-Cookie").Single(_ => _.Contains(_f.Settings.SessionCookieName)));
            //Assert.Contains("; path=a/b/c", r.Headers.GetValues("Set-Cookie").Single(_ => _.Contains(CsrfConfigOptions.CookieName)));
        }

        [Fact]
        public async Task ValidateTwoFactorRedirectsToRequestCodeIfConfigured()
        {
            var user = CreateUser("bob", "dabadee", true);
            var validated = AuthorizationResponse.Authorized();

            _f = new SignInControllerFixture(Db);

            _f.Settings.TwoFactorAuthenticationEnabled(user.IsExternalUser).Returns(true);

            _f.UserValidation.Validate(user, "dabadee", Arg.Any<string>(), Arg.Any<string>())
              .Returns(validated);

            _f.LicenseAuthorization.TryAuthorize(Arg.Any<User>(), out _)
              .Returns(x =>
              {
                  x[1] = AuthorizationResponse.Authorized();
                  return true;
              });

            var r = await _f.Subject.Post(JObject.FromObject(new SigninCredentials
            {
                Username = "bob",
                Password = "dabadee"
            }));

            var d = (SignInResponse)((ObjectContent)r.Content).Value;
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("codeRequired", d.Status);
            Assert.False(r.Headers.TryGetValues("Set-Cookie", out _));
        }

        [Fact]
        public async Task ValidateProvidesCookieIfUserHasPreviouslyLoggedInAndSessionExpiryModePassedIn()
        {
            var user = CreateUser("bob", "dabadee", true);
            var validated = AuthorizationResponse.Authorized();

            _f = new SignInControllerFixture(Db).WithCookie(user);

            _f.Settings.TwoFactorAuthenticationEnabled(user.IsExternalUser).Returns(true);

            _f.UserValidation.Validate(user, "dabadee", Arg.Any<string>(), Arg.Any<string>())
              .Returns(validated);

            _f.UserValidation.Validate(user, "dabadee")
              .Returns(validated);

            _f.LicenseAuthorization.TryAuthorize(Arg.Any<User>(), out _)
              .Returns(x =>
              {
                  x[1] = AuthorizationResponse.Authorized();
                  return true;
              });

            var r = await _f.Subject.Post(JObject.FromObject(new SigninCredentials
            {
                Username = "bob",
                Password = "dabadee",
                SessionResume = true
            }));

            var d = (SignInResponse)((ObjectContent)r.Content).Value;
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.NotEqual("codeRequired", d.Status);
            Assert.True(r.Headers.TryGetValues("Set-Cookie", out _));
        }

        [Fact]
        public async Task ValidateDoesNotSkipTwoFactorIfDifferentUserTriesToAuthenticate()
        {
            var user = CreateUser("bob", "dabadee", true);
            var user2 = CreateUser("user2", "dabadee", true);
            var validated = AuthorizationResponse.Authorized();

            _f = new SignInControllerFixture(Db).WithCookie(user2);

            _f.Settings.TwoFactorAuthenticationEnabled(user.IsExternalUser).Returns(true);

            _f.UserValidation.Validate(user, "dabadee", Arg.Any<string>(), Arg.Any<string>())
              .Returns(validated);

            _f.UserValidation.Validate(user, "dabadee")
              .Returns(validated);

            _f.LicenseAuthorization.TryAuthorize(Arg.Any<User>(), out _)
              .Returns(x =>
              {
                  x[1] = AuthorizationResponse.Authorized();
                  return true;
              });

            var r = await _f.Subject.Post(JObject.FromObject(new SigninCredentials
            {
                Username = "bob",
                Password = "dabadee",
                SessionResume = true
            }));

            var d = (SignInResponse)((ObjectContent)r.Content).Value;
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("codeRequired", d.Status);
            Assert.False(r.Headers.TryGetValues("Set-Cookie", out _));
        }

        [Fact]
        public async Task ValidateTwoFactorDoesNotRedirectIfNotConfigured()
        {
            _f = new SignInControllerFixture(Db);

            var user = CreateUser("bob", "dabadee", true);

            var validated = AuthorizationResponse.Authorized();

            _f.Settings.TwoFactorAuthenticationEnabled(user.IsExternalUser).Returns(false);

            _f.UserValidation.Validate(user, "dabadee")
              .Returns(validated);

            _f.LicenseAuthorization.TryAuthorize(Arg.Any<User>(), out _)
              .Returns(x =>
              {
                  x[1] = AuthorizationResponse.Authorized();
                  return true;
              });

            var r = await _f.Subject.Post(JObject.FromObject(new SigninCredentials
            {
                Username = "bob",
                Password = "dabadee"
            }));

            var d = (SignInResponse)((ObjectContent)r.Content).Value;
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("success", d.Status);
            Assert.Contains("; path=a/b/c; httponly", r.Headers.GetValues("Set-Cookie").Single(_ => _.Contains(_f.Settings.SessionCookieName)));
        }

        [Fact]
        public async Task ValidateTwoFactorSuccessRedirects()
        {
            _f = new SignInControllerFixture(Db);

            var user = CreateUser("bob", "dabadee", true);

            var validated = AuthorizationResponse.Authorized();

            _f.Settings.TwoFactorAuthenticationEnabled(user.IsExternalUser).Returns(true);

            _f.UserValidation.Validate(user, "dabadee", Arg.Any<string>(), Arg.Any<string>())
              .Returns(validated);

            _f.LicenseAuthorization.TryAuthorize(Arg.Any<User>(), out _)
              .Returns(x =>
              {
                  x[1] = AuthorizationResponse.Authorized();
                  return true;
              });

            var authCode = "code";
            var authMode = string.Empty;
            _f.TwoFactorAuthVerify.Verify(authMode, authCode, user).Returns(true);

            var r = await _f.Subject.Post(JObject.FromObject(new SigninCredentials
            {
                Username = "bob",
                Password = "dabadee",
                Preference = authMode,
                Code = authCode
            }));

            var d = (SignInResponse)((ObjectContent)r.Content).Value;
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("success", d.Status);
            Assert.Contains("; path=a/b/c; httponly", r.Headers.GetValues("Set-Cookie").Single(_ => _.Contains(_f.Settings.SessionCookieName)));
        }

        [Fact]
        public async Task ValidateTwoFactorFailDoesNotRedirectOrSupplyCookie()
        {
            var authCode = "code";
            var authMode = string.Empty;
            var user = CreateUser("bob", "dabadee", true);

            _f = new SignInControllerFixture(Db);

            _f.Settings.TwoFactorAuthenticationEnabled(user.IsExternalUser).Returns(true);

            _f.UserValidation.Validate(user, "dabadee", authMode, authCode)
              .Returns(new AuthorizationResponse("two-factor-failed"));

            _f.LicenseAuthorization.TryAuthorize(Arg.Any<User>(), out _)
              .Returns(x =>
              {
                  x[1] = AuthorizationResponse.Authorized();
                  return true;
              });

            var r = await _f.Subject.Post(JObject.FromObject(new SigninCredentials
            {
                Username = "bob",
                Password = "dabadee",
                Preference = authMode,
                Code = authCode
            }));

            var d = (AuthorizationResponse)((ObjectContent)r.Content).Value;

            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("two-factor-failed", d.FailReasonCode);
            Assert.False(r.Headers.TryGetValues("Set-Cookie", out _));
        }

        public class Ping : FactBase
        {

            SignInControllerFixture _f;

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task PingShouldExtendAdfsSession(bool secureFlag)
            {
                _f = new SignInControllerFixture(Db, secureFlag);
                var cookieValue = secureFlag ? "; domain=localhost; path=a/b/c; secure; httponly" : "; domain=localhost; path=a/b/c; httponly";

                var user = new User("adfs", false).In(Db);

                _f.TokenExtender
                  .ShouldExtend(Arg.Any<AuthCookieData>())
                  .Returns((true, true));

                _f.WithCookie(user, AuthenticationModeKeys.Adfs);

                var r = await _f.Subject.PingToCheckSessionValidity();

                _f.TokenExtender
                  .Received(1)
                  .ShouldExtend(Arg.Any<AuthCookieData>())
                  .IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(HttpStatusCode.OK, r.StatusCode);
                Assert.Equal("success", ((dynamic)((ObjectContent)r.Content).Value).Status);
                Assert.Contains(r.Headers.GetValues("Set-Cookie"), _ => _.Contains(cookieValue));
            }

            [Fact]
            public async Task PingShouldExtendNonSsoSession()
            {
                _f = new SignInControllerFixture(Db);

                var user = new User("user", false).In(Db);

                _f.WithCookie(user, AuthenticationModeKeys.Forms);

                var r = await _f.Subject.PingToCheckSessionValidity();

                _f.TokenExtender
                  .DidNotReceiveWithAnyArgs()
                  .ShouldExtend(Arg.Any<AuthCookieData>())
                  .IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(HttpStatusCode.OK, r.StatusCode);
                Assert.Equal("success", ((dynamic)((ObjectContent)r.Content).Value).Status);
                Assert.False(r.Headers.Any());

                _f.WithCookie(user, AuthenticationModeKeys.Windows);

                r = await _f.Subject.PingToCheckSessionValidity();

                _f.TokenExtender
                  .DidNotReceiveWithAnyArgs()
                  .ShouldExtend(Arg.Any<AuthCookieData>())
                  .IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(HttpStatusCode.OK, r.StatusCode);
                Assert.Equal("success", ((dynamic)((ObjectContent)r.Content).Value).Status);
                Assert.False(r.Headers.Any());
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task PingShouldExtendSsoSession(bool secureFlag)
            {
                _f = new SignInControllerFixture(Db, secureFlag);
                var cookieValue = secureFlag ? "; path=a/b/c; secure; httponly" : "; path=a/b/c; httponly";

                var user = new User("sso", false).In(Db);

                _f.TokenExtender.ShouldExtend(Arg.Any<AuthCookieData>())
                  .Returns((true, true));

                _f.WithCookie(user);

                var r = await _f.Subject.PingToCheckSessionValidity();

                _f.TokenExtender
                  .Received(1)
                  .ShouldExtend(Arg.Any<AuthCookieData>())
                  .IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(HttpStatusCode.OK, r.StatusCode);
                Assert.Equal("success", ((dynamic)((ObjectContent)r.Content).Value).Status);
                Assert.Contains(r.Headers.GetValues("Set-Cookie"), _ => _.Contains(cookieValue));
            }
        }

        public class SignInControllerFixture : IFixture<SignInController>
        {
            readonly HttpRequestMessage _request;
            public IAdfsAuthenticator AdfsAuthenticator { get; }
            public ClaimsPrincipal ClaimsPricipal { get; }
            public ILicenseAuthorization LicenseAuthorization { get; }
            public IPrincipalUser PrincipalUser { get; }
            public Guid ReturnedGuk { get; }
            public string ReturnSessionid { get; }
            public IAuthSettings Settings { get; }
            public ITokenExtender TokenExtender { get; }
            public ITokenManagementService TokenManagement { get; }
            public ITokenValidationService TokenValidation { get; }
            public ISsoUserIdentifier UserIdentifier { get; }
            public IUserIdentityAccessManager UserIdentityAccess { get; }
            public IUserValidation UserValidation { get; }
            public ITwoFactorAuthVerify TwoFactorAuthVerify { get; }
            public IResetPasswordHelper ResetPasswordHelper { get; }
            public ISourceIpAddressResolver SourceIpAddressResolver { get; }
            public IProductImprovementSettingsResolver ProductImprovementSettingsResolver { get; }
            public SignInControllerFixture(InMemoryDbContext db, bool isSecure = false)
            {
                Settings = Substitute.For<IAuthSettings>();
                Settings.SessionTimeout.Returns(10);
                Settings.SessionCookieName.Returns(".CPASSInprotech");
                Settings.SessionCookiePath.Returns("a/b/c");
                Settings.SessionCookieDomain.Returns("localhost");

                UserValidation = Substitute.For<IUserValidation>();
                ProductImprovementSettingsResolver = Substitute.For<IProductImprovementSettingsResolver>();
                TwoFactorAuthVerify = Substitute.For<ITwoFactorAuthVerify>();

                LicenseAuthorization = Substitute.For<ILicenseAuthorization>();

                TokenManagement = Substitute.For<ITokenManagementService>();
                TokenValidation = Substitute.For<ITokenValidationService>();

                _request = new HttpRequestMessage(HttpMethod.Post, isSecure ? "https://localhost/cpainproma/apps/signin" : "http://localhost/cpainproma/apps/signin");
                _request.Properties[HttpPropertyKeys.HttpConfigurationKey] = new HttpConfiguration();
                UserIdentityAccess = Substitute.For<IUserIdentityAccessManager>();
                TokenExtender = Substitute.For<ITokenExtender>();

                TokenManagement.GetByCode(Arg.Any<string>(), Arg.Any<string>()).Returns(new SSOProviderResponse());
                ClaimsPricipal = new ClaimsPrincipal();
                ReturnedGuk = Guid.NewGuid();
                ReturnSessionid = "session id";
                ClaimsPricipal.AddIdentity(new ClaimsIdentity(new[] { new Claim("guk", ReturnedGuk.ToString()), new Claim("first_name", "First Name"), new Claim("last_name", "Last Name"), new Claim(ClaimTypes.Email, "a@xyz.com"), new Claim("session_id", ReturnSessionid) }));
                TokenValidation.ValidateToPrincipal(Arg.Any<string>()).Returns(ClaimsPricipal);
                TokenExtender = Substitute.For<ITokenExtender>();
                UserIdentifier = Substitute.For<ISsoUserIdentifier>();
                PrincipalUser = Substitute.For<IPrincipalUser>();
                ResetPasswordHelper = Substitute.For<IResetPasswordHelper>();

                AdfsAuthenticator = Substitute.For<IAdfsAuthenticator>();
                var logger = Substitute.For<IUserAuditLogger<SignInController>>();

                SourceIpAddressResolver = Substitute.For<ISourceIpAddressResolver>();
                SourceIpAddressResolver.Resolve(Arg.Any<HttpRequestMessage>()).Returns((string)null);
                SourceIpAddressResolver.Resolve(Arg.Any<IOwinContext>()).Returns((string)null);

                Subject = new SignInController(db, Settings, UserValidation, LicenseAuthorization, TokenManagement, TokenValidation, UserIdentityAccess,
                                               UserIdentifier, AdfsAuthenticator, TokenExtender, PrincipalUser, logger, SourceIpAddressResolver, Substitute.For<IUserTwoFactorAuthPreference>(), TwoFactorAuthVerify, ResetPasswordHelper, ProductImprovementSettingsResolver)
                {
                    Request = _request
                };
            }

            public SignInController Subject { get; }

            public SignInControllerFixture WithCookie(User user, string authMode = AuthenticationModeKeys.Sso, string cookiePath = "a/b/c", string cookieDomain = "localhost")
            {
                var ticket = new FormsAuthenticationTicket(1, ".CPASSInprotech", Fixture.Today(), Fixture.FutureDate(), false,
                                                           JsonConvert.SerializeObject(new AuthCookieData(new AuthUser(user.UserName, user.Id, authMode, 1), false)), cookiePath);

                var encryptedTicket = FormsAuthentication.Encrypt(ticket);

                if (_request.Headers.Contains("Cookie"))
                {
                    _request.Headers.Remove("Cookie");
                }

                _request.Headers.Add("Cookie", new[]
                {
                    new CookieHeaderValue(".CPASSInprotech", encryptedTicket)
                    {
                        Path = cookiePath,
                        Domain = cookieDomain
                    }.ToString()
                });

                return this;
            }
        }

        [Fact]
        public void AdfsShouldRedirectUser()
        {
            _f = new SignInControllerFixture(Db);

            _f.AdfsAuthenticator.GetLoginUrl().Returns("http://sso.com?token_type=authorize");
            _f.AdfsAuthenticator.GetCallbackUri(Arg.Any<string>(), out _).Returns(x =>
            {
                x[1] = "http://localhost/cpainproma/apps/adfsreturn";
                return true;
            });
            var r = _f.Subject.Adfs(string.Empty);
            Assert.Equal(HttpStatusCode.Moved, r.StatusCode);
            Assert.Equal(new Uri($"http://sso.com/?token_type=authorize&redirect_uri={HttpUtility.UrlEncode("http://localhost/cpainproma/apps/adfsreturn?redirectUrl=")}"), r.Headers.Location);

            r = _f.Subject.Adfs("http://localhost/cpainproma/apps/system");
            Assert.Equal(HttpStatusCode.Moved, r.StatusCode);

            var returnUrl = new Uri($"http://localhost/cpainproma/apps/adfsreturn?redirectUrl={HttpUtility.UrlEncode("http://localhost/cpainproma/apps/system")}").ToString();
            Assert.Equal(new Uri($"http://sso.com/?token_type=authorize&redirect_uri={HttpUtility.UrlEncode(returnUrl)}"), r.Headers.Location);
        }

        [Fact]
        public async Task ProcessResponseFromAdfsServer()
        {
            _f = new SignInControllerFixture(Db);

            var expected = new User("INT\\Test", false).In(Db);
            _f.ClaimsPricipal.Identities.First().AddClaim(new Claim(ClaimTypes.WindowsAccountName, expected.UserName));
            _f.AdfsAuthenticator.ValidateToPrincipal(Arg.Any<string>()).Returns(_f.ClaimsPricipal);

            _f.AdfsAuthenticator
              .GetToken(Arg.Any<string>(), Arg.Any<string>())
              .Returns(_ => new SSOProviderResponse { AccessToken = "token", ExpiresIn = 60, RefreshToken = "Refresh", TokenType = "Code" });

            _f.UserValidation
              .HasConfiguredAccess(Arg.Any<User>())
              .Returns(new ValidationResponse());

            _f.LicenseAuthorization.TryAuthorize(Arg.Any<User>(), out _)
              .Returns(x =>
              {
                  x[1] = AuthorizationResponse.Authorized();
                  return true;
              });
            _f.PrincipalUser.From(Arg.Any<ClaimsPrincipal>(), Arg.Any<string>()).Returns(expected);

            var r = await _f.Subject.AdfsReturn(string.Empty, "code");
            Assert.Equal(HttpStatusCode.Moved, r.StatusCode);
            Assert.Equal(new Uri($"http://localhost/cpainproma/apps/signin/redirect/#/?goto={HttpUtility.UrlEncode("http://localhost/cpainproma/apps/portal")}"), r.Headers.Location);

            _f.UserIdentityAccess
              .Received(1)
              .StartSession(Arg.Any<int>(),
                            AuthenticationModeKeys.Adfs,
                            Arg.Is<UserIdentityAccessData>(_ => _.RefreshToken == "Refresh"), null, null);
        }

        [Fact]
        public async Task ProcessResponseFromSsoServer()
        {
            _f = new SignInControllerFixture(Db);

            var expected = new User("Some user", false);
            _f.TokenManagement
              .GetByCode(Arg.Any<string>(), Arg.Any<string>())
              .Returns(_ => new SSOProviderResponse { AccessToken = "token", ExpiresIn = 60, RefreshToken = "Refresh", TokenType = "Code" });

            _f.UserValidation
              .HasConfiguredAccess(Arg.Any<User>())
              .Returns(new ValidationResponse());

            _f.LicenseAuthorization.TryAuthorize(Arg.Any<User>(), out _)
              .Returns(x =>
              {
                  x[1] = AuthorizationResponse.Authorized();
                  return true;
              });

            _f.UserIdentifier.TryLinkUserAuto(Arg.Any<SsoIdentity>(), out _, out _)
              .Returns(x =>
              {
                  x[1] = expected;
                  x[2] = SsoUserLinkResultType.Success;
                  return true;
              });

            var r = await _f.Subject.SsoReturn(string.Empty, "code");
            Assert.Equal(HttpStatusCode.Moved, r.StatusCode);
            Assert.Equal(new Uri($"http://localhost/cpainproma/apps/signin/redirect/#/?goto={HttpUtility.UrlEncode("http://localhost/cpainproma/apps/portal")}"), r.Headers.Location);

            _f.UserIdentityAccess
              .Received(1)
              .StartSession(Arg.Any<int>(),
                            AuthenticationModeKeys.Sso,
                            Arg.Is<UserIdentityAccessData>(_ => _.RefreshToken == "Refresh" && _.AccessToken == "token" && _.SessionId == _f.ReturnSessionid),
                            null, null);
        }

        [Fact]
        public void ReturnsAuthenticationSettingsFromConfig()
        {
            _f = new SignInControllerFixture(Db);

            _f.Settings.FormsEnabled.Returns(true);
            _f.Settings.WindowsEnabled.Returns(false);
            _f.Settings.SsoEnabled.Returns(true);
            _f.ProductImprovementSettingsResolver.Resolve().Returns(new ProductImprovementSettings() {UserUsageStatisticsConsented = true});

            var result = _f.Subject.GetSignInOptions();

            Assert.True(result.ShowForms);
            Assert.False(result.ShowWindows);
            Assert.True(result.ShowSso);
            Assert.True(result.FirmConsentedToUserStatistics);
        }

        [Fact]
        public async Task ReturnsLicensingIssuesAsResponse()
        {
            _f = new SignInControllerFixture(Db);

            var user = CreateUser("bob", "dabadee", true);
            var validated = AuthorizationResponse.Authorized();
            _f.UserValidation.Validate(user, "dabadee").Returns(validated);

            _f.LicenseAuthorization.TryAuthorize(Arg.Any<User>(), out _)
              .Returns(x =>
              {
                  x[1] = new AuthorizationResponse("blah-blah-blah", "unlicensed module");
                  return false;
              });

            var r = await _f.Subject.Post(JObject.FromObject(new SigninCredentials
            {
                Username = "bob",
                Password = "dabadee"
            }));

            var d = (AuthorizationResponse)((ObjectContent)r.Content).Value;
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("blah-blah-blah", d.FailReasonCode);
            Assert.Equal("unlicensed module", d.Parameter);
        }

        [Fact]
        public async Task ReturnsPasswordExpiringAsResponse()
        {
            _f = new SignInControllerFixture(Db);

            var user = CreateUser("bob", "dabadee", true);
            var validated = AuthorizationResponse.Authorized();
            _f.UserValidation.Validate(user, "dabadee").Returns(validated);
            _f.UserValidation.IsPasswordExpired(user).Returns(true);

            _f.LicenseAuthorization.TryAuthorize(Arg.Any<User>(), out _)
              .Returns(x =>
              {
                  x[1] = AuthorizationResponse.Authorized();
                  return true;
              });

            _f.ResetPasswordHelper.ResolveSecretKey(user).Returns(Fixture.String("token"));

            var r = await _f.Subject.Post(JObject.FromObject(new SigninCredentials
            {
                Username = "bob",
                Password = "dabadee"
            }));

            var d = (SignInResponse)((ObjectContent)r.Content).Value;
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.True(d.ReturnUrl.Contains("token"));
            Assert.Equal("resetPassword", d.Status);
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ShouldExtendAdfsSession(bool secureFlag)
        {
            _f = new SignInControllerFixture(Db, secureFlag);
            var cookieValue = secureFlag ? "; domain=localhost; path=a/b/c; secure; httponly" : "; domain=localhost; path=a/b/c; httponly";

            var user = new User("sso", false).In(Db);

            _f.TokenExtender.ShouldExtend(Arg.Any<AuthCookieData>()).Returns((true, true));
            _f.WithCookie(user, AuthenticationModeKeys.Adfs);

            var r = await _f.Subject.ExtendSso();
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("success", ((dynamic)((ObjectContent)r.Content).Value).Status);
            Assert.Contains(r.Headers.GetValues("Set-Cookie"), _ => _.Contains(cookieValue));
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ShouldExtendSsoSession(bool secureFlag)
        {
            _f = new SignInControllerFixture(Db, secureFlag);
            var cookieValue = secureFlag ? "; domain=localhost; path=a/b/c; secure; httponly" : "; domain=localhost; path=a/b/c; httponly";

            var user = new User("sso", false).In(Db);

            _f.TokenExtender.ShouldExtend(Arg.Any<AuthCookieData>())
              .Returns((true, true));
            _f.WithCookie(user);
            var r = await _f.Subject.ExtendSso();
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("success", ((dynamic)((ObjectContent)r.Content).Value).Status);
            Assert.Contains(cookieValue, r.Headers.GetValues("Set-Cookie").Single(_ => _.Contains(_f.Settings.SessionCookieName)));
        }

        [Fact]
        public async Task ShouldReturFailureIfNotSso()
        {
            _f = new SignInControllerFixture(Db);

            _f.TokenExtender.ShouldExtend(Arg.Any<AuthCookieData>())
              .Returns((false, false));

            var r = await _f.Subject.ExtendSso();
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("failure", ((dynamic)((ObjectContent)r.Content).Value).Status);
        }

        [Fact]
        public async Task ShouldReturnFailureIfCookieNotPresentInPost12_1()
        {
            _f = new SignInControllerFixture(Db);

            _f.TokenExtender.ShouldExtend(Arg.Any<AuthCookieData>())
              .Returns((false, false));

            var r = await _f.Subject.ExtendSso();
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("failure", ((dynamic)((ObjectContent)r.Content).Value).Status);
            Assert.False(r.Headers.Any());
        }

        [Fact]
        public async Task ShouldReturnWithoutResponseCookieIfCookieNotPresentInPre12_1()
        {
            _f = new SignInControllerFixture(Db);

            _f.TokenExtender.ShouldExtend(Arg.Any<AuthCookieData>())
              .Returns((false, true));

            var r = await _f.Subject.ExtendSso();
            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("success", ((dynamic)((ObjectContent)r.Content).Value).Status);
            Assert.False(r.Headers.Any());
        }

        [Fact]
        public async Task ShouldThrowErrorIfAccountNotFoundForAdfs()
        {
            _f = new SignInControllerFixture(Db);

            var identity = new ClaimsIdentity();
            identity.AddClaim(new Claim(ClaimTypes.WindowsAccountName, "INT\\Test"));

            _f.AdfsAuthenticator
              .GetToken(Arg.Any<string>(), Arg.Any<string>())
              .Returns(_ => new SSOProviderResponse { AccessToken = "token", ExpiresIn = 60, RefreshToken = "Refresh", TokenType = "Code" });

            _f.AdfsAuthenticator
              .ValidateToPrincipal("token")
              .Returns(new GenericPrincipal(identity, new string[0]));

            await Assert.ThrowsAsync<SsoException>(async () => await _f.Subject.SsoReturn(string.Empty, "code"));
        }

        [Fact]
        public async Task ShouldThrowErrorIfGukNotFound()
        {
            _f = new SignInControllerFixture(Db);

            var guk = new Guid();

            var identity = new ClaimsIdentity();
            identity.AddClaim(new Claim("guk", guk.ToString()));

            _f.TokenManagement
              .GetByCode(Arg.Any<string>(), Arg.Any<string>())
              .Returns(_ => new SSOProviderResponse { AccessToken = "token", ExpiresIn = 60, RefreshToken = "Refresh", TokenType = "Code" });

            _f.TokenValidation
              .ValidateToPrincipal("token")
              .Returns(new GenericPrincipal(identity, new string[0]));

            await Assert.ThrowsAsync<SsoException>(async () => await _f.Subject.SsoReturn(string.Empty, "code"));
        }

        [Fact]
        public async Task SsoReturnCallsAppropriateFunctions()
        {
            _f = new SignInControllerFixture(Db);

            var expectedUser = new User("Some user", false);

            var user = expectedUser;
            _f.UserIdentifier.TryFindUser(Arg.Any<Guid>(), out _).Returns(x =>
            {
                x[1] = user;
                return true;
            });
            _f.UserIdentifier.TryLinkUserAuto(Arg.Any<SsoIdentity>(), out expectedUser, out _).Returns(true);
            _f.UserValidation.HasConfiguredAccess(Arg.Any<User>()).Returns(ValidationResponse.Validated());
            _f.LicenseAuthorization.TryAuthorize(Arg.Any<User>(), out _).Returns(true);

            await _f.Subject.SsoReturn("http://cpainproma/portal", "some code");

            _f.UserIdentifier.Received(1).TryFindUser(_f.ReturnedGuk, out _);
            _f.UserIdentifier.Received(1).EnforceEmailValidity(Arg.Any<string>(), expectedUser, out _);
            _f.UserIdentifier.Received(1).TryLinkUserAuto(Arg.Any<SsoIdentity>(), out expectedUser, out _);
            _f.UserValidation.Received(1).HasConfiguredAccess(expectedUser);
            _f.LicenseAuthorization.Received(1).TryAuthorize(expectedUser, out _);
        }

        [Fact]
        public void SsoShouldRedirectUser()
        {
            _f = new SignInControllerFixture(Db);

            _f.TokenManagement.GetLoginUrl().Returns("http://sso.com?token_type=authorize");

            var r = _f.Subject.InitiateSso(string.Empty);
            Assert.Equal(HttpStatusCode.Moved, r.StatusCode);
            Assert.Equal(new Uri($"http://sso.com/?token_type=authorize&redirect_uri={HttpUtility.UrlEncode("http://localhost/cpainproma/apps/ssoReturn?redirectUrl=")}"), r.Headers.Location);

            r = _f.Subject.InitiateSso("http://localhost/cpainproma/apps/system");
            Assert.Equal(HttpStatusCode.Moved, r.StatusCode);

            var returnUrl = new Uri($"http://localhost/cpainproma/apps/ssoReturn?redirectUrl={HttpUtility.UrlEncode("http://localhost/cpainproma/apps/system")}").ToString();
            Assert.Equal(new Uri($"http://sso.com/?token_type=authorize&redirect_uri={HttpUtility.UrlEncode(returnUrl)}"), r.Headers.Location);
        }
    }
}