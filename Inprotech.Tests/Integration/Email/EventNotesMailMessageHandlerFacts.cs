using System.Threading.Tasks;
using Inprotech.Contracts.Messages;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Email;
using Inprotech.Tests.Extensions;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Email 
{
    public class EventNotesMailMessageHandlerFacts
    {
        [Fact]
        public async Task ScheduleNotificationJobForEventNotesMail()
        {
            var jobServer = Substitute.For<IIntegrationServerClient>();

            var message = new EventNotesMailMessage();

            var subject = new EventNotesMailMessageHandler(jobServer);

            await subject.HandleAsync(message);

            jobServer.Received(1)
                     .Post("api/jobs/EventNotesMailMessageExecution/start", message)
                     .IgnoreAwaitForNSubstituteAssertion();
        }
    }

    public class EventNotesMailMessageJobFacts
    {
        [Fact]
        public void ReturnsNotifyAllConcernedActivity()
        {
            var original = new EventNotesMailMessage
            {
                Subject = Fixture.String("EmailSubject"),
                To = Fixture.String("EmailTo"),
                Cc = Fixture.String("EmailCC"),
                From = Fixture.String("EmailFrom"),
                Body = Fixture.String("EmailBody")
            };

            var r = new EventNotesMailMessagePerformJob()
                .GetJob(JObject.FromObject(original));

            Assert.Equal("EventNotesMailMessageExecution.EmailUser", r.TypeAndMethod());

            var arg = (EventNotesMailMessage) r.Arguments[0];

            Assert.Equal(original.Subject, arg.Subject);
            Assert.Equal(original.To, arg.To);
            Assert.Equal(original.Cc, arg.Cc);
            Assert.Equal(original.From, arg.From);
            Assert.Equal(original.Body, arg.Body);
        }
    }
}
