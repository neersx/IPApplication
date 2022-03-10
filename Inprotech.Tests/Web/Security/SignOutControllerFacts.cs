using System;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using System.Web.Http.Hosting;
using System.Web.Security;
using CPA.SingleSignOn.Client.Services;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Security;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class SignOutControllerFacts
    {
        public SignOutControllerFacts()
        {
            _settings = Substitute.For<IAuthSettings>();
            _tokenManagementService = Substitute.For<ITokenManagementService>();
            _userIdentityAccessManager = Substitute.For<IUserIdentityAccessManager>();
            _adfsAuthenticator = Substitute.For<IAdfsAuthenticator>();
            var logger = Substitute.For<ILogger<SignOutController>>();

            _request = new HttpRequestMessage(HttpMethod.Get, "http://www.abc.com/parent/apps/signout");
            _request.Properties[HttpPropertyKeys.HttpConfigurationKey] = new HttpConfiguration();

            _settings.SessionCookieName.Returns("a");
            _settings.SessionCookiePath.Returns("/a/b/c");
            _settings.SessionCookieDomain.Returns("localhost");
            _settings.SignInUrl.Returns("parent/signin");
            _settings.ParentPath.Returns("CPAInproma");

            _subject = new SignOutController(_settings, _tokenManagementService, _userIdentityAccessManager, _adfsAuthenticator, logger)
            {
                Request = _request
            };
        }

        readonly IAuthSettings _settings;
        readonly ITokenManagementService _tokenManagementService;
        readonly IUserIdentityAccessManager _userIdentityAccessManager;
        readonly SignOutController _subject;
        readonly IAdfsAuthenticator _adfsAuthenticator;
        readonly HttpRequestMessage _request;

        void SetRequestAndCookie(string authMode = AuthenticationModeKeys.Sso, string cookiePath = "/a/b/c", string cookieDomain = "localhost")
        {
            var ticket = new FormsAuthenticationTicket(1, "a", DateTime.Now, DateTime.Now.AddHours(1), false,
                                                       JsonConvert.SerializeObject(new AuthCookieData(new AuthUser("user", 1, authMode, 1), false)), cookiePath);

            var encryptedTicket = FormsAuthentication.Encrypt(ticket);

            _request.Headers.Add("Cookie", new[]
            {
                new CookieHeaderValue("a", encryptedTicket)
                {
                    Path = cookiePath,
                    Domain = cookieDomain
                }.ToString()
            });
        }

        [Fact]
        public async Task ShouldEndSessionIfCookieDataFound()
        {
            SetRequestAndCookie();
            var r = await _subject.Get();

            Assert.Equal(HttpStatusCode.Redirect, r.StatusCode);
            Assert.Equal("http://www.abc.com/parent/signin", r.Headers.Location.ToString());

            _userIdentityAccessManager.Received(1).EndSession(Arg.Any<long>())
                                      .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldNotRedirectUserToLogoutFromSsoIfSigninWasNotSso()
        {
            _settings.SsoEnabled.Returns(true);
            SetRequestAndCookie(AuthenticationModeKeys.Forms);

            var ssoUrl = "http://sso.com/logout";
            _tokenManagementService.GetLogoutUrl().Returns(ssoUrl);

            var r = await _subject.Get();

            _userIdentityAccessManager.Received(1).EndSession(Arg.Any<long>())
                                      .IgnoreAwaitForNSubstituteAssertion();

            Assert.Equal(HttpStatusCode.Redirect, r.StatusCode);
            Assert.Equal("http://www.abc.com/parent/signin", r.Headers.Location.ToString());
        }

        [Fact]
        public async Task ShouldRedirectUserToLogoutFromAdfs()
        {
            _settings.AdfsEnabled.Returns(true);
            SetRequestAndCookie(AuthenticationModeKeys.Adfs);

            var adfsUrl = "http://sso.com/adfs/ls/?wa=wsignout1.0&wreply=http://www.abc.com/parent/signin";
            _adfsAuthenticator.GetLogoutUrl(Arg.Any<string>()).Returns(adfsUrl);

            var r = await _subject.Get();

            _userIdentityAccessManager.Received(1).EndSession(Arg.Any<long>())
                                      .IgnoreAwaitForNSubstituteAssertion();

            Assert.Equal(HttpStatusCode.Redirect, r.StatusCode);
            Assert.Equal(adfsUrl, r.Headers.Location.ToString());
        }

        [Fact]
        public async Task ShouldRedirectUserToLogoutFromSso()
        {
            _settings.SsoEnabled.Returns(true);
            SetRequestAndCookie();

            var ssoUrl = "http://sso.com/logout";
            var userIdentityAccessData = new UserIdentityAccessData("sessionId", "accessToken", "refreshToken");
            _tokenManagementService.GetLogoutUrl().Returns(ssoUrl);
            _userIdentityAccessManager.GetSigninData(Arg.Any<long>(), Arg.Any<int>(), Arg.Any<string>())
                                      .Returns((userIdentityAccessData, null));

            var r = await _subject.Get();

            _userIdentityAccessManager.Received(1).EndSession(Arg.Any<long>())
                                      .IgnoreAwaitForNSubstituteAssertion();

            _tokenManagementService.Received(1).Revoke(userIdentityAccessData.AccessToken, userIdentityAccessData.SessionId);

            Assert.Equal(HttpStatusCode.Redirect, r.StatusCode);
            Assert.Equal(new Uri($"{ssoUrl}?resumeUrl={HttpUtility.UrlEncode("http://www.abc.com/parent/signin")}").ToString(), r.Headers.Location.ToString());
        }

        [Fact]
        public async Task ShouldRedirectUserToLogoutFromSsoEvenIfRevokeFails()
        {
            _settings.SsoEnabled.Returns(true);
            SetRequestAndCookie();

            var ssoUrl = "http://sso.com/logout";
            _tokenManagementService.GetLogoutUrl().Returns(ssoUrl);
            _userIdentityAccessManager.GetSigninData(Arg.Any<long>(), Arg.Any<int>(), Arg.Any<string>())
                                      .Returns((new UserIdentityAccessData("sessionId", "accessToken", "refreshToken"), null));
            _tokenManagementService.When(_ => _.Revoke(Arg.Any<string>(), Arg.Any<string>())).Throw(new Exception("Session already invalidated. Can not revoke!!"));

            var r = await _subject.Get();

            Assert.Equal(HttpStatusCode.Redirect, r.StatusCode);
            Assert.Equal(new Uri($"{ssoUrl}?resumeUrl={HttpUtility.UrlEncode("http://www.abc.com/parent/signin")}").ToString(), r.Headers.Location.ToString());
        }

        [Fact]
        public async Task ShouldRedirectUserToParentsHome()
        {
            SetRequestAndCookie();
            var r = await _subject.Get();

            Assert.Equal(HttpStatusCode.Redirect, r.StatusCode);
            Assert.Equal("http://www.abc.com/parent/signin", r.Headers.Location.ToString());
            await _userIdentityAccessManager.DidNotReceive().EndSession(Arg.Any<int>());
        }

        [Fact]
        public async Task ShouldSend200ResponseForOldWeb()
        {
            SetRequestAndCookie();
            var r = await _subject.Get("InprotechWeb");

            Assert.Equal(HttpStatusCode.OK, r.StatusCode);
            Assert.Equal("http://www.abc.com/parent/signin#/?goto=http://www.abc.com:80/CPAInproma/default.aspx", r.Headers.Location.ToString());
            await _userIdentityAccessManager.DidNotReceive().EndSession(Arg.Any<int>());
        }
    }
}