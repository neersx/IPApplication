using Inprotech.Web.Security;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class LicenseAuthorizationFacts
    {
        readonly ILicenses _licenses = Substitute.For<ILicenses>();

        [Theory]
        [InlineData(FailReason.ExceededUsers, "exceeded-users")]
        [InlineData(FailReason.NoLicenceFound, "no-licence-found")]
        public void ReturnsUnauthorizedWhenThereAreBlockingConditionsWithLicenses(FailReason reason, string expectedReasonCode)
        {
            var bob = new User();
            var unlicensedModule = Fixture.String();

            _licenses.Verify(bob.Id)
                     .Returns(new LicenseVerification
                     {
                         FailReason = reason,
                         IsBlocked = true,
                         UnlicensedModule = unlicensedModule
                     });

            var subject = new LicenseAuthorization(_licenses);

            AuthorizationResponse response;

            Assert.False(subject.TryAuthorize(bob, out response));
            Assert.False(response.Accepted);
            Assert.Equal(expectedReasonCode, response.FailReasonCode);
            Assert.Equal(unlicensedModule, response.Parameter);
        }

        [Theory]
        [InlineData(FailReason.ExceededUsers)]
        [InlineData(FailReason.NoLicenceFound)]
        public void ReturnsAuthorizedWhenLicenseConditionsAreNonBlocking(FailReason reason)
        {
            var bob = new User();
            var unlicensedModule = Fixture.String();

            _licenses.Verify(bob.Id)
                     .Returns(new LicenseVerification
                     {
                         FailReason = reason,
                         IsBlocked = false,
                         UnlicensedModule = unlicensedModule
                     });

            var subject = new LicenseAuthorization(_licenses);

            AuthorizationResponse response;

            Assert.True(subject.TryAuthorize(bob, out response));
            Assert.True(response.Accepted);
        }

        [Fact]
        public void ReturnsAuthorizedWhenThereAreNoIssuesWithLicenses()
        {
            var bob = new User();

            _licenses.Verify(bob.Id).Returns(new LicenseVerification());

            var subject = new LicenseAuthorization(_licenses);

            AuthorizationResponse response;

            Assert.True(subject.TryAuthorize(bob, out response));
            Assert.True(response.Accepted);
        }
    }
}