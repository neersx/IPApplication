using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class ResetEventControl : IntegrationTest
    {
        [Test]
        public void ResetDueDateCalc()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var addEvent = setup.InsertWithNewId(new Event());
                var updateEvent = setup.InsertWithNewId(new Event());
                var deleteEvent = setup.InsertWithNewId(new Event());

                // add due date calc
                setup.Insert(new DueDateCalc(f.CriteriaValidEvent, 0) {FromEventId = addEvent.Id, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Cycle = 1});

                // update due date calc
                setup.Insert(new DueDateCalc(f.CriteriaValidEvent, 1) {FromEventId = updateEvent.Id, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Cycle = 1, Workday = 2});
                setup.Insert(new DueDateCalc(f.ChildValidEvent, 0) {FromEventId = updateEvent.Id, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Cycle = 1, Workday = 1});
                setup.Insert(new DueDateCalc(f.GrandchildValidEvent, 0) {FromEventId = updateEvent.Id, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Cycle = 1, Workday = 1, IsInherited = true});

                // delete due date calc
                setup.Insert(new DueDateCalc(f.ChildValidEvent, 1) {FromEventId = deleteEvent.Id, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Cycle = 1});
                setup.Insert(new DueDateCalc(f.GrandchildValidEvent, 1) {FromEventId = deleteEvent.Id, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Cycle = 1, IsInherited = true});

                return new
                {
                    f.EventId,
                    CriteriaId = f.ChildCriteriaId,
                    ChildId = f.GrandchildCriteriaId,
                    AddEvent = addEvent.Id,
                    UpdateEvent = updateEvent.Id,
                    DeleteEvent = deleteEvent.Id
                };
            });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId + "/reset?applyToDescendants=true", null);

            using (var dbContext = new SqlDbContext())
            {
                var addedDueDateCalc = dbContext.Set<DueDateCalc>().SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.FromEventId == data.AddEvent);
                var updatedDueDateCalc = dbContext.Set<DueDateCalc>().Single(_ => _.CriteriaId == data.CriteriaId && _.FromEventId == data.UpdateEvent);
                var deletedDueDateCalc = dbContext.Set<DueDateCalc>().SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.FromEventId == data.DeleteEvent);
                var addedChildDueDateCalc = dbContext.Set<DueDateCalc>().SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.FromEventId == data.AddEvent);
                var updatedChildDueDateCalc = dbContext.Set<DueDateCalc>().Single(_ => _.CriteriaId == data.ChildId && _.FromEventId == data.UpdateEvent);
                var deletedChildDueDateCalc = dbContext.Set<DueDateCalc>().SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.FromEventId == data.DeleteEvent);

                Assert.IsNotNull(addedDueDateCalc, "Due Date calc added from parent.");
                Assert.AreEqual(2, updatedDueDateCalc.Workday, "Due Date Calc with same hash as parent updated");
                Assert.IsNull(deletedDueDateCalc, "Due Date calc not in parent gets deleted");

                Assert.IsNotNull(addedChildDueDateCalc, "Added Due Date calc inherited.");
                Assert.AreEqual(2, updatedChildDueDateCalc.Workday, "Updated Due Date Calc inherited");
                Assert.IsNull(deletedChildDueDateCalc, "Deleted Due Date calc inherited");
            }
        }

        [Test]
        public void ResetDateComparison()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var addEvent = setup.InsertWithNewId(new Event());
                var updateEvent = setup.InsertWithNewId(new Event());
                var deleteEvent = setup.InsertWithNewId(new Event());

                // add Date Comparison
                setup.Insert(new DueDateCalc(f.CriteriaValidEvent, 0) {FromEventId = addEvent.Id, Comparison = "<"});

                // update Date Comparison
                setup.Insert(new DueDateCalc(f.CriteriaValidEvent, 1) {FromEventId = updateEvent.Id, Comparison = ">"});
                setup.Insert(new DueDateCalc(f.ChildValidEvent, 0) {FromEventId = updateEvent.Id, Comparison = "="});
                setup.Insert(new DueDateCalc(f.GrandchildValidEvent, 0) {FromEventId = updateEvent.Id, Comparison = "=", IsInherited = true});

                // delete Date Comparison
                setup.Insert(new DueDateCalc(f.ChildValidEvent, 1) {FromEventId = deleteEvent.Id, Comparison = "<>"});
                setup.Insert(new DueDateCalc(f.GrandchildValidEvent, 1) {FromEventId = deleteEvent.Id, Comparison = "<>", IsInherited = true});

                return new
                {
                    f.EventId,
                    CriteriaId = f.ChildCriteriaId,
                    ChildId = f.GrandchildCriteriaId,
                    AddEvent = addEvent.Id,
                    UpdateEvent = updateEvent.Id,
                    DeleteEvent = deleteEvent.Id
                };
            });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId + "/reset?applyToDescendants=true", null);

            using (var dbContext = new SqlDbContext())
            {
                var addedDateComparison = dbContext.Set<DueDateCalc>().SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.FromEventId == data.AddEvent);
                var updatedDateComparison = dbContext.Set<DueDateCalc>().Single(_ => _.CriteriaId == data.CriteriaId && _.FromEventId == data.UpdateEvent);
                var deletedDateComparison = dbContext.Set<DueDateCalc>().SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.FromEventId == data.DeleteEvent);
                var addedChildDateComparison = dbContext.Set<DueDateCalc>().SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.FromEventId == data.AddEvent);
                var updatedChildDateComparison = dbContext.Set<DueDateCalc>().Single(_ => _.CriteriaId == data.ChildId && _.FromEventId == data.UpdateEvent);
                var deletedChildDateComparison = dbContext.Set<DueDateCalc>().SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.FromEventId == data.DeleteEvent);

                Assert.IsNotNull(addedDateComparison, "Date Comparison added from parent.");
                Assert.AreEqual(">", updatedDateComparison.Comparison, "Date Comparison with same hash as parent updated");
                Assert.IsNull(deletedDateComparison, "Date Comparison not in parent gets deleted");

                Assert.IsNotNull(addedChildDateComparison, "Added Date Comparison inherited.");
                Assert.AreEqual(">", updatedChildDateComparison.Comparison, "Updated Date Comparison inherited");
                Assert.IsNull(deletedChildDateComparison, "Deleted Date Comparison inherited");
            }
        }

        [Test]
        public void ResetDesignatedJurisdiction()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var addJurisdiction = new CountryBuilder(setup.DbContext).Create(Fixture.String(3));
                var deleteJurisdiction = new CountryBuilder(setup.DbContext).Create(Fixture.String(3));

                // add dj
                setup.Insert(new DueDateCalc(f.CriteriaValidEvent, 0) {JurisdictionId = addJurisdiction.Id});

                // delete dj
                setup.Insert(new DueDateCalc(f.ChildValidEvent, 0) {JurisdictionId = deleteJurisdiction.Id});
                setup.Insert(new DueDateCalc(f.GrandchildValidEvent, 0) {JurisdictionId = deleteJurisdiction.Id, IsInherited = true});

                // make sure criteria belong to group countries so jurisdiction changes will inherit down.
                var groupJurisdiction = new CountryBuilder(setup.DbContext) {Type = "1"}.Create(Fixture.String(5));
                setup.DbContext.Set<Criteria>().Single(_ => _.Id == f.CriteriaId).CountryId = groupJurisdiction.Id;
                setup.DbContext.Set<Criteria>().Single(_ => _.Id == f.ChildCriteriaId).CountryId = groupJurisdiction.Id;
                setup.DbContext.Set<Criteria>().Single(_ => _.Id == f.GrandchildCriteriaId).CountryId = groupJurisdiction.Id;
                setup.DbContext.SaveChanges();

                return new
                {
                    f.EventId,
                    CriteriaId = f.ChildCriteriaId,
                    ChildId = f.GrandchildCriteriaId,
                    AddJurisdictionId = addJurisdiction.Id,
                    DeleteJurisdictionId = deleteJurisdiction.Id
                };
            });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId + "/reset?applyToDescendants=true", null);

            using (var dbContext = new SqlDbContext())
            {
                var addedJurisdiction = dbContext.Set<DueDateCalc>().SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.JurisdictionId == data.AddJurisdictionId);
                var deletedJurisdiction = dbContext.Set<DueDateCalc>().SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.JurisdictionId == data.DeleteJurisdictionId);
                var addedChildJurisdiction = dbContext.Set<DueDateCalc>().SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.JurisdictionId == data.AddJurisdictionId);
                var deletedChildJurisdiction = dbContext.Set<DueDateCalc>().SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.JurisdictionId == data.DeleteJurisdictionId);

                Assert.IsNotNull(addedJurisdiction, "Jurisdiction added from parent.");
                Assert.IsNull(deletedJurisdiction, "Jurisdiction not in parent gets deleted");

                Assert.IsNotNull(addedChildJurisdiction, "Added Jurisdiction inherited.");
                Assert.IsNull(deletedChildJurisdiction, "Deleted Jurisdiction inherited");
            }
        }

        [Test]
        public void ResetDateEntryRules()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var addEvent = setup.InsertWithNewId(new Event());
                var deleteEvent = setup.InsertWithNewId(new Event());

                // add Date Entry Rule
                setup.Insert(new DatesLogic(f.CriteriaValidEvent, 0) {Operator = "<", CompareEventId = addEvent.Id, RelativeCycle = 1, ErrorMessage = "ABC"});

                // delete Date Entry Rule
                setup.Insert(new DatesLogic(f.ChildValidEvent, 1) {Operator = ">", CompareEventId = deleteEvent.Id, RelativeCycle = 1, ErrorMessage = "ABC"});
                setup.Insert(new DatesLogic(f.GrandchildValidEvent, 1) {Operator = ">", CompareEventId = deleteEvent.Id, RelativeCycle = 1, ErrorMessage = "ABC", IsInherited = true});

                return new
                {
                    f.EventId,
                    CriteriaId = f.ChildCriteriaId,
                    ChildId = f.GrandchildCriteriaId,
                    AddEvent = addEvent.Id,
                    DeleteEvent = deleteEvent.Id
                };
            });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId + "/reset?applyToDescendants=true", null);

            using (var dbContext = new SqlDbContext())
            {
                var addedDateEntryRule = dbContext.Set<DatesLogic>().SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.CompareEventId == data.AddEvent);
                var deletedDateEntryRule = dbContext.Set<DatesLogic>().SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.CompareEventId == data.DeleteEvent);
                var addedChildDateEntryRule = dbContext.Set<DatesLogic>().SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.CompareEventId == data.AddEvent);
                var deletedChildDateEntryRule = dbContext.Set<DatesLogic>().SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.CompareEventId == data.DeleteEvent);

                Assert.IsNotNull(addedDateEntryRule, "Date Entry Rule added from parent.");
                Assert.IsNull(deletedDateEntryRule, "Date Entry Rule not in parent gets deleted");

                Assert.IsNotNull(addedChildDateEntryRule, "Added Date Entry Rule inherited.");
                Assert.IsNull(deletedChildDateEntryRule, "Deleted Date Entry Rule inherited");
            }
        }

        [Test]
        public void ResetReminderAndDocument()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                // add Reminder
                setup.Insert(new ReminderRule(f.CriteriaValidEvent, 0) {Message1 = "ABC", SendElectronically = 1, EmailSubject = "DEF", LeadTime = 3, PeriodType = "M", Frequency = 2, FreqPeriodType = "D"});

                // delete Reminder
                setup.Insert(new ReminderRule(f.ChildValidEvent, 0) {Message1 = "XYZ", SendElectronically = 1, EmailSubject = "UVW", LeadTime = 3, PeriodType = "M", Frequency = 2, FreqPeriodType = "D"});
                setup.Insert(new ReminderRule(f.GrandchildValidEvent, 0) {Message1 = "XYZ", SendElectronically = 1, EmailSubject = "UVW", LeadTime = 3, PeriodType = "M", Frequency = 2, FreqPeriodType = "D", IsInherited = true});

                var addDocument = setup.InsertWithNewId(new Document {Name = Fixture.String(5)});
                var deleteDocument = setup.InsertWithNewId(new Document {Name = Fixture.String(5)});

                // add Document
                setup.Insert(new ReminderRule(f.CriteriaValidEvent, 1) {LetterNo = addDocument.Id, UpdateEvent = 1, LeadTime = 1, PeriodType = "W", Frequency = 1, FreqPeriodType = "D"});

                // delete Document
                setup.Insert(new ReminderRule(f.ChildValidEvent, 1) {LetterNo = deleteDocument.Id, UpdateEvent = 1, LeadTime = 1, PeriodType = "W", Frequency = 1, FreqPeriodType = "D"});
                setup.Insert(new ReminderRule(f.GrandchildValidEvent, 1) {LetterNo = deleteDocument.Id, UpdateEvent = 1, LeadTime = 1, PeriodType = "W", Frequency = 1, FreqPeriodType = "D", IsInherited = true});

                return new
                {
                    f.EventId,
                    CriteriaId = f.ChildCriteriaId,
                    ChildId = f.GrandchildCriteriaId,
                    AddEmailSubject = "DEF",
                    DeleteEmailSubject = "UVW",
                    AddDocumentId = addDocument.Id,
                    DeleteDocumentId = deleteDocument.Id
                };
            });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId + "/reset?applyToDescendants=true", null);

            using (var dbContext = new SqlDbContext())
            {
                var reminders = dbContext.Set<ReminderRule>().Where(_ => new[] {data.CriteriaId, data.ChildId}.Contains(_.CriteriaId) && _.EventId == data.EventId);
                var addedReminderRule = reminders.SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.EmailSubject == data.AddEmailSubject);
                var deletedReminderRule = reminders.SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.EmailSubject == data.DeleteEmailSubject);
                var addedChildReminderRule = reminders.SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.EmailSubject == data.AddEmailSubject);
                var deletedChildReminderRule = reminders.SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.EmailSubject == data.DeleteEmailSubject);

                Assert.IsNotNull(addedReminderRule, "Reminder Rule added from parent.");
                Assert.IsNull(deletedReminderRule, "Reminder Rule not in parent gets deleted");

                Assert.IsNotNull(addedChildReminderRule, "Added Reminder Rule inherited.");
                Assert.IsNull(deletedChildReminderRule, "Deleted Reminder Rule inherited");

                var addedDocumentRule = reminders.SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.LetterNo == data.AddDocumentId);
                var deletedDocumentRule = reminders.SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.LetterNo == data.DeleteDocumentId);
                var addedChildDocumentRule = reminders.SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.LetterNo == data.AddDocumentId);
                var deletedChildDocumentRule = reminders.SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.LetterNo == data.DeleteDocumentId);

                Assert.IsNotNull(addedDocumentRule, "Document Rule added from parent.");
                Assert.IsNull(deletedDocumentRule, "Document Rule not in parent gets deleted");

                Assert.IsNotNull(addedChildDocumentRule, "Added Document Rule inherited.");
                Assert.IsNull(deletedChildDocumentRule, "Deleted Document Rule inherited");
            }
        }

        [Test]
        public void ResetSatisfyingEventClearEventUpdateEvent()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var addEvent = setup.InsertWithNewId(new Event());
                var updateEvent = setup.InsertWithNewId(new Event());
                var deleteEvent = setup.InsertWithNewId(new Event());

                // add SatisfyingEvent
                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 0) { RelatedEventId = addEvent.Id, RelativeCycleId = 1, IsSatisfyingEvent = true });
                // update SatisfyingEvent
                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 1) { RelatedEventId = updateEvent.Id, RelativeCycleId = 2, IsSatisfyingEvent = true });
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 0) { RelatedEventId = updateEvent.Id, RelativeCycleId = 3, IsSatisfyingEvent = true });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 0) { RelatedEventId = updateEvent.Id, RelativeCycleId = 3, IsSatisfyingEvent = true, IsInherited = true });
                // delete SatisfyingEvent
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 1) { RelatedEventId = deleteEvent.Id, RelativeCycleId = 4, IsSatisfyingEvent = true });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 1) { RelatedEventId = deleteEvent.Id, RelativeCycleId = 4, IsSatisfyingEvent = true, IsInherited = true });
                
                // add Event To Clear
                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 2) { RelatedEventId = addEvent.Id, RelativeCycleId = 1, ClearDue = 1, ClearEvent = 1 });
                // update Event To Clear
                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 3) { RelatedEventId = updateEvent.Id, RelativeCycleId = 2, ClearDue = 1 });
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 2) { RelatedEventId = updateEvent.Id, RelativeCycleId = 3, ClearDue = 1 });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 2) { RelatedEventId = updateEvent.Id, RelativeCycleId = 3, ClearDue = 1, IsInherited = true });
                // delete Event To Clear
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 3) { RelatedEventId = deleteEvent.Id, RelativeCycleId = 4, ClearEvent = 1 });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 3) { RelatedEventId = deleteEvent.Id, RelativeCycleId = 4, ClearEvent = 1, IsInherited = true });

                // add Event To Update
                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 4) { RelatedEventId = addEvent.Id, RelativeCycleId = 1, IsUpdateEvent = true });
                // update Event To Update
                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 5) { RelatedEventId = updateEvent.Id, RelativeCycleId = 3, IsUpdateEvent = true });
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 4) { RelatedEventId = updateEvent.Id, RelativeCycleId = 4, IsUpdateEvent = true });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 4) { RelatedEventId = updateEvent.Id, RelativeCycleId = 4, IsUpdateEvent = true, IsInherited = true });
                // delete Event To Update
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 5) { RelatedEventId = deleteEvent.Id, RelativeCycleId = 4, IsUpdateEvent = true });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 5) { RelatedEventId = deleteEvent.Id, RelativeCycleId = 4, IsUpdateEvent = true, IsInherited = true });

                return new
                {
                    f.EventId,
                    CriteriaId = f.ChildCriteriaId,
                    ChildId = f.GrandchildCriteriaId,
                    AddEventId = addEvent.Id,
                    UpdateEventId = updateEvent.Id,
                    DeleteEventId = deleteEvent.Id
                };
            });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId + "/reset?applyToDescendants=true", null);

            using (var dbContext = new SqlDbContext())
            {
                var relatedEvents = dbContext.Set<RelatedEventRule>().Where(_ => new[] { data.CriteriaId, data.ChildId }.Contains(_.CriteriaId) && _.EventId == data.EventId).ToArray();

                var addedSatisfyingEvent = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.AddEventId && _.IsSatisfyingEvent);
                var updatedSatisfyingEvent = relatedEvents.Single(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.UpdateEventId && _.IsSatisfyingEvent);
                var deletedSatisfyingEvent = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.DeleteEventId && _.IsSatisfyingEvent);
                Assert.IsNotNull(addedSatisfyingEvent, "Satisfying Event added from parent.");
                Assert.AreEqual(2, updatedSatisfyingEvent.RelativeCycleId, "Satisfying Event with same hash as parent updated");
                Assert.IsNull(deletedSatisfyingEvent, "Satisfying Event not in parent gets deleted");

                var addedChildSatisfyingEvent = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.AddEventId && _.IsSatisfyingEvent);
                var updatedChildSatisfyingEvent = relatedEvents.Single(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.UpdateEventId && _.IsSatisfyingEvent);
                var deletedChildSatisfyingEvent = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.DeleteEventId && _.IsSatisfyingEvent);
                Assert.IsNotNull(addedChildSatisfyingEvent, "Added Satisfying Event inherited.");
                Assert.AreEqual(2, updatedChildSatisfyingEvent.RelativeCycleId, "Satisfying Event with same hash as parent updated");
                Assert.IsNull(deletedChildSatisfyingEvent, "Deleted Satisfying Event inherited");

                var addedEventToClear = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.AddEventId && _.IsClearEventRule);
                var updatedEventToClear = relatedEvents.Single(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.UpdateEventId && _.IsClearEventRule);
                var deletedEventToClear = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.DeleteEventId && _.IsClearEventRule);
                Assert.IsNotNull(addedEventToClear, "Clear Event added from parent.");
                Assert.AreEqual(2, updatedEventToClear.RelativeCycleId, "Clear Event with same hash as parent updated");
                Assert.IsNull(deletedEventToClear, "Clear Event not in parent gets deleted");

                var addedChildEventToClear = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.AddEventId && _.IsClearEventRule);
                var updatedChildEventToClear = relatedEvents.Single(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.UpdateEventId && _.IsClearEventRule);
                var deletedChildEventToClear = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.DeleteEventId && _.IsClearEventRule);
                Assert.IsNotNull(addedChildEventToClear, "Added Clear Event inherited.");
                Assert.AreEqual(2, updatedChildEventToClear.RelativeCycleId, "Clear Event with same hash as parent updated");
                Assert.IsNull(deletedChildEventToClear, "Deleted Clear Event inherited");

                var addedEventToUpdate = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.AddEventId && _.IsUpdateEvent);
                var updatedEventToUpdate = relatedEvents.Single(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.UpdateEventId && _.IsUpdateEvent);
                var deletedEventToUpdate = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.DeleteEventId && _.IsUpdateEvent);
                Assert.IsNotNull(addedEventToUpdate, "Update Event added from parent.");
                Assert.AreEqual(3, updatedEventToUpdate.RelativeCycleId, "Update Event with same hash as parent updated");
                Assert.IsNull(deletedEventToUpdate, "Update Event not in parent gets deleted");

                var addedChildEventToUpdate = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.AddEventId && _.IsUpdateEvent);
                var updatedChildEventToUpdate = relatedEvents.Single(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.UpdateEventId && _.IsUpdateEvent);
                var deletedChildEventToUpdate = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.DeleteEventId && _.IsUpdateEvent);
                Assert.IsNotNull(addedChildEventToUpdate, "Added Update Event inherited.");
                Assert.AreEqual(3, updatedChildEventToUpdate.RelativeCycleId, "Update Event with same hash as parent updated");
                Assert.IsNull(deletedChildEventToUpdate, "Deleted Update Event inherited");
            }
        }

        [Test]
        public void ResetFromMultiUseRelatedEvent()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var addEvent = setup.InsertWithNewId(new Event());
                var updateEvent = setup.InsertWithNewId(new Event());

                // parent multi-use add rule
                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 0)
                {
                    RelatedEventId = addEvent.Id, RelativeCycleId = 1, IsSatisfyingEvent = true,
                    ClearDue = 1, ClearEvent = 1,
                    IsUpdateEvent = true
                });

                // parent multi-use update rule
                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 1)
                {
                    RelatedEventId = updateEvent.Id,
                    RelativeCycleId = 2,
                    IsSatisfyingEvent = true,
                    ClearDueOnDueChange = true,
                    ClearEventOnDueChange= true,
                    IsUpdateEvent = true
                });

                // update SatisfyingEvent
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 0) { RelatedEventId = updateEvent.Id, RelativeCycleId = 3, IsSatisfyingEvent = true });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 0) { RelatedEventId = updateEvent.Id, RelativeCycleId = 3, IsSatisfyingEvent = true, IsInherited = true });
                
                // update Event To Clear
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 1) { RelatedEventId = updateEvent.Id, RelativeCycleId = 3, ClearDue = 1 });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 1) { RelatedEventId = updateEvent.Id, RelativeCycleId = 3, ClearDue = 1, IsInherited = true });
                
                // update Event To Update
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 2) { RelatedEventId = updateEvent.Id, RelativeCycleId = 4, IsUpdateEvent = true });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 2) { RelatedEventId = updateEvent.Id, RelativeCycleId = 4, IsUpdateEvent = true, IsInherited = true });

                return new
                {
                    f.EventId,
                    CriteriaId = f.ChildCriteriaId,
                    ChildId = f.GrandchildCriteriaId,
                    AddEventId = addEvent.Id,
                    UpdateEventId = updateEvent.Id
                };
            });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId + "/reset?applyToDescendants=true", null);

            using (var dbContext = new SqlDbContext())
            {
                var relatedEvents = dbContext.Set<RelatedEventRule>().Where(_ => new[] { data.CriteriaId, data.ChildId }.Contains(_.CriteriaId) && _.EventId == data.EventId).ToArray();

                var addedSatisfyingEvent = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.AddEventId && _.IsSatisfyingEvent);
                var updatedSatisfyingEvent = relatedEvents.Single(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.UpdateEventId && _.IsSatisfyingEvent);
                Assert.IsNotNull(addedSatisfyingEvent, "Satisfying Event added from parent.");
                Assert.AreEqual(2, updatedSatisfyingEvent.RelativeCycleId, "Satisfying Event with same RelatedEventId as parent updated");

                var addedChildSatisfyingEvent = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.AddEventId && _.IsSatisfyingEvent);
                var updatedChildSatisfyingEvent = relatedEvents.Single(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.UpdateEventId && _.IsSatisfyingEvent);
                Assert.IsNotNull(addedChildSatisfyingEvent, "Added Satisfying Event inherited.");
                Assert.AreEqual(2, updatedChildSatisfyingEvent.RelativeCycleId, "Satisfying Event with same RelatedEventId as parent updated");

                var addedEventToClear = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.AddEventId && _.IsClearEventRule);
                var updatedEventToClear = relatedEvents.Single(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.UpdateEventId && _.IsClearEventRule);
                Assert.IsNotNull(addedEventToClear, "Clear Event added from parent.");
                Assert.AreEqual(2, updatedEventToClear.RelativeCycleId, "Clear Event with same RelatedEventId as parent updated");
                Assert.IsTrue(updatedEventToClear.ClearDueOnDueChange, "Clear Event with same RelatedEventId as parent is updated");
                Assert.IsTrue(updatedEventToClear.ClearEventOnDueChange, "Clear Event with same RelatedEventId as parent is updated");
                Assert.IsTrue(updatedEventToClear.ClearDue.GetValueOrDefault() == 0, "Clear Event with same RelatedEventId as parent is updated");

                var addedChildEventToClear = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.AddEventId && _.IsClearEventRule);
                var updatedChildEventToClear = relatedEvents.Single(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.UpdateEventId && _.IsClearEventRule);
                Assert.IsNotNull(addedChildEventToClear, "Added Clear Event inherited.");
                Assert.AreEqual(2, updatedChildEventToClear.RelativeCycleId, "Clear Event rules inherited");
                Assert.IsTrue(updatedChildEventToClear.ClearDueOnDueChange, "Clear Event rules inherited");
                Assert.IsTrue(updatedChildEventToClear.ClearEventOnDueChange, "Clear Event rules inherited");
                Assert.IsTrue(updatedChildEventToClear.ClearDue.GetValueOrDefault() == 0, "Clear Event rules inherited");

                var addedEventToUpdate = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.AddEventId && _.IsUpdateEvent);
                var updatedEventToUpdate = relatedEvents.Single(_ => _.CriteriaId == data.CriteriaId && _.RelatedEventId == data.UpdateEventId && _.IsUpdateEvent);
                Assert.IsNotNull(addedEventToUpdate, "Update Event added from parent.");
                Assert.AreEqual(2, updatedEventToUpdate.RelativeCycleId, "Update Event with same RelatedEventId as parent updated");

                var addedChildEventToUpdate = relatedEvents.SingleOrDefault(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.AddEventId && _.IsUpdateEvent);
                var updatedChildEventToUpdate = relatedEvents.Single(_ => _.CriteriaId == data.ChildId && _.RelatedEventId == data.UpdateEventId && _.IsUpdateEvent);
                Assert.IsNotNull(addedChildEventToUpdate, "Added Update Event inherited.");
                Assert.AreEqual(2, updatedChildEventToUpdate.RelativeCycleId, "Update Event with same RelatedEventId as parent updated");
            }
        }
    }
}