using Inprotech.Integration.IPPlatform.Sso;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.Sso
{
    public class UserAccessTokenFacts
    {
        [Fact]
        public void StoreAndProvdeAccessToken()
        {
            var subject = new UserAccessToken();

            var token = Fixture.String();

            Assert.Null(subject.GetAccessToken());

            subject.Store(token);

            Assert.Equal(token, subject.GetAccessToken());
        }
    }
}