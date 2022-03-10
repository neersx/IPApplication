using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class EventToUpdateTest : IntegrationTest
    {
        [Test]
        public void AddEventToUpdate()
        {
            var data = DbSetup.Do(setup =>
            {
                var inheritanceFixture = new EventControlDbSetup().SetupCriteriaInheritance();
                var existingEvent = setup.InsertWithNewId(new Event());
                setup.Insert(new RelatedEventRule(inheritanceFixture.ChildCriteriaId, inheritanceFixture.EventId, 0) { UpdateEvent = 1, RelatedEventId = existingEvent.Id });
                var dateAdjustment = setup.InsertWithNewId(new DateAdjustment());

                return new
                {
                    inheritanceFixture.EventId,
                    inheritanceFixture.CriteriaId,
                    ChildId = inheritanceFixture.ChildCriteriaId,
                    GrandchildId = inheritanceFixture.GrandchildCriteriaId,
                    inheritanceFixture.Importance,
                    ExistingEventToUpdate = existingEvent.Id,
                    DateAdjustment = dateAdjustment.Id
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                ChangeRespOnDueDates = false,
                EventsToUpdateDelta = new Delta<RelatedEventRuleSaveModel> { Added = new List<RelatedEventRuleSaveModel>() }
            }.WithMandatoryFields();

            formData.EventsToUpdateDelta.Added.Add(new RelatedEventRuleSaveModel { EventToUpdateId = data.EventId, RelativeCycle = 2, AdjustDate = data.DateAdjustment });
            formData.EventsToUpdateDelta.Added.Add(new RelatedEventRuleSaveModel { EventToUpdateId = data.ExistingEventToUpdate, RelativeCycle = 1 }); // existing in child

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var criteriaEventsToUpdate = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).RelatedEvents.WhereEventsToUpdate();
                var childEventsToUpdate = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId).RelatedEvents.WhereEventsToUpdate().Where(_ => _.IsInherited).ToArray();
                var grandchildEventsToUpdate = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId).RelatedEvents.WhereEventsToUpdate().Where(_ => _.IsInherited).ToArray();

                Assert.AreEqual(2, criteriaEventsToUpdate.Count(), "Adds new update event.");
                Assert.AreEqual(1, childEventsToUpdate.Length, "Adds update Event to child");
                Assert.AreEqual(2, childEventsToUpdate.First().RelativeCycleId, "Adds update Event with correct data");
                Assert.AreEqual(data.DateAdjustment, childEventsToUpdate.First().DateAdjustmentId, "Adds update Event with correct data");
                Assert.AreEqual(1, grandchildEventsToUpdate.Length, "Adds update Event to grandchild");
                Assert.AreEqual(2, grandchildEventsToUpdate.First().RelativeCycleId, "Adds update Event with correct data");
                Assert.AreEqual(data.DateAdjustment, grandchildEventsToUpdate.First().DateAdjustmentId, "Adds update Event with correct data");
            }
        }
        
        [Test]
        public void UpdateEventToUpdate()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var eventBuilder = new EventBuilder(setup.DbContext);
                var updateEvent = eventBuilder.Create();

                var existingDateAdjustment = setup.InsertWithNewId(new DateAdjustment());
                var dateAdjustment = setup.InsertWithNewId(new DateAdjustment());

                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 0) {UpdateEvent = 1, RelatedEventId = updateEvent.Id, RelativeCycleId = 0, DateAdjustmentId = existingDateAdjustment.Id});
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 0) {Inherited = 1, UpdateEvent = 1, RelatedEventId = updateEvent.Id, RelativeCycleId = 0, DateAdjustmentId = existingDateAdjustment.Id });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 0) {Inherited = 0, UpdateEvent = 1, RelatedEventId = updateEvent.Id, RelativeCycleId = 0, DateAdjustmentId = existingDateAdjustment.Id });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance,
                    NewEventToUpdate = eventBuilder.Create().Id,
                    NewRelativeCycle = (short) 1,
                    DateAdjustment = dateAdjustment.Id
                };
            });

            var updates = new List<RelatedEventRuleSaveModel>
            {
                new RelatedEventRuleSaveModel
                {
                    Sequence = 0,
                    EventToUpdateId = data.NewEventToUpdate,
                    RelativeCycle = data.NewRelativeCycle,
                    AdjustDate = data.DateAdjustment
                }
            };

            var formData = new WorkflowEventControlSaveModel
            {
                Description = "Apple",
                MaxCycles = 1,
                ApplyToDescendants = true,
                ImportanceLevel = data.ImportanceLevel,
                EventsToUpdateDelta = new Delta<RelatedEventRuleSaveModel> {Updated = updates}
            };

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<RelatedEventRule>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var child = dbContext.Set<RelatedEventRule>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var grandchild = dbContext.Set<RelatedEventRule>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(data.NewEventToUpdate, parent.RelatedEventId, "Updates update Event");
                Assert.AreEqual(data.NewRelativeCycle, parent.RelativeCycleId, "Updates update Relative Cycle");
                Assert.AreEqual(data.DateAdjustment, parent.DateAdjustmentId, "Updates update Date Adjustment");

                Assert.AreEqual(data.NewEventToUpdate, child.RelatedEventId, "Updates inherited child update Event");
                Assert.AreEqual(data.NewRelativeCycle, child.RelativeCycleId, "Updates inherited child Relative Cycle");
                Assert.AreEqual(data.DateAdjustment, child.DateAdjustmentId, "Updates inherited child Date Adjustment");

                Assert.AreNotEqual(data.NewEventToUpdate, grandchild.RelatedEventId, "Does not Update uninherited grandchild");
                Assert.AreNotEqual(data.NewRelativeCycle, grandchild.RelativeCycleId, "Does not Update uninherited grandchild");
                Assert.AreNotEqual(data.DateAdjustment, grandchild.DateAdjustmentId, "Does not Update uninherited grandchild");
            }
        }

        [Test]
        public void DeleteEventToUpdate()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var child1 = new CriteriaBuilder(setup.DbContext).Create("child1", f.CriteriaId);
                var childValidEvent1 = setup.Insert(new ValidEvent(child1.Id, f.EventId, "Pear") { NumberOfCyclesAllowed = 1, Inherited = 1 });

                var @event = new EventBuilder(setup.DbContext).Create();
                var dateAdjustment = setup.InsertWithNewId(new DateAdjustment());

                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 0) { UpdateEvent = 1, Sequence = 0, RelatedEventId = @event.Id, RelativeCycleId = 1, Inherited = 1, DateAdjustmentId = dateAdjustment.Id });
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 0) { UpdateEvent = 1, Sequence = 1, RelatedEventId = @event.Id, RelativeCycleId = 1, Inherited = 1, DateAdjustmentId = dateAdjustment.Id });
                setup.Insert(new RelatedEventRule(childValidEvent1, 0) { UpdateEvent = 1, Sequence = 2, RelatedEventId = @event.Id, RelativeCycleId = 1, Inherited = 0, DateAdjustmentId = dateAdjustment.Id });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 0) { UpdateEvent = 1, Sequence = 0, RelatedEventId = @event.Id, RelativeCycleId = 1, Inherited = 0, DateAdjustmentId = dateAdjustment.Id });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    Child1Id = child1.Id,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance,
                    EventToUpdateId = @event.Id
                };
            });

            var deletes = new List<RelatedEventRuleSaveModel>
            {
                new RelatedEventRuleSaveModel
                {
                    Sequence = 0,
                    EventToUpdateId = data.EventToUpdateId
                }
            };

            var formData = new WorkflowEventControlSaveModel
            {
                Description = "Apple",
                MaxCycles = 1,
                ChangeRespOnDueDates = false,
                ApplyToDescendants = true,
                ImportanceLevel = data.ImportanceLevel,
                EventsToUpdateDelta = new Delta<RelatedEventRuleSaveModel> { Deleted = deletes }
            };

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentCount = dbContext.Set<RelatedEventRule>().Count(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var childCount = dbContext.Set<RelatedEventRule>().Count(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var child1Count = dbContext.Set<RelatedEventRule>().Count(_ => _.CriteriaId == data.Child1Id && _.EventId == data.EventId);
                var grandchildCount = dbContext.Set<RelatedEventRule>().Count(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(0, parentCount, "Deletes update event.");
                Assert.AreEqual(0, childCount, "Deletes Inherited child update event.");
                Assert.AreEqual(1, child1Count, "Does not delete non inherited child update event.");
                Assert.AreEqual(1, grandchildCount, "Does not delete not-inherited grandchild.");
            }
        }
    }
}