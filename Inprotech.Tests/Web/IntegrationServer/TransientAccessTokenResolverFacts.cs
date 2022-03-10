using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.IntegrationServer;
using Microsoft.Owin;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.IntegrationServer
{
    public class TransientAccessTokenResolverFacts : FactBase
    {
        readonly ICurrentOwinContext _currentOwinContext = Substitute.For<ICurrentOwinContext>();
        readonly IAuthSettings _authSettings = Substitute.For<IAuthSettings>();

        TransientAccessTokenResolver CreateSubject()
        {
            return new TransientAccessTokenResolver(_currentOwinContext);
        }

        [Fact]
        public async Task ShouldResolveCorrectTransientAccessToken()
        {
            var subject = CreateSubject();
            var token = Guid.NewGuid().ToString();

            _currentOwinContext.OwinContext.Request.Returns(new OwinRequest
            {
                Headers =
                {
                    new KeyValuePair<string, string[]>("X-ApiKey", new[]
                    {
                        token
                    })
                }
            });

            var result = subject.TryResolve(out var tToken);

            Assert.True(result);
            Assert.Equal(token, tToken.ToString());
        }

        [Fact]
        public async Task ShouldReturnFalseForNoCookie()
        {
            var subject = CreateSubject();

            _authSettings.SessionCookieName.Returns(string.Empty);

            _currentOwinContext.OwinContext.Request.Returns(new OwinRequest());

            var result = subject.TryResolve(out var tToken);

            Assert.False(result);
        }
    }
}