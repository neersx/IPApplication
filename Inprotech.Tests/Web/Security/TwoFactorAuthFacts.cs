using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Security.TwoFactorAuth;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class TwoFactorAuthFacts : FactBase
    {
        public class TwoFactorAuthFixture : IFixture<TwoFactorApp>
        {
            public TwoFactorAuthFixture()
            {
                Totp = Substitute.For<TwoFactorTotp>();
                AuthPreference = Substitute.For<IUserTwoFactorAuthPreference>();
                Subject = new TwoFactorApp(Totp, AuthPreference);
            }

            public ITwoFactorTotp Totp { get; set; }
            public IUserTwoFactorAuthPreference AuthPreference { get; set; }

            public TwoFactorApp Subject { get; }

            public TwoFactorAuthFixture WithKey(string key)
            {
                AuthPreference.ResolveEmailSecretKey(Arg.Any<int>()).Returns(key);
                AuthPreference.ResolveAppSecretKey(Arg.Any<int>()).Returns(key);
                return this;
            }
        }

        public class TwoFactorAppFacts : FactBase
        {
            [Fact]
            public async Task CorrectCodeVerifies()
            {
                var fixture = new TwoFactorAuthFixture()
                    .WithKey("key");

                var subject = fixture.Subject;

                var password = Fixture.String();

                var bob = CreateUser("bob", password, true);
                var authCode = fixture.Totp.OneTimePassword(30, "key").ComputeTotp();
                var verification = await subject.VerifyForUser(bob, authCode);

                Assert.True(verification);
            }
            
            [Fact]
            public async Task IncorrectCodeFailsVerification()
            {
                var fixture = new TwoFactorAuthFixture()
                    .WithKey("key");

                var subject = fixture.Subject;

                var password = Fixture.String();

                var bob = CreateUser("bob", password, true);
                var authCode = fixture.Totp.OneTimePassword(30, "key").ComputeTotp() + "INCORRECT";
                var verification = await subject.VerifyForUser(bob, authCode);
                
                Assert.False(verification);
            }
        }

    }
}
