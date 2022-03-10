using Autofac;
using Dependable;
using Inprotech.Infrastructure;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Properties;
using Inprotech.Integration.Security.Authorization;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace Inprotech.Tests.Integration.Security.Authorization
{
    public class ExpiringPasswordFacts
    {
        [Collection("Dependable")]
        public class CheckAndNotifyMethod
        {
            readonly ExpiringPasswordFixture _fixture = new ExpiringPasswordFixture();

            [Fact]
            public async Task NotifiesUserForExpiringPassword()
            {
                _fixture.SiteControls.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(true);
                _fixture.SiteControls.Read<int?>(SiteControls.PasswordExpiryDuration).Returns(10);

                _fixture.UserPasswordExpiryValidator.Resolve(10)
                        .Returns(new[]
                                 {
                                     new UserPasswordExpiryDetails
                                     {
                                         Id = 1,
                                         Email = "someone@cpaglobal.com",
                                         EmailBody = Fixture.String()
                                     },
                                     new UserPasswordExpiryDetails
                                     {
                                         Id = 3,
                                         Email = "someone@cpaglobal.com",
                                         EmailBody = Fixture.String()
                                     }
                                 });

                var activity = await _fixture.Subject.CheckAndNotify();
                _fixture.Execute(activity);

                await _fixture.UserPasswordExpiryValidator.Received(1).Resolve(10);
                _fixture.EmailNotifier.Received(2).Send(Arg.Is<Notification>(
                                                                             _ =>
                                                                                 _.EmailRecipient.Single().Email == "someone@cpaglobal.com"
                                                                                 && _.Subject == Alerts.PasswordExpiry_Title
                                                                                 && !_.IsBodyHtml))
                        .IgnoreAwaitForNSubstituteAssertion();

            }

            [Fact]
            public async Task NotifiesUserForExpiringPasswordWithHtml()
            {
                _fixture.SiteControls.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(true);
                _fixture.SiteControls.Read<int?>(SiteControls.PasswordExpiryDuration).Returns(10);

                _fixture.UserPasswordExpiryValidator.Resolve(10)
                        .Returns(new[]
                        {
                            new UserPasswordExpiryDetails
                            {
                                Id = 1,
                                Email = "someone@cpaglobal.com",
                                EmailBody = Fixture.String("Text<b>In</b>")
                            },
                            new UserPasswordExpiryDetails
                            {
                                Id = 3,
                                Email = "someone@cpaglobal.com",
                                EmailBody = Fixture.String("Text<b>In</b>")
                            }
                        });

                var activity = await _fixture.Subject.CheckAndNotify();
                _fixture.Execute(activity);

                await _fixture.UserPasswordExpiryValidator.Received(1).Resolve(10);
                _fixture.EmailNotifier.Received(2).Send(Arg.Is<Notification>(
                                                                             _ =>
                                                                                 _.EmailRecipient.Single().Email == "someone@cpaglobal.com"
                                                                                 && _.Subject == Alerts.PasswordExpiry_Title
                                                                                 && _.IsBodyHtml))
                        .IgnoreAwaitForNSubstituteAssertion();

            }

            [Fact]
            public async Task ReturnsImmediatelyWhenEnforcePasswordSiteControlIsFalse()
            {
                var activity = await _fixture.Subject.CheckAndNotify();

                _fixture.Execute(activity);

                await _fixture.UserPasswordExpiryValidator.DidNotReceive().Resolve(Arg.Any<int>());
            }

            [Fact]
            public async Task ReturnsImmediatelyWhenExpiryDurationSiteControlHasNegativeValue()
            {
                _fixture.SiteControls.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(true);
                _fixture.SiteControls.Read<int?>(SiteControls.PasswordExpiryDuration).Returns(-1);

                var activity = await _fixture.Subject.CheckAndNotify();

                _fixture.Execute(activity);

                await _fixture.UserPasswordExpiryValidator.DidNotReceive().Resolve(Arg.Any<int>());
            }

            [Fact]
            public async Task ReturnsEmptyWhenNoUsersToNotify()
            {
                _fixture.SiteControls.Read<bool>(SiteControls.EnforcePasswordPolicy).Returns(true);
                _fixture.SiteControls.Read<int?>(SiteControls.PasswordExpiryDuration).Returns(10);

                var activity = await _fixture.Subject.CheckAndNotify();

                _fixture.Execute(activity);

                await _fixture.EmailNotifier.DidNotReceive().Send(Arg.Any<Notification>());
            }
        }
        public class ExpiringPasswordFixture : IFixture<ExpiringPassword>
        {
            public ExpiringPasswordFixture()
            {
                UserPasswordExpiryValidator = Substitute.For<IUserPasswordExpiryValidator>();

                EmailNotifier = Substitute.For<IEmailNotification>();

                SiteControls = Substitute.For<ISiteControlReader>();
                SiteControls.Read<string>(Inprotech.Infrastructure.SiteControls.ProductSupportEmail).Returns("inprotech.support@cpaglobal.com");

                Subject = new ExpiringPassword(EmailNotifier, SiteControls, UserPasswordExpiryValidator);
            }

            public IUserPasswordExpiryValidator UserPasswordExpiryValidator { get; set; }

            public IEmailNotification EmailNotifier { get; set; }

            public ISiteControlReader SiteControls { get; set; }

            public ExpiringPassword Subject { get; }

            ILifetimeScope WireUp(DependableActivity.CompletedActivity completedActivity)
            {
                var builder = new ContainerBuilder();
                builder.RegisterInstance(UserPasswordExpiryValidator).As<IUserPasswordExpiryValidator>();
                builder.RegisterInstance(EmailNotifier).As<IEmailNotification>();
                builder.RegisterInstance(SiteControls).As<ISiteControlReader>();
                builder.RegisterInstance(Subject).As<ExpiringPassword>();
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
