using System.Threading.Tasks;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Security.Authorization;
using Inprotech.Tests.Extensions;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Security.Authorization
{
    public class UserResetPasswordEmailRequiredHandlerFacts
    {
        [Fact]
        public async Task ScheduleNotificationJobForResetPassword()
        {
            var jobServer = Substitute.For<IIntegrationServerClient>();

            var message = new UserResetPasswordMessage();

            var subject = new UserResetPasswordEmailRequiredHandler(jobServer);

            await subject.HandleAsync(message);

            jobServer.Received(1)
                     .Post("api/jobs/UserResetPasswordEmailRequired/start", message)
                     .IgnoreAwaitForNSubstituteAssertion();
        }
    }

    public class UserResetPasswordEmailRequiredJobFacts
    {
        [Fact]
        public void ReturnsNotifyAllConcernedActivity()
        {
            var original = new UserResetPasswordMessage
            {
                IdentityId = Fixture.Integer(),
                UserEmail = Fixture.String(),
                Username = Fixture.String(),
                EmailBody = Fixture.String(),
                UserResetPassword = Fixture.String()
            };

            var r = new UserResetPasswordEmailRequiredHandlerPerformJob()
                .GetJob(JObject.FromObject(original));

            Assert.Equal("UserResetPasswordEmailRequired.EmailUser", r.TypeAndMethod());

            var arg = (UserResetPasswordMessage) r.Arguments[0];

            Assert.Equal(original.Username, arg.Username);
            Assert.Equal(original.UserEmail, arg.UserEmail);
            Assert.Equal(original.IdentityId, arg.IdentityId);
            Assert.Equal(original.EmailBody, arg.EmailBody);
            Assert.Equal(original.UserResetPassword, arg.UserResetPassword);
        }
    }
}