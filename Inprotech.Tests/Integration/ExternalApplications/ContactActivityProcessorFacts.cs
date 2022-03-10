using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Integration.ExternalApplications.Crm;
using Inprotech.Integration.ExternalApplications.Crm.Request;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.ExternalApplications
{
    public class ContactActivityProcessorFacts
    {
        public class ContactActivityProcessorFixture : IFixture<ContactActivityProcessor>
        {
            public ContactActivityProcessorFixture(InMemoryDbContext db)
            {
                DbContext = db;

                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(InternalWebApiUser());

                LastInternalCodeGenerator = Substitute.For<ILastInternalCodeGenerator>();

                SystemClock = Substitute.For<Func<DateTime>>();
                SystemClock().Returns(Fixture.Today());

                Subject = new ContactActivityProcessor(DbContext, LastInternalCodeGenerator, SecurityContext, SystemClock);
            }

            public InMemoryDbContext DbContext { get; set; }

            public ISecurityContext SecurityContext { get; set; }

            public ILastInternalCodeGenerator LastInternalCodeGenerator { get; set; }

            public Func<DateTime> SystemClock { get; }

            public ContactActivityProcessor Subject { get; }

            User InternalWebApiUser()
            {
                return UserBuilder.AsInternalUser(DbContext, "internal").Build().In(DbContext);
            }
        }

        public class AddContactActivityMethod : FactBase
        {
            Name _contactName;
            ContactActivityRequest _request;
            TableCode _activityType;
            TableCode _activityCategory;
            Name _callerName;
            Name _staffName;

            void Setup()
            {
                _contactName = new NameBuilder(Db).Build().In(Db);
                var contactNameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.Contact}.Build().In(Db);
                var ntc =
                    new NameTypeClassificationBuilder(Db) {Name = _contactName, NameType = contactNameType, IsAllowed = 1}
                        .Build().In(Db);
                _contactName.NameTypeClassifications.Add(ntc);

                _activityType = new TableCodeBuilder {TableCode = KnownActivityTypes.PhoneCall}.For(TableTypes.ContactActivityType).Build().In(Db);
                _activityCategory = new TableCodeBuilder().For(TableTypes.ContactActivityCategory).Build().In(Db);
                _callerName = new NameBuilder(Db).Build().In(Db);
                _staffName = new NameBuilder(Db).Build().In(Db);

                _request = new ContactActivityRequest();
            }

            void SetupContactActivity()
            {
                _request.ContactActivity = new ContactActivity
                {
                    ActivityCategory = _activityCategory.Id,
                    ActivityType = _activityType.Id,
                    Summary = Fixture.String(),
                    IsOutgoing = true,
                    CallerId = _callerName.Id,
                    StaffId = _staffName.Id,
                    Notes = Fixture.String()
                };
            }

            [Fact]
            public void AddContactActivityAttachmentIfMandatoryFieldsArePassed()
            {
                Setup();
                SetupContactActivity();

                var attachment1 = new ContactActivityAttachment
                {
                    AttachmentName = Fixture.String(),
                    FileName = "C:\\Users.pdf"
                };
                var attachment2 = new ContactActivityAttachment
                {
                    AttachmentName = Fixture.String(),
                    FileName = "C:\\Users.xml"
                };
                _request.ContactActivityAttachments = new List<ContactActivityAttachment> {attachment1, attachment2};

                var f = new ContactActivityProcessorFixture(Db);

                f.LastInternalCodeGenerator.GenerateLastInternalCode(Arg.Any<string>()).Returns(1);

                f.Subject.AddContactActivity(_contactName.Id, _request);

                var activityAttachments = f.DbContext.Set<ActivityAttachment>().Where(aa => aa.ActivityId == 1).ToList();
                Assert.Equal(2, activityAttachments.Count);
                Assert.Equal(attachment1.AttachmentName, activityAttachments[0].AttachmentName);
                Assert.Equal(0, activityAttachments[0].SequenceNo);
                Assert.Equal(1, activityAttachments[1].SequenceNo);
            }

            [Fact]
            public void AddContactActivityIfMandatoryFieldsArePassed()
            {
                Setup();
                SetupContactActivity();

                var f = new ContactActivityProcessorFixture(Db);
                var lastInternalCode = Fixture.Integer();

                f.LastInternalCodeGenerator.GenerateLastInternalCode(Arg.Any<string>()).Returns(lastInternalCode);

                f.Subject.AddContactActivity(_contactName.Id, _request);

                var activity = f.DbContext.Set<Activity>().FirstOrDefault();
                Assert.NotNull(activity);
                Assert.Equal(f.SecurityContext.User.Id, activity.UserIdentityId);
                Assert.Equal(_activityType.Id, activity.ActivityType.Id);
                Assert.NotNull(activity.ActivityDate);
                Assert.Equal(0, activity.LongFlag.GetValueOrDefault());
                Assert.Null(activity.ClientReference);
                Assert.Equal(1, activity.CallType.GetValueOrDefault());
                Assert.Null(activity.RelatedName);
                Assert.NotNull(activity.CallStatus);
                if (activity.CallStatus == null) return;
                Assert.Equal<short>(1, activity.CallStatus.Value);
            }

            [Fact]
            public void AddContactActivityOfClientRequest()
            {
                Setup();

                var clientReqType = new TableCodeBuilder {TableCode = KnownActivityTypes.ClientRequest}.For(TableTypes.ContactActivityType).Build().In(Db);
                var date = DateTime.Today.AddDays(1);

                _request.ContactActivity = new ContactActivity
                {
                    ActivityCategory = _activityCategory.Id,
                    ActivityType = clientReqType.Id,
                    Summary = Fixture.String(),
                    StaffId = _staffName.Id,
                    CallerId = _callerName.Id,
                    ClientReference = "ClientReference1234567890ClientReference1234567890ClientReference1234567890ClientReference1234567890",
                    Notes = Fixture.String(),
                    Incomplete = true,
                    Date = date
                };

                var f = new ContactActivityProcessorFixture(Db);
                var lastInternalCode = Fixture.Integer();

                f.LastInternalCodeGenerator.GenerateLastInternalCode(Arg.Any<string>()).Returns(lastInternalCode);

                f.Subject.AddContactActivity(_contactName.Id, _request);

                var activity = f.DbContext.Set<Activity>().FirstOrDefault();
                Assert.NotNull(activity);
                Assert.Equal(clientReqType.Id, activity.ActivityType.Id);
                Assert.Null(activity.StaffName);
                Assert.Null(activity.CallerName);
                Assert.False(activity.Incomplete == 1);
                Assert.NotEqual(date, activity.ActivityDate);
                Assert.Equal(_request.ContactActivity.ClientReference.Substring(0, 50), activity.ClientReference);
            }

            [Fact]
            public void CreateDefaultSummaryIfNotProvided()
            {
                Setup();
                SetupContactActivity();

                _request.ContactActivity.Summary = null;
                var summary = _activityType.Name + " - To: " + _contactName.Formatted(NameStyles.FirstNameThenFamilyName);

                var f = new ContactActivityProcessorFixture(Db);
                var lastInternalCode = Fixture.Integer();

                f.LastInternalCodeGenerator.GenerateLastInternalCode(Arg.Any<string>()).Returns(lastInternalCode);

                f.Subject.AddContactActivity(_contactName.Id, _request);

                var activity = f.DbContext.Set<Activity>().FirstOrDefault();
                Assert.NotNull(activity);
                Assert.Equal(summary, activity.Summary);
            }

            [Fact]
            public void SetRegardingNameAsNullIfContactNameIsNotItsEmployee()
            {
                Setup();
                SetupContactActivity();
                var regardingName = new NameBuilder(Db).Build().In(Db);
                _request.ContactActivity.RegardingId = regardingName.Id;

                var f = new ContactActivityProcessorFixture(Db);
                var lastInternalCode = Fixture.Integer();

                f.LastInternalCodeGenerator.GenerateLastInternalCode(Arg.Any<string>()).Returns(lastInternalCode);

                f.Subject.AddContactActivity(_contactName.Id, _request);

                var activity = f.DbContext.Set<Activity>().FirstOrDefault();
                if (activity == null) return;
                Assert.Null(activity.RelatedName);
            }

            [Fact]
            public void SetRegardingNameIfContactNameIsItsEmployee()
            {
                Setup();
                SetupContactActivity();
                var regardingName = new NameBuilder(Db).Build().In(Db);
                new AssociatedNameBuilder(Db)
                {
                    Name = regardingName,
                    RelatedName = _contactName,
                    Relationship = KnownRelations.Employs
                }.Build().In(Db);

                _request.ContactActivity.RegardingId = regardingName.Id;

                var f = new ContactActivityProcessorFixture(Db);
                var lastInternalCode = Fixture.Integer();

                f.LastInternalCodeGenerator.GenerateLastInternalCode(Arg.Any<string>()).Returns(lastInternalCode);

                f.Subject.AddContactActivity(_contactName.Id, _request);

                var activity = f.DbContext.Set<Activity>().FirstOrDefault();
                if (activity == null) return;
                Assert.Equal(regardingName.Id, activity.RelatedNameId);
            }

            [Fact]
            public void ThrowsExceptionWhenActivityCategoryIsNotValid()
            {
                Setup();

                _request.ContactActivity = new ContactActivity {ActivityType = _activityType.Id, ActivityCategory = Fixture.Integer()};

                var exception =
                    Record.Exception(() => new ContactActivityProcessorFixture(Db).Subject.AddContactActivity(_contactName.Id, _request));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsExceptionWhenActivityTypeIsNotPassed()
            {
                Setup();

                _request.ContactActivity = new ContactActivity();

                var exception =
                    Record.Exception(() => new ContactActivityProcessorFixture(Db).Subject.AddContactActivity(_contactName.Id, _request));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.BadRequest, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsExceptionWhenActivityTypeIsNotValid()
            {
                Setup();

                _request.ContactActivity = new ContactActivity {ActivityType = Fixture.Integer(), ActivityCategory = _activityCategory.Id};

                var exception =
                    Record.Exception(() => new ContactActivityProcessorFixture(Db).Subject.AddContactActivity(_contactName.Id, _request));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsExceptionWhenAttachmentNameIsNull()
            {
                Setup();
                SetupContactActivity();

                var attachment = new ContactActivityAttachment
                {
                    FileName = "C:\\Users.pdf"
                };
                _request.ContactActivityAttachments = new List<ContactActivityAttachment> {attachment};

                var f = new ContactActivityProcessorFixture(Db);

                f.LastInternalCodeGenerator.GenerateLastInternalCode(Arg.Any<string>()).Returns(1);

                var exception =
                    Record.Exception(() => f.Subject.AddContactActivity(_contactName.Id, _request));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.BadRequest, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsExceptionWhenContactActivityIsNotPassed()
            {
                Setup();
                var exception =
                    Record.Exception(() => new ContactActivityProcessorFixture(Db).Subject.AddContactActivity(_contactName.Id, _request));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.BadRequest, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsExceptionWhenFileNameIsInvalid()
            {
                Setup();
                SetupContactActivity();

                var attachment = new ContactActivityAttachment
                {
                    AttachmentName = Fixture.String(),
                    FileName = "User@\\?s"
                };
                _request.ContactActivityAttachments = new List<ContactActivityAttachment> {attachment};

                var f = new ContactActivityProcessorFixture(Db);

                f.LastInternalCodeGenerator.GenerateLastInternalCode(Arg.Any<string>()).Returns(1);

                var exception =
                    Record.Exception(() => f.Subject.AddContactActivity(_contactName.Id, _request));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.BadRequest, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsExceptionWhenFileNameIsNull()
            {
                Setup();
                SetupContactActivity();

                var attachment = new ContactActivityAttachment
                {
                    AttachmentName = Fixture.String()
                };
                _request.ContactActivityAttachments = new List<ContactActivityAttachment> {attachment};

                var f = new ContactActivityProcessorFixture(Db);

                f.LastInternalCodeGenerator.GenerateLastInternalCode(Arg.Any<string>()).Returns(1);

                var exception =
                    Record.Exception(() => f.Subject.AddContactActivity(_contactName.Id, _request));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.BadRequest, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsExceptionWhenNameIsNotAValidContact()
            {
                var name = new NameBuilder(Db).Build().In(Db);
                var exception =
                    Record.Exception(() => new ContactActivityProcessorFixture(Db).Subject.AddContactActivity(name.Id, null));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsExceptionWhenNameIsNotPassed()
            {
                var exception =
                    Record.Exception(() => new ContactActivityProcessorFixture(Db).Subject.AddContactActivity(Fixture.Integer(), null));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsExceptionWhenNonCrmCaseIsPassed()
            {
                Setup();
                var @case = new CaseBuilder().Build().In(Db);

                _request.ContactActivity = new ContactActivity {ActivityType = _activityType.Id, ActivityCategory = _activityCategory.Id, CaseId = @case.Id};

                var exception =
                    Record.Exception(() => new ContactActivityProcessorFixture(Db).Subject.AddContactActivity(_contactName.Id, _request));

                Assert.NotNull(exception);
                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.Unauthorized, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void TruncateSummaryAndReferencesIfMoreLengthIsPassedThenAccepted()
            {
                Setup();
                SetupContactActivity();
                _request.ContactActivity.Summary =
                    "Summary1234567890Summary1234567890Summary1234567890Summary1234567890Summary1234567890Summary1234567890Summary1234567890";
                _request.ContactActivity.GeneralReference = "GeneralReference1234567890";

                var f = new ContactActivityProcessorFixture(Db);
                var lastInternalCode = Fixture.Integer();

                f.LastInternalCodeGenerator.GenerateLastInternalCode(Arg.Any<string>()).Returns(lastInternalCode);

                f.Subject.AddContactActivity(_contactName.Id, _request);

                var activity = f.DbContext.Set<Activity>().FirstOrDefault();
                Assert.NotNull(activity);
                Assert.Equal(_request.ContactActivity.Summary.Substring(0, 100), activity.Summary);
                Assert.Equal(_request.ContactActivity.GeneralReference.Substring(0, 20), activity.ReferenceNo);
            }
        }
    }
}