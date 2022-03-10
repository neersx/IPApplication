using System;
using System.Collections.Generic;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Security;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Web.IntegrationServer;
using InprotechKaizen.Model.Security;
using Microsoft.Owin;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.IntegrationServer
{
    public class SessionAccessInputResolverFacts : FactBase
    {
        readonly ICurrentOwinContext _currentOwinContext = Substitute.For<ICurrentOwinContext>();
        readonly IAuthSettings _authSettings = Substitute.For<IAuthSettings>();

        SessionAccessTokenInputResolver CreateSubject()
        {
            return new SessionAccessTokenInputResolver(_currentOwinContext, _authSettings);
        }

        [Fact]
        public async Task ShouldResolveCorrectIdAndSessionId()
        {
            var user = new User().In(Db);
            var subject = CreateSubject();
            var authUser = new AuthUser("user", user.Id, AuthenticationModeKeys.Forms, user.Id);
            var ticket = FormsAuthentication.Encrypt(new FormsAuthenticationTicket(1, "aaa", DateTime.Now, DateTime.Now.AddHours(1), false,
                                                                                   JsonConvert.SerializeObject(new AuthCookieData(authUser, false))));
            _authSettings.SessionCookieName.Returns("aaa");

            _currentOwinContext.OwinContext.Request.Returns(new OwinRequest
            {
                Headers =
                {
                    new KeyValuePair<string, string[]>("Cookie", new[]
                    {
                        new CookieHeaderValue("aaa", ticket).ToString()
                    })
                }
            });

            var result = subject.TryResolve(out var userId, out var sessionId);

            Assert.NotNull(result);
            Assert.True(result);
            Assert.Equal(user.Id, userId);
            Assert.Equal(user.Id, sessionId);
        }        
        
        [Fact]
        public async Task ShouldReturnFalseForNoCookie()
        {
            var user = new User().In(Db);
            var subject = CreateSubject();
            var authUser = new AuthUser("user", user.Id, AuthenticationModeKeys.Forms, user.Id);
            var ticket = FormsAuthentication.Encrypt(new FormsAuthenticationTicket(1, "aaa", DateTime.Now, DateTime.Now.AddHours(1), false,
                                                                                   JsonConvert.SerializeObject(new AuthCookieData(authUser, false))));
            _authSettings.SessionCookieName.Returns(String.Empty);

            _currentOwinContext.OwinContext.Request.Returns(new OwinRequest
            {
                Headers =
                {
                    new KeyValuePair<string, string[]>("Cookie", new string[0])
                }
            });

            var result = subject.TryResolve(out var userId, out var sessionId);
            
            Assert.False(result);
            Assert.Equal(int.MinValue, userId);
            Assert.Equal(long.MinValue, sessionId);
        }
    }
}