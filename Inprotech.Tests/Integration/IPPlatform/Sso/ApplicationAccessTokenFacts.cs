using CPA.IAM.Proxy;
using Inprotech.Integration.IPPlatform.Sso;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.Sso
{
    public class ApplicationAccessTokenFacts
    {
        [Fact]
        public void ReturnsTokenFromTokenProvider()
        {
            var token = Fixture.String();
            var tokenProvider = Substitute.For<ITokenProvider>();

            tokenProvider.GetClientAccessToken().Returns(token);

            var subject = new ApplicationAccessToken(tokenProvider);

            Assert.Equal(token, subject.GetAccessToken());

            tokenProvider.Received(1).GetClientAccessToken();
        }
    }
}