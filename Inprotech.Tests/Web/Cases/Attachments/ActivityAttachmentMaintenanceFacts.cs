using System;
using System.Dynamic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Attachment;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.ContactActivities;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Tests.Web.Cases.Attachments
{
    public class CaseActivityAttachmentMaintenanceFacts : FactBase
    {
        void CreateEvent(string actionId, int eventId, string eventDescription)
        {
            new Action(id: actionId, name: Fixture.String()).In(Db);
            new Event {Id = eventId, ControllingAction = actionId, Description = eventDescription}.In(Db);
        }

        void CreateValidEvent(int criteriaId, int eventId, string validDescription)
        {
            var criteria = new Criteria {Id = criteriaId}.In(Db);
            new ValidEvent(criteria.Id, eventId, validDescription).In(Db);
        }

        void CreateCaseWithOpenActionNValidEvent(int caseId, int eventId, string irn, string eventDescription, string validDescription = "Valid!")
        {
            var actionCode = Fixture.RandomString(3);
            var criteriaId = Fixture.Integer();
            CreateEvent(actionCode, eventId, eventDescription);
            CreateValidEvent(criteriaId, eventId, validDescription);

            var @case = new CaseBuilder {Irn = irn}.BuildWithId(caseId).In(Db);
            var action = Db.Set<Action>().Single(_ => _.Code == actionCode);
            var criteria = Db.Set<Criteria>().Single(_ => _.Id == criteriaId);
            new OpenAction(action, @case, 1, "started", criteria) {ActionId = action.Code}.In(Db);

            new CaseEvent(@case.Id, eventId, 1)
            {
                CreatedByCriteriaKey = criteria.Id
            }.In(Db);
        }

        [Fact]
        public async Task GetAttachmentReturnsData()
        {
            var caseId = Fixture.Integer();
            var eventId = Fixture.Integer();
            CreateCaseWithOpenActionNValidEvent(caseId, eventId, "SomeIRN", "descriptions", "ValidDescription");
            var activity = new Activity {Id = 1, CaseId = caseId, EventId = eventId, ActivityCategory = new TableCode(), ActivityType = new TableCode()}.In(Db);
            new ActivityAttachment {ActivityId = 1, SequenceNo = 1, Activity = activity}.In(Db);

            var f = new ActivityAttachmentMaintenanceFixture(Db);

            dynamic result = await f.Subject.GetAttachment(1, 1);

            Assert.Equal(caseId, result.ActivityCaseId);
            Assert.Equal(eventId, result.EventId);
            Assert.Equal("ValidDescription", result.EventDescription);
        }

        [Fact]
        public async Task GetAttachmentsReturnsData()
        {
            var caseId = Fixture.Integer();
            var eventId = Fixture.Integer();
            CreateCaseWithOpenActionNValidEvent(caseId, eventId, "SomeIRN", "descriptions");
            var activity1 = new Activity {Id = 1, CaseId = caseId, EventId = eventId, ActivityCategory = new TableCode(), ActivityType = new TableCode()}.In(Db);
            new ActivityAttachment {ActivityId = 1, SequenceNo = 1, Activity = activity1}.In(Db);

            var activity2 = new Activity {Id = 2, CaseId = caseId, EventId = eventId, ActivityCategory = new TableCode(), ActivityType = new TableCode()}.In(Db);
            new ActivityAttachment {ActivityId = 2, SequenceNo = 1, Activity = activity2}.In(Db);
            new ActivityAttachment {ActivityId = 2, SequenceNo = 2, Activity = activity2}.In(Db);

            var f = new ActivityAttachmentMaintenanceFixture(Db);

            var result = await f.Subject.GetAttachments(caseId, new CommonQueryParameters());

            Assert.Equal(3, result.Count());
        }

        [Fact]
        public async Task ReturnsActionName()
        {
            var caseId = Fixture.Integer();
            var eventId = Fixture.Integer();

            var f = new ActivityAttachmentMaintenanceFixture(Db);
            f.ActivityMaintenance.ViewDetails().ReturnsForAnyArgs(new ExpandoObject());
            f.Actions.CaseViewActions(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>())
             .ReturnsForAnyArgs(new[]
             {
                 new ActionData {Name = "A NEW NAME", BaseName = "A Base Name", Code = "AS"},
                 new ActionData {Name = "A NEW NAME 2", BaseName = "A Base Name 2", Code = "SA"}
             }.AsDbAsyncEnumerble());

            new CaseBuilder {Irn = "ABCD", CaseType = new CaseType {Code = "T"}.In(Db), PropertyType = new PropertyType {Code = "P"}.In(Db), CountryCode = "AZ"}.BuildWithId(caseId).In(Db);

            dynamic result = await f.Subject.ViewDetails(caseId, null, "AS");
            f.ActivityMaintenance.Received(1).ViewDetails().IgnoreAwaitForNSubstituteAssertion();

            Assert.Equal(caseId, result.caseId);
            Assert.Equal("ABCD", result.irn);
            Assert.Equal("A NEW NAME", result.actionName);
        }

        [Fact]
        public async Task ReturnsBaseEventDescription()
        {
            var caseId = Fixture.Integer();
            var eventId = Fixture.Integer();

            var f = new ActivityAttachmentMaintenanceFixture(Db);
            f.ActivityMaintenance.ViewDetails().ReturnsForAnyArgs(new ExpandoObject());
            new CaseBuilder {Irn = "Awesome"}.BuildWithId(caseId).In(Db);
            CreateEvent(Fixture.RandomString(3), eventId, "baseDescription");

            dynamic result = await f.Subject.ViewDetails(caseId, eventId);
            f.ActivityMaintenance.Received(1).ViewDetails().IgnoreAwaitForNSubstituteAssertion();

            Assert.Equal(caseId, result.caseId);
            Assert.Equal("Awesome", result.irn);
            Assert.Equal(eventId, result.Event.Id);
            Assert.Equal("baseDescription", result.Event.Description);
            Assert.False(result.Event.IsCaseEvent);
            Assert.False(result.Event.IsCyclic);
        }

        [Fact]
        public async Task ReturnsViewDetails()
        {
            var caseId = Fixture.Integer();
            var eventId = Fixture.Integer();

            var f = new ActivityAttachmentMaintenanceFixture(Db);
            f.ActivityMaintenance.ViewDetails().ReturnsForAnyArgs(new ExpandoObject());
            CreateCaseWithOpenActionNValidEvent(caseId, eventId, "SomeIRN", "baseDescription", "validDescription");

            dynamic result = await f.Subject.ViewDetails(caseId, eventId);
            f.ActivityMaintenance.Received(1).ViewDetails().IgnoreAwaitForNSubstituteAssertion();

            Assert.Equal(caseId, result.caseId);
            Assert.Equal("SomeIRN", result.irn);
            Assert.Equal(eventId, result.Event.Id);
            Assert.Equal("validDescription", result.Event.Description);
            Assert.True(result.Event.IsCaseEvent);
            Assert.False(result.Event.IsCyclic);

            f.CultureResolver.Received(1).Resolve();
        }

        [Fact]
        public async Task InsertAttachmentCallsTransactionRecordal()
        {
            var f = new ActivityAttachmentMaintenanceFixture(Db);

            await f.Subject.InsertAttachment(new ActivityAttachmentModel {ActivityCaseId = 10, ActivityId = 1});

            f.TransactionRecordal.Received(1).RecordTransactionForCase(10, CaseTransactionMessageIdentifier.AmendedCase, component: KnownComponents.Case);
            f.AttachmentMaintenance.Received(1).InsertAttachment(Arg.Any<ActivityAttachmentModel>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task InsertAttachmentThrowsExceptionIfCycleIsInvalid()
        {
            var caseId = Fixture.Integer();
            var eventId = Fixture.Integer();
            CreateCaseWithOpenActionNValidEvent(caseId, eventId, "SomeIRN", "descriptions", "ValidDescription");
            var f = new ActivityAttachmentMaintenanceFixture(Db);

            await Assert.ThrowsAnyAsync<Exception>(async () => await f.Subject.InsertAttachment(new ActivityAttachmentModel {ActivityCaseId = caseId, ActivityId = 1, EventId = eventId, EventCycle = 10}));
            f.AttachmentMaintenance.Received(0).InsertAttachment(Arg.Any<ActivityAttachmentModel>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task UpdateAttachmentCallsTransactionRecordal()
        {
            var f = new ActivityAttachmentMaintenanceFixture(Db);

            await f.Subject.UpdateAttachment(new ActivityAttachmentModel {ActivityCaseId = 10, ActivityId = 1});

            f.TransactionRecordal.Received(1).RecordTransactionForCase(10, CaseTransactionMessageIdentifier.AmendedCase, component: KnownComponents.Case);
            f.AttachmentMaintenance.Received(1).UpdateAttachment(Arg.Any<ActivityAttachmentModel>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task UpdateAttachmentThrowsExceptionIfCycleIsInvalid()
        {
            const int activityId = 1;
            const int attachmentSeq = 10;
            new Activity(activityId, Fixture.String(),
                         new TableCode(Fixture.Integer(), Fixture.Short(), Fixture.String()),
                         new TableCode(Fixture.Integer(), Fixture.Short(), Fixture.String())).In(Db);

            new ActivityAttachment(activityId, attachmentSeq).In(Db);

            var caseId = Fixture.Integer();
            var eventId = Fixture.Integer();
            CreateCaseWithOpenActionNValidEvent(caseId, eventId, "SomeIRN", "descriptions", "ValidDescription");
            var f = new ActivityAttachmentMaintenanceFixture(Db);

            await Assert.ThrowsAnyAsync<Exception>(async () => await f.Subject.UpdateAttachment(new ActivityAttachmentModel {ActivityCaseId = caseId, ActivityId = activityId, SequenceNo = attachmentSeq, EventId = eventId, EventCycle = 10}));
            f.AttachmentMaintenance.Received(0).InsertAttachment(Arg.Any<ActivityAttachmentModel>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task DeleteAttachmentCallsTransactionRecordal()
        {
            var f = new ActivityAttachmentMaintenanceFixture(Db);

            await f.Subject.DeleteAttachment(new ActivityAttachmentModel {ActivityCaseId = 10, ActivityId = 1});

            f.TransactionRecordal.Received(1).RecordTransactionForCase(10, CaseTransactionMessageIdentifier.AmendedCase, component: KnownComponents.Case);
        }
    }

    public class ActivityAttachmentMaintenanceFixture : IFixture<ActivityAttachmentMaintenanceBase>
    {
        public ActivityAttachmentMaintenanceFixture(InMemoryDbContext db)
        {
            ActivityMaintenance = Substitute.For<IActivityMaintenance>();
            AttachmentMaintenance = Substitute.For<IAttachmentMaintenance>();
            Actions = Substitute.For<IActions>();
            CultureResolver = Substitute.For<IPreferredCultureResolver>();
            TransactionRecordal = Substitute.For<ITransactionRecordal>();

            Subject = new CaseActivityAttachmentMaintenance(AttachmentFor.Case, db, AttachmentMaintenance, ActivityMaintenance, Actions, CultureResolver, Substitute.For<IAttachmentContentLoader>(), TransactionRecordal);
        }

        public IActivityMaintenance ActivityMaintenance { get; set; }
        public IAttachmentMaintenance AttachmentMaintenance { get; set; }
        public IActions Actions { get; set; }
        public IPreferredCultureResolver CultureResolver { get; set; }
        public ITransactionRecordal TransactionRecordal { get; set; }
        public ActivityAttachmentMaintenanceBase Subject { get; }
    }
}