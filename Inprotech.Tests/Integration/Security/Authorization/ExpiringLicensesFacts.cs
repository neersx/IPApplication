using System;
using System.Linq;
using System.Threading.Tasks;
using Autofac;
using Dependable;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Notifications.Security;
using Inprotech.Infrastructure.Policy;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Properties;
using Inprotech.Integration.Security.Authorization;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Security.Authorization
{
    public class ExpiringLicensesFacts
    {
        [Collection("Dependable")]
        public class CheckAndNotifyMethod
        {
            readonly ExpiringLicensesFixture _fixture = new ExpiringLicensesFixture();

            [Fact]
            public async Task NotifiesUserAdministratorsForExpiringLicenses()
            {
                var expiringModule1 = Fixture.String();
                var expiringModule2 = Fixture.String();

                _fixture.Licenses.Expiring()
                        .Returns(new[]
                        {
                            new ExpiringLicense
                            {
                                ExpiryDate = Fixture.FutureDate(),
                                Module = expiringModule1
                            },
                            new ExpiringLicense
                            {
                                ExpiryDate = Fixture.FutureDate(),
                                Module = expiringModule2
                            }
                        });

                _fixture.UserAdministrators.Resolve()
                        .Returns(new[]
                        {
                            new UserEmail
                            {
                                Email = "someone@cpaglobal.com"
                            }
                        });

                var activity = await _fixture.Subject.CheckAndNotify();

                _fixture.Execute(activity);

                _fixture.UserAdministrators.Received(1).Resolve();

                _fixture.SiteControls.Received(1).Read<string>(SiteControls.ProductSupportEmail);

                _fixture.EmailNotifier.Received(1)
                        .Send(Arg.Is<Notification>(
                                                   _ =>
                                                       _.EmailRecipient.Single().Email == "someone@cpaglobal.com"
                                                       && _.Subject == Alerts.LicenseExpiry_Title
                                                       && _.Body.TextContains(expiringModule1)
                                                       && _.Body.TextContains(expiringModule2)))
                        .IgnoreAwaitForNSubstituteAssertion();

                _fixture.PopupNotifier.Received(1)
                        .Send(Arg.Is<Notification>(
                                                   _ =>
                                                       _.EmailRecipient.Single().Email == "someone@cpaglobal.com"
                                                       && _.Subject == Alerts.LicenseExpiry_Title
                                                       && _.Body.TextContains(expiringModule1)
                                                       && _.Body.TextContains(expiringModule2)))
                        .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ReturnsImmediatelyForNonLicenseExpiry()
            {
                var activity = await _fixture.Subject.CheckAndNotify();

                _fixture.Execute(activity);

                _fixture.UserAdministrators.DidNotReceive().Resolve();
            }

            [Fact]
            public async Task ThrowsErrorWhenNoUserAdministratorsToNotifyTo()
            {
                _fixture.Licenses.Expiring()
                        .Returns(new[]
                        {
                            new ExpiringLicense
                            {
                                ExpiryDate = Fixture.FutureDate(),
                                Module = Fixture.String()
                            }
                        });

                await Assert.ThrowsAsync<Exception>(async () => await _fixture.Subject.CheckAndNotify());
            }
        }

        public class ExpiringLicensesFixture : IFixture<ExpiringLicenses>
        {
            public ExpiringLicensesFixture()
            {
                Licenses = Substitute.For<ILicenses>();

                UserAdministrators = Substitute.For<IUserAdministrators>();

                EmailNotifier = Substitute.For<IEmailNotification>();

                PopupNotifier = Substitute.For<IPopupNotification>();

                SiteDateFormat = Substitute.For<ISiteDateFormat>();
                SiteDateFormat.Resolve().Returns("dd-MMM-yyyy");

                SiteControls = Substitute.For<ISiteControlReader>();
                SiteControls.Read<string>(Inprotech.Infrastructure.SiteControls.ProductSupportEmail).Returns("inprotech.support@cpaglobal.com");

                Subject = new ExpiringLicenses(Licenses, UserAdministrators, EmailNotifier, PopupNotifier, SiteDateFormat, SiteControls);
            }

            public ILicenses Licenses { get; set; }

            public IUserAdministrators UserAdministrators { get; set; }

            public IEmailNotification EmailNotifier { get; set; }

            public IPopupNotification PopupNotifier { get; set; }

            public ISiteDateFormat SiteDateFormat { get; set; }

            public ISiteControlReader SiteControls { get; set; }

            public ExpiringLicenses Subject { get; }

            ILifetimeScope WireUp(DependableActivity.CompletedActivity completedActivity)
            {
                var builder = new ContainerBuilder();
                builder.RegisterInstance(Licenses).As<ILicenses>();
                builder.RegisterInstance(UserAdministrators).As<IUserAdministrators>();
                builder.RegisterInstance(PopupNotifier).As<IPopupNotification>();
                builder.RegisterInstance(EmailNotifier).As<IEmailNotification>();
                builder.RegisterInstance(SiteDateFormat).As<ISiteDateFormat>();
                builder.RegisterInstance(SiteControls).As<ISiteControlReader>();
                builder.RegisterInstance(Subject).As<ExpiringLicenses>();
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