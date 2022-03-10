using System.Net;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Security;
using InprotechKaizen.Model.Components.Security.SingleSignOn;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class SsoLookupControllerFacts
    {
        public class ControllerFacts
        {
            readonly SsoLookupControllerFixture _f = new SsoLookupControllerFixture();

            [Theory]
            [InlineData(SsoUserLinkResultType.NoMatchingInprotechUser, "no-matching-inprotech-user")]
            [InlineData(SsoUserLinkResultType.Success, "success")]
            public async Task ShouldUnlinkTheUser(SsoUserLinkResultType response, string expected)
            {
                var id = Fixture.Integer();

                _f.SsoUserIdentifier.UnlinkUser(id)
                  .Returns(response);

                var r = await _f.Subject.Unlink(id);

                Assert.Equal(expected, r.Code);
            }

            [Fact]
            public void AlwaysReturnsNotFound()
            {
                var r = _f.Subject.ByEmail(Fixture.String());

                Assert.Equal(HttpStatusCode.NotFound, r.StatusCode);
            }

            [Fact]
            public void AlwaysReturnsSuccessForLinkingUser()
            {
                var result = _f.Subject.Link(Fixture.Integer());

                Assert.NotNull(result);
                Assert.Equal("success", result.Code);
            }

            [Fact]
            public void ControllerSecuredByMaintainUserTask()
            {
                var r = TaskSecurity.Secures<SsoLookupController>(
                                                                  ApplicationTask.MaintainUser,
                                                                  ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify);

                Assert.True(r);
            }

            [Fact]
            public void ShouldPreventSearchingWhenEmailIsNotProvided()
            {
                var r = _f.Subject.ByEmail(null);

                Assert.Equal(HttpStatusCode.BadRequest, r.StatusCode);
            }
        }

        public class SsoLookupControllerFixture : IFixture<SsoLookupController>
        {
            public SsoLookupControllerFixture()
            {
                Subject = new SsoLookupController(SsoUserIdentifier);
            }

            public ISsoUserIdentifier SsoUserIdentifier { get; } = Substitute.For<ISsoUserIdentifier>();

            public SsoLookupController Subject { get; }
        }
    }
}