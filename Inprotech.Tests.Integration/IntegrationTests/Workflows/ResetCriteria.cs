using System.Data.Entity;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class ResetCriteria : IntegrationTest
    {
        [Test]
        public void ResetEventsAndEntries()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var addEvent = setup.InsertWithNewId(new Event());
                var deleteEvent = setup.InsertWithNewId(new Event());

                f.ChildValidEvent.Inherited = 0;

                // setup due date calc that will be removed when common event is re-inherited
                setup.Insert(new DueDateCalc(f.ChildValidEvent, 1) { FromEventId = addEvent.Id, DeadlinePeriod = 1, PeriodType = "W", RelativeCycle = 1, Cycle = 1 });
                setup.Insert(new ValidEvent(f.CriteriaId, addEvent.Id, "Event to be added"));
                setup.Insert(new ValidEvent(f.ChildCriteriaId, deleteEvent.Id, "Event to be deleted"));

                setup.Insert(new DataEntryTask(f.CriteriaId, 0) {Description = "ADD ME", DisplaySequence = 3});
                var updateTask = setup.Insert(new DataEntryTask(f.CriteriaId, 1) { Description = "I got updated", DisplaySequence = 1 });
                setup.Insert(new AvailableEvent(updateTask, addEvent, deleteEvent));
                setup.Insert(new DataEntryTask(f.ChildCriteriaId, 0) { Description = "I got updated***", ParentCriteriaId = f.CriteriaId});
                setup.Insert(new DataEntryTask(f.ChildCriteriaId, 1) { Description = "I'll Get Deleted" });

                return new
                {
                    UpdatedEvent = f.EventId,
                    CriteriaId = f.ChildCriteriaId,
                    ChildId = f.GrandchildCriteriaId,
                    AddEvent = addEvent.Id,
                    DeleteEvent = deleteEvent.Id
                };
            });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/reset?applyToDescendants=true", null);

            using (var dbContext = new SqlDbContext())
            {
                // events
                var updatedEvent = dbContext.Set<ValidEvent>().Include(_ => _.DueDateCalcs).Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.UpdatedEvent && _.Inherited == 1);
                Assert.IsTrue(!updatedEvent.DueDateCalcs.Any(), "Due Date calc not in parent should be removed");

                var otherEvents = dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == data.CriteriaId && _.EventId != data.UpdatedEvent).ToArray();
                Assert.IsTrue(otherEvents.SingleOrDefault(_ => _.EventId == data.AddEvent) != null, "Event in parent should be added");
                Assert.IsTrue(otherEvents.SingleOrDefault(_ => _.EventId == data.DeleteEvent) == null, "Event not in parent should be deleted");

                // entries
                var entries = dbContext.Set<DataEntryTask>().Where(_ => _.CriteriaId == data.CriteriaId && _.Inherited == 1).ToArray();
                var added = entries.SingleOrDefault(_ => _.Description == "ADD ME");
                Assert.NotNull(added, "Should add entry from parent");
                Assert.AreEqual(3, added.DisplaySequence, "Event display sequence should be same as parent");
                
                var updated = entries.SingleOrDefault(_ => _.Description == "I got updated");
                Assert.NotNull(updated);
                Assert.AreEqual(1, updated.AvailableEvents.Count, "Available event should be inherited from parent");
                Assert.AreEqual(1, updated.DisplaySequence, "Entry display sequence should be same as parent");

                Assert.Null(entries.SingleOrDefault(_ => _.Description == "I'll Get Deleted"), "Should delete entry not in parent");
            }
        }
    }
}