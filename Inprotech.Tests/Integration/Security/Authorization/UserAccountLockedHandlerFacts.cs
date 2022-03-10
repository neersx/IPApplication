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
    public class UserAccountLockedHandlerFacts
    {
        [Fact]
        public async Task ScheduleNotificationJobForLockedAccount()
        {
            var jobServer = Substitute.For<IIntegrationServerClient>();

            var lockedAccount = new UserAccountLockedMessage();

            var subject = new UserAccountLockedHandler(jobServer);

            await subject.HandleAsync(lockedAccount);

            jobServer.Received(1)
                     .Post("api/jobs/UserAccountLocked/start", lockedAccount)
                     .IgnoreAwaitForNSubstituteAssertion();
        }
    }

    public class UserAccountLockedNotifierJobFacts
    {
        [Fact]
        public void ReturnsNotifyAllConcernedActivity()
        {
            var original = new UserAccountLockedMessage
            {
                Username = Fixture.String(),
                UserEmail = Fixture.String(),
                DisplayName = Fixture.String(),
                LockedLocal = Fixture.Today(),
                LockedUtc = Fixture.TodayUtc(),
                IdentityId = Fixture.Integer()
            };

            var r = new UserAccountLockedHandlerPerformJob()
                .GetJob(JObject.FromObject(original));

            Assert.Equal("UserAccountLocked.NotifyAllConcerned", r.TypeAndMethod());

            var arg = (UserAccountLockedMessage) r.Arguments[0];

            Assert.Equal(original.Username, arg.Username);
            Assert.Equal(original.DisplayName, arg.DisplayName);
            Assert.Equal(original.UserEmail, arg.UserEmail);
            Assert.Equal(original.LockedLocal, arg.LockedLocal);
            Assert.Equal(original.LockedUtc, arg.LockedUtc);
            Assert.Equal(original.IdentityId, arg.IdentityId);
        }
    }
}