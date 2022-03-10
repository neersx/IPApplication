using System.Linq;
using System.Threading.Tasks;
using Autofac;
using Dependable;
using Inprotech.Contracts.Messages;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.Email;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Security.Authorization;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Email
{
    public class EventNotesMailMessageExecutionFacts
    {
        [Collection("Dependable")]
        public class NotifyAllConcernedMethod
        {
            readonly EventNotesMailMessageExecutionFixture _fixture = new EventNotesMailMessageExecutionFixture();

            readonly EventNotesMailMessage _message = new EventNotesMailMessage
            {
                From = Fixture.String("EmailFrom"),
                To = Fixture.String("EmailTo"),
                Cc = Fixture.String("EmailCc"),
                Body = Fixture.String("EmailBody"),
                Subject = Fixture.String("EmailSubject")
            };

            [Fact]
            public async Task ProvideUserWithEmailEventNotesUpdate()
            {
                var activity = await _fixture.Subject.EmailUser(_message);

                _fixture.Execute(activity);

                _fixture.EmailNotifier.Received(1)
                        .Send(Arg.Is<Notification>(
                                                   _ =>
                                                       _.EmailRecipient.Single().Email == _message.To
                                                       && _.Subject == _message.Subject
                                                       && _.Body.TextContains(_message.Body)))
                        .IgnoreAwaitForNSubstituteAssertion();
            }
        }
    }

    public class EventNotesMailMessageExecutionFixture : IFixture< EventNotesMailMessageExecution>
    {
        public EventNotesMailMessageExecutionFixture()
        {
            EmailNotifier = Substitute.For<IEmailNotification>();

            Subject = new EventNotesMailMessageExecution(EmailNotifier);
        }

        public IEmailNotification EmailNotifier { get; set; }

        public EventNotesMailMessageExecution Subject { get; }

        ILifetimeScope WireUp(DependableActivity.CompletedActivity completedActivity)
        {
            var builder = new ContainerBuilder();
            builder.RegisterInstance(EmailNotifier).As<IEmailNotification>();
            builder.RegisterInstance(Subject).As<EventNotesMailMessageExecution>();
            builder.RegisterType<NullActivity>().AsSelf();
            builder.RegisterInstance(completedActivity).AsSelf();
            return builder.Build();
        }

        public void Execute(Activity activity)
        {
            DependableActivity.Execute(activity, WireUp, true);
        }
    }
}
