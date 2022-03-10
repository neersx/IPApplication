using Autofac;
using Dependable;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Security.Authorization;
using Inprotech.Tests.Extensions;
using NSubstitute;
using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace Inprotech.Tests.Integration.Security.Authorization
{
    public class UserResetPasswordEmailRequiredFacts
    {
        [Collection("Dependable")]
        public class NotifyAllConcernedMethod
        {
            readonly UserResetPasswordEmailRequiredFixture _fixture = new UserResetPasswordEmailRequiredFixture();

            readonly UserResetPasswordMessage _message = new UserResetPasswordMessage
            {
                IdentityId = Fixture.Integer(),
                UserEmail = Fixture.String(),
                Username = Fixture.String(),
                EmailBody = Fixture.String(),
                UserResetPassword = Fixture.String()
            };

            [Fact]
            public async Task ProvideUserResetPasswordLink()
            {
                var activity = await _fixture.Subject.EmailUser(_message);

                _fixture.Execute(activity);

                _fixture.SiteControls.Received(1).Read<string>(SiteControls.WorkBenchAdministratorEmail);

                _fixture.EmailNotifier.Received(1)
                        .Send(Arg.Is<Notification>(
                                                   _ =>
                                                       _.EmailRecipient.Single().Email == _message.UserEmail
                                                       && _.Subject == _message.UserResetPassword
                                                       && _.Body.TextContains(_message.EmailBody)))
                        .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class UserResetPasswordEmailRequiredFixture : IFixture<UserResetPasswordEmailRequired>
        {
            public UserResetPasswordEmailRequiredFixture()
            {
                EmailNotifier = Substitute.For<IEmailNotification>();

                SiteControls = Substitute.For<ISiteControlReader>();
                SiteControls.Read<string>(Inprotech.Infrastructure.SiteControls.WorkBenchAdministratorEmail).Returns("support@customer-domain.com");

                Subject = new UserResetPasswordEmailRequired(EmailNotifier, SiteControls);
            }

            public IEmailNotification EmailNotifier { get; set; }

            public ISiteControlReader SiteControls { get; set; }

            public UserResetPasswordEmailRequired Subject { get; }

            ILifetimeScope WireUp(DependableActivity.CompletedActivity completedActivity)
            {
                var builder = new ContainerBuilder();
                builder.RegisterInstance(EmailNotifier).As<IEmailNotification>();
                builder.RegisterInstance(SiteControls).As<ISiteControlReader>();
                builder.RegisterInstance(Subject).As<UserResetPasswordEmailRequired>();
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
}
