using Autofac;
using Dependable;
using Inprotech.Contracts.DocItems;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Properties;
using Inprotech.Integration.Security.Authorization;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using System.Collections.Generic;
using System.Data;
using System.Threading.Tasks;
using Xunit;

namespace Inprotech.Tests.Integration.Security.Authorization
{
    public class UserTwoFactorEmailRequiredFacts
    {
        [Collection("Dependable")]
        public class EmailUserMethod : FactBase
        {
            UserTwoFactorEmailRequiredFixture _fixture;

            readonly UserAccount2FaMessage _message = new UserAccount2FaMessage
            {
                DisplayName = Fixture.String(),
                IdentityId = Fixture.Integer(),
                UserEmail = Fixture.String(),
                Username = Fixture.String(),
                AuthenticationCode = Fixture.String()
            };

            [Fact]
            public async Task EmailUser()
            {
                _fixture = new UserTwoFactorEmailRequiredFixture(Db);

                var dataItem = new DocItem {Name = KnownEmailDocItems.TwoFactor, Sql = "Select ABC, DEF, XYZ", EntryPointUsage = 1}.In(Db);
                var docItemResult = new UserEmailContent
                {
                    Subject = Fixture.String(),
                    Body = Fixture.String("text<anc>hjb"),
                    Footer = Fixture.String()
                };
                var result = new DataSet();
                result.Tables.Add(new DataTable());
                result.Tables[0].Columns.Add("Subject");
                result.Tables[0].Columns.Add("Body");
                result.Tables[0].Columns.Add("Footer");
                var row = result.Tables[0].NewRow();
                row["Subject"] = docItemResult.Subject;
                row["Body"] = docItemResult.Body;
                row["Footer"] = docItemResult.Footer;
                result.Tables[0].Rows.Add(row);
                _fixture.DocItemRunner.Run(Arg.Any<int>(), Arg.Any<Dictionary<string, object>>()).Returns(result);

                var activity = await _fixture.Subject.EmailUser(_message);

                _fixture.Execute(activity);

                _fixture.SiteControls.Received(1).Read<string>(SiteControls.WorkBenchAdministratorEmail);

                _fixture.DocItemRunner.Received(1).Run(dataItem.Id, Arg.Any<Dictionary<string, object>>());

                _fixture.EmailNotifier.Received(1)
                        .Send(Arg.Is<Notification>(
                                                   _ =>
                                                       _.Subject == docItemResult.Subject
                                                       && _.Body.TextContains(docItemResult.Body)
                                                       && _.Body.TextContains(docItemResult.Footer)
                                                       && _.IsBodyHtml))
                        .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task EmailUserWithDefaultContent()
            {
                _fixture = new UserTwoFactorEmailRequiredFixture(Db);

                var dataItem = new DocItem {Name = KnownEmailDocItems.TwoFactor, Sql = "Select ABC, DEF, XYZ", EntryPointUsage = 1}.In(Db);
                var result = new DataSet();
                _fixture.DocItemRunner.Run(Arg.Any<int>(), Arg.Any<Dictionary<string, object>>()).Returns(result);

                var activity = await _fixture.Subject.EmailUser(_message);

                _fixture.Execute(activity);

                _fixture.SiteControls.Received(1).Read<string>(SiteControls.WorkBenchAdministratorEmail);

                _fixture.DocItemRunner.Received(1).Run(dataItem.Id, Arg.Any<Dictionary<string, object>>());

                _fixture.EmailNotifier.Received(1)
                        .Send(Arg.Is<Notification>(
                                                   _ =>
                                                       _.Subject == Alerts.UserAccountRequiresTwoFactorEmailTitle
                                                       && _.Body.TextContains(string.Format(Alerts.UserAccountRequiresTwoFactorExplanation, _message.AuthenticationCode))
                                                       && _.Body.TextContains("This is a system generated email. Please do not reply.")
                                                       && !_.IsBodyHtml))
                        .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class UserTwoFactorEmailRequiredFixture : IFixture<UserTwoFactorEmailRequired>
        {
            public UserTwoFactorEmailRequiredFixture(InMemoryDbContext db)
            {
                EmailNotifier = Substitute.For<IEmailNotification>();
                SiteControls = Substitute.For<ISiteControlReader>();
                SiteControls.Read<string>(Inprotech.Infrastructure.SiteControls.WorkBenchAdministratorEmail).Returns("support@customer-domain.com");
                DocItemRunner = Substitute.For<IDocItemRunner>();
                Subject = new UserTwoFactorEmailRequired(EmailNotifier, SiteControls, db, DocItemRunner);
            }

            public IEmailNotification EmailNotifier { get; set; }
            public ISiteControlReader SiteControls { get; set; }
            public IDocItemRunner DocItemRunner { get; set; }
            public UserTwoFactorEmailRequired Subject { get; }

            ILifetimeScope WireUp(DependableActivity.CompletedActivity completedActivity)
            {
                var builder = new ContainerBuilder();
                builder.RegisterInstance(EmailNotifier).As<IEmailNotification>();
                builder.RegisterInstance(SiteControls).As<ISiteControlReader>();
                builder.RegisterInstance(Subject).As<UserTwoFactorEmailRequired>();
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
