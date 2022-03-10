using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Autofac;
using Dependable;
using Inprotech.Contracts.DocItems;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Notifications.Security;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Properties;
using Inprotech.Integration.Security.Authorization;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Security.Authorization
{
    public class UserAccountLockedFacts
    {
        [Collection("Dependable")]
        public class NotifyAllConcernedMethod : FactBase
        {
            UserAccountLockedFixture _fixture;

            readonly UserAccountLockedMessage _lockedAccount = new UserAccountLockedMessage
            {
                DisplayName = Fixture.String(),
                IdentityId = Fixture.Integer(),
                LockedLocal = Fixture.Today(),
                LockedUtc = Fixture.TodayUtc(),
                UserEmail = Fixture.String(),
                Username = Fixture.String()
            };

            [Fact]
            public async Task NotifiesUserAdministratorsForUserAccountLocked()
            {
                _fixture = new UserAccountLockedFixture(Db);
                _fixture.UserAdministrators.Resolve(_lockedAccount.IdentityId)
                        .Returns(new[]
                        {
                            new UserEmail
                            {
                                Email = "someone@cpaglobal.com"
                            }
                        });

                var dataItem = new DocItem {Name = KnownEmailDocItems.UserAccountLocked, Sql = "Select ABC", EntryPointUsage = 1}.In(Db);
                var docItemResult = new UserEmailContent
                {
                    Subject = Fixture.String(),
                    Body = Fixture.String("text<b>text</b>")
                };
                var result = new DataSet();
                result.Tables.Add(new DataTable());
                result.Tables[0].Columns.Add("Subject");
                result.Tables[0].Columns.Add("Body");
                var row = result.Tables[0].NewRow();
                row["Subject"] = docItemResult.Subject;
                row["Body"] = docItemResult.Body;
                result.Tables[0].Rows.Add(row);
                _fixture.DocItemRunner.Run(Arg.Any<int>(), Arg.Any<Dictionary<string, object>>()).Returns(result);

                var activity = await _fixture.Subject.NotifyAllConcerned(_lockedAccount);

                _fixture.Execute(activity);

                _fixture.UserAdministrators.Received(1).Resolve(_lockedAccount.IdentityId);

                _fixture.SiteControls.Received(1).Read<string>(SiteControls.WorkBenchAdministratorEmail);

                _fixture.DocItemRunner.Received(1).Run(dataItem.Id, Arg.Any<Dictionary<string, object>>());

                _fixture.EmailNotifier.Received(1)
                        .Send(Arg.Is<Notification>(
                                                   _ =>
                                                       _.EmailRecipient.Single().Email == "someone@cpaglobal.com"
                                                       && _.Subject == docItemResult.Subject
                                                       && _.Body.TextContains(docItemResult.Body)
                                                       && _.Body.TextContains(_lockedAccount.Username)
                                                       && _.Body.TextContains(_lockedAccount.UserEmail)
                                                       && _.Body.TextContains(_lockedAccount.LockedUtc.ToString("U"))
                                                       && _.Body.TextContains(_lockedAccount.LockedLocal.ToString("F"))
                                                       && _.Body.TextContains(_lockedAccount.DisplayName)
                                                       && _.IsBodyHtml))
                        .IgnoreAwaitForNSubstituteAssertion();

                _fixture.PopupNotifier.Received(1)
                        .Send(Arg.Is<Notification>(
                                                   _ =>
                                                       _.EmailRecipient.Single().Email == "someone@cpaglobal.com"
                                                       && _.Subject == docItemResult.Subject
                                                       && _.Body.TextContains(docItemResult.Body)
                                                       && _.Body.TextContains(_lockedAccount.Username)
                                                       && _.Body.TextContains(_lockedAccount.UserEmail)
                                                       && _.Body.TextContains(_lockedAccount.LockedUtc.ToString("U"))
                                                       && _.Body.TextContains(_lockedAccount.LockedLocal.ToString("F"))
                                                       && _.Body.TextContains(_lockedAccount.DisplayName)))
                        .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task NotifiesUserAdministratorsForUserAccountLockedWithDefaultContent()
            {
                _fixture = new UserAccountLockedFixture(Db);
                _fixture.UserAdministrators.Resolve(_lockedAccount.IdentityId)
                        .Returns(new[]
                        {
                            new UserEmail
                            {
                                Email = "someone@cpaglobal.com"
                            }
                        });

                var dataItem = new DocItem {Name = KnownEmailDocItems.UserAccountLocked, Sql = "Select ABC", EntryPointUsage = 1}.In(Db);
                var result = new DataSet();
                _fixture.DocItemRunner.Run(Arg.Any<int>(), Arg.Any<Dictionary<string, object>>()).Returns(result);

                var activity = await _fixture.Subject.NotifyAllConcerned(_lockedAccount);

                _fixture.Execute(activity);

                _fixture.UserAdministrators.Received(1).Resolve(_lockedAccount.IdentityId);

                _fixture.SiteControls.Received(1).Read<string>(SiteControls.WorkBenchAdministratorEmail);

                _fixture.DocItemRunner.Received(1).Run(dataItem.Id, Arg.Any<Dictionary<string, object>>());

                _fixture.EmailNotifier.Received(1)
                        .Send(Arg.Is<Notification>(
                                                   _ =>
                                                       _.EmailRecipient.Single().Email == "someone@cpaglobal.com"
                                                       && _.Subject == string.Format(Alerts.UserAccountLockedTitle, _lockedAccount.Username)
                                                       && _.Body.TextContains(Alerts.UserAccountLockedExplanation)
                                                       && _.IsBodyHtml))
                        .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ThrowsErrorWhenNoUserAdministratorsToNotifyTo()
            {
                _fixture = new UserAccountLockedFixture(Db);
                await Assert.ThrowsAsync<Exception>(async () => await _fixture.Subject.NotifyAllConcerned(_lockedAccount));
            }
        }

        public class UserAccountLockedFixture : IFixture<UserAccountLocked>
        {
            public UserAccountLockedFixture(InMemoryDbContext db)
            {
                UserAdministrators = Substitute.For<IUserAdministrators>();

                EmailNotifier = Substitute.For<IEmailNotification>();

                PopupNotifier = Substitute.For<IPopupNotification>();

                SiteControls = Substitute.For<ISiteControlReader>();
                SiteControls.Read<string>(Inprotech.Infrastructure.SiteControls.WorkBenchAdministratorEmail).Returns("support@customer-domain.com");

                DocItemRunner = Substitute.For<IDocItemRunner>();

                Subject = new UserAccountLocked(UserAdministrators, EmailNotifier, PopupNotifier, SiteControls, db, DocItemRunner);
            }

            public IUserAdministrators UserAdministrators { get; set; }

            public IEmailNotification EmailNotifier { get; set; }

            public IPopupNotification PopupNotifier { get; set; }

            public ISiteControlReader SiteControls { get; set; }

            public IDocItemRunner DocItemRunner { get; set; }

            public UserAccountLocked Subject { get; }

            ILifetimeScope WireUp(DependableActivity.CompletedActivity completedActivity)
            {
                var builder = new ContainerBuilder();
                builder.RegisterInstance(UserAdministrators).As<IUserAdministrators>();
                builder.RegisterInstance(PopupNotifier).As<IPopupNotification>();
                builder.RegisterInstance(EmailNotifier).As<IEmailNotification>();
                builder.RegisterInstance(SiteControls).As<ISiteControlReader>();
                builder.RegisterInstance(Subject).As<UserAccountLocked>();
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