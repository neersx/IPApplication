using System;
using System.Collections.Generic;
using System.Data;
using Inprotech.Contracts.DocItems;
using Inprotech.Contracts.Messages;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Legacy;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases
{
    public class EventNotesEmailHelperFacts : FactBase
    {
        public class EventNotesPrepareEmailMessage : FactBase
        {
            
            [Fact]
            public void ReturnsEventNotesMailMessage()
            {
                var f = new EventNotesEmailHelperFixture(Db).WithUser()
                                                            .WithTranslations()
                                                            .WithEventNotesEmailSiteControlsConfigured()
                                                            .WithDocItemsReturningValidEmailAddresses();
                
                var setup = f.SetupCaseEventText();

                (EventNotesMailMessage mailMessage, string emailValidationMessage) validationResult = f.Subject.PrepareEmailMessage(setup.caseEventText, "new text");
                
                Assert.NotNull(validationResult.mailMessage);
                Assert.Equal(string.Empty, validationResult.emailValidationMessage);
                Assert.Equal("abc@domain.com", validationResult.mailMessage.To);
                Assert.Contains("MainEmail" ,validationResult.mailMessage.From);
                Assert.Contains("localised-emailSubject" ,validationResult.mailMessage.Subject);
                Assert.Contains("xyz@domain.com" ,validationResult.mailMessage.Cc);
                Assert.Contains("localised-emailBodyPart1", validationResult.mailMessage.Body);
                Assert.Contains("localised-emailBodyPart2", validationResult.mailMessage.Body);
                Assert.Contains("http://localhost/cpinproma", validationResult.mailMessage.Body);
            }

            [Fact]
            public void ReturnsValidationMessageWhenInvalidEmailFormatsReturnedByDocItemQuery()
            {
                var f = new EventNotesEmailHelperFixture(Db).WithUser()
                                                            .WithTranslations()
                                                            .WithEventNotesEmailSiteControlsConfigured()
                                                            .WithDocItemsReturningInValidEmailAddresses();
                
                var setup = f.SetupCaseEventText();

                (EventNotesMailMessage mailMessage, string emailValidationMessage) validationResult = f.Subject.PrepareEmailMessage(setup.caseEventText, "new text");
                
                Assert.NotNull(validationResult.emailValidationMessage);
                Assert.Equal("localised-toCcEmailValidation", validationResult.emailValidationMessage);
            }

            [Fact]
            public void DoesNotPrepareEmailMessageWhenSiteControlsNotConfiguredForEmail()
            {
                var f = new EventNotesEmailHelperFixture(Db).WithUser()
                                                            .WithTranslations()
                                                            .WithEventNotesEmailSiteControlsConfigured(false)
                                                            .WithDocItemsReturningValidEmailAddresses();
                
                var setup = f.SetupCaseEventText();

                (EventNotesMailMessage mailMessage, string emailValidationMessage) validationResult = f.Subject.PrepareEmailMessage(setup.caseEventText, "new text");
                
                Assert.Equal(string.Empty, validationResult.emailValidationMessage);
                Assert.Null(validationResult.mailMessage.To);
                Assert.Null(validationResult.mailMessage.Body);
            }
        }

        public class EventNotesEmailHelperFixture : IFixture<EventNotesEmailHelper>
        {
            public EventNotesEmailHelperFixture(InMemoryDbContext dbContext)
            {
                DbContext = dbContext;
                SecurityContext = Substitute.For<ISecurityContext>();
                DocItemRunner = Substitute.For<IDocItemRunner>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                StaticTranslator = Substitute.For<IStaticTranslator>();
                DataService = Substitute.For<IDataService>();
                DataService.GetParentUri(Arg.Any<string>()).ReturnsForAnyArgs(new Uri("http://localhost/cpinproma"));
                EmailValidator = Substitute.For<IEmailValidator>();

                Subject = new EventNotesEmailHelper(DbContext, SecurityContext, SiteControlReader, DocItemRunner, PreferredCultureResolver, StaticTranslator, DataService, EmailValidator);
            }

            ISecurityContext SecurityContext { get; set; }
            IDocItemRunner DocItemRunner { get; set; }
            InMemoryDbContext DbContext { get; set; }
            ISiteControlReader SiteControlReader { get; set; }
            IPreferredCultureResolver PreferredCultureResolver { get; set; }
            IStaticTranslator StaticTranslator { get; set; }
            IDataService DataService { get; set; }
            IEmailValidator EmailValidator { get; set; }

            public EventNotesEmailHelper Subject { get; }

            public EventNotesEmailHelperFixture WithUser(bool validNameEmail = true)
            {
                var name = new NameBuilder(DbContext).Build().In(DbContext);

                name.MainEmail().TelecomNumber = Fixture.String("MainEmail");
                name.MainPhone().TelecomNumber = Fixture.String("MainPhone");

                var user = new User("internal", false)
                {
                    Name = name
                }.In(DbContext);
                SecurityContext.User.Returns(_ => user);

                return this;
            }

            public EventNotesEmailHelperFixture WithDocItemsReturningValidEmailAddresses(bool configureDocItem = true)
            {
                DocItemRunner.Run("event_notes_email_to", Arg.Any<Dictionary<string, object>>()).Returns(_ =>
                {
                    var ds = new DataSet();
                    var dt = new DataTable();
                    dt.Columns.Add();
                    dt.Rows.Add("abc@domain.com");
                    ds.Tables.Add(dt);
                    return ds;
                });

                DocItemRunner.Run("event_notes_email_cc", Arg.Any<Dictionary<string, object>>()).Returns(_ =>
                {
                    var ds = new DataSet();
                    var dt = new DataTable();
                    dt.Columns.Add();
                    dt.Rows.Add("xyz@domain.com");
                    ds.Tables.Add(dt);
                    return ds;
                });

                EmailValidator.IsValid(Arg.Any<string>()).Returns(true);
               
                return this;
            }

            public EventNotesEmailHelperFixture WithDocItemsReturningInValidEmailAddresses()
            {
                DocItemRunner.Run("event_notes_email_to", Arg.Any<Dictionary<string, object>>()).Returns(_ =>
                {
                    var ds = new DataSet();
                    var dt = new DataTable();
                    dt.Columns.Add();
                    dt.Rows.Add("abc.domain.com");
                    ds.Tables.Add(dt);
                    return ds;
                });

                DocItemRunner.Run("event_notes_email_cc", Arg.Any<Dictionary<string, object>>()).Returns(_ =>
                {
                    var ds = new DataSet();
                    var dt = new DataTable();
                    dt.Columns.Add();
                    dt.Rows.Add("xyz.domain.com");
                    ds.Tables.Add(dt);
                    return ds;
                });

                EmailValidator.IsValid(Arg.Any<string>()).Returns(false);
               
                return this;
            }

            public EventNotesEmailHelperFixture WithEventNotesEmailSiteControlsConfigured(bool configureDocItem = true)
            {
                if (configureDocItem)
                {
                    SiteControlReader.Read<string>(SiteControls.EventNotesEmailTo).Returns("event_notes_email_to");
                    SiteControlReader.Read<string>(SiteControls.EventNotesEmailCopyTo).Returns("event_notes_email_cc");
                }
               
                return this;
            }

            public EventNotesEmailHelperFixture WithTranslations()
            {
                var cultures = new[] {"en-AU"};
                PreferredCultureResolver.ResolveAll().ReturnsForAnyArgs(cultures);

                StaticTranslator.Translate("taskPlanner.eventNotes.toCcEmailValidation", Arg.Any<IEnumerable<string>>()).Returns("localised-toCcEmailValidation");
                StaticTranslator.Translate("taskPlanner.eventNotes.fromEmailValidation", Arg.Any<IEnumerable<string>>()).Returns("localised-fromEmailValidation");
                StaticTranslator.Translate("taskPlanner.eventNotes.eventNotesEmailSubject", Arg.Any<IEnumerable<string>>()).Returns("localised-emailSubject");
                StaticTranslator.Translate("taskPlanner.eventNotes.eventNotesEmailBodyPart1", Arg.Any<IEnumerable<string>>()).Returns("localised-emailBodyPart1");
                StaticTranslator.Translate("taskPlanner.eventNotes.eventNotesEmailBodyPart2", Arg.Any<IEnumerable<string>>()).Returns("localised-emailBodyPart2");
                StaticTranslator.Translate("taskPlanner.eventNotes.eventNotesEmailBodyPart1WithEventNoteType", Arg.Any<IEnumerable<string>>()).Returns("localised-emailBodyPart1WithEventNoteType");
                
                return this;
            }

            public dynamic SetupCaseEventText()
            {
                var @case = new Case { Irn = "Case" }.In(DbContext);
                var eventTextRow = new EventText(Fixture.String(), null).In(DbContext);
                var caseEventText = new CaseEventText(@case, 1, 1, eventTextRow).In(DbContext);

                return new
                {
                    @case,
                    caseEventText
                };
            }
        }
    }
}
