using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class EventToClearTest : IntegrationTest
    {
        [Test]
        public void AddEventToClear()
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var inheritanceFixture = new EventControlDbSetup().SetupCriteriaInheritance();
                var existingEvent = eventBuilder.Create();
                setup.Insert(new RelatedEventRule(inheritanceFixture.ChildCriteriaId, inheritanceFixture.EventId, 0)
                {
                    RelatedEventId = existingEvent.Id,
                    RelativeCycleId = 1,
                    IsClearEvent = true,
                    IsClearDue = false,
                    ClearEventOnDueChange = true,
                    ClearDueOnDueChange = false
                });

                return new
                {
                    inheritanceFixture.EventId,
                    inheritanceFixture.CriteriaId,
                    ChildId = inheritanceFixture.ChildCriteriaId,
                    GrandchildId = inheritanceFixture.GrandchildCriteriaId,
                    inheritanceFixture.Importance,
                    ExistingEventToClearId = existingEvent.Id
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                ChangeRespOnDueDates = false,
                EventsToClearDelta = new Delta<RelatedEventRuleSaveModel> { Added = new List<RelatedEventRuleSaveModel>() }
            }.WithMandatoryFields();

            formData.EventsToClearDelta.Added.Add(new RelatedEventRuleSaveModel
            {
                RelatedEventId = data.EventId,
                RelativeCycle = 2,
                ClearEventOnEventChange = true,
                ClearDueDateOnEventChange = true,
                ClearEventOnDueDateChange = true,
                ClearDueDateOnDueDateChange = true
            });
            formData.EventsToClearDelta.Added.Add(new RelatedEventRuleSaveModel
            {
                RelatedEventId = data.ExistingEventToClearId,
                RelativeCycle = 1,
                ClearEventOnEventChange = true,
                ClearDueDateOnEventChange = true,
                ClearEventOnDueDateChange = true,
                ClearDueDateOnDueDateChange = true
            }); // existing in child

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentRecords = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).RelatedEvents.WhereEventsToClear().ToArray();
                var childInheritedRecords = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId).RelatedEvents.WhereEventsToClear().Where(_ => _.Inherited == 1).ToArray();
                var grandchildInheritedRecords = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId).RelatedEvents.WhereEventsToClear().Where(_ => _.Inherited == 1).ToArray();

                Assert.AreEqual(2, parentRecords.Length, "Adds new Event to Clear.");
                Assert.AreEqual(1, childInheritedRecords.Length, "Adds Event to Clear to child");

                var theOnlyAddedChildRecord = childInheritedRecords.Single();

                Assert.AreEqual(2, theOnlyAddedChildRecord.RelativeCycleId);
                Assert.IsTrue(theOnlyAddedChildRecord.IsClearEvent);
                Assert.IsTrue(theOnlyAddedChildRecord.IsClearDue);
                Assert.IsTrue(theOnlyAddedChildRecord.ClearEventOnDueChange);
                Assert.IsTrue(theOnlyAddedChildRecord.ClearDueOnDueChange);

                Assert.AreEqual(1, grandchildInheritedRecords.Length, "Adds Event to Clear to grandchild");
                Assert.AreEqual(2, grandchildInheritedRecords.First().RelativeCycleId, "Adds Event to Clear with correct data");
            }
        }

        [Test]
        public void UpdateEventToClear()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var eventBuilder = new EventBuilder(setup.DbContext);
                var eventToClear = eventBuilder.Create();

                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 0)
                {
                    RelatedEventId = eventToClear.Id,
                    RelativeCycleId = 0,
                    ClearDue = 1
                });
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 0)
                {
                    Inherited = 1,
                    RelatedEventId = eventToClear.Id,
                    RelativeCycleId = 0,
                    ClearDue = 1
                });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 0)
                {
                    Inherited = 0,
                    RelatedEventId = eventToClear.Id,
                    RelativeCycleId = 0,
                    ClearEvent = 1
                });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance,
                    NewEventToUpdate = eventBuilder.Create().Id,
                    NewRelativeCycle = (short)1
                };
            });

            var updates = new List<RelatedEventRuleSaveModel>
            {
                new RelatedEventRuleSaveModel
                {
                    Sequence = 0,
                    EventToClearId = data.NewEventToUpdate,
                    RelativeCycle = data.NewRelativeCycle,
                    ClearDueDateOnDueDateChange = false,
                    ClearDueDateOnEventChange = false,
                    ClearEventOnDueDateChange = false,
                    ClearEventOnEventChange = true
                }
            };

            var formData = new WorkflowEventControlSaveModel
            {
                Description = "Apple",
                MaxCycles = 1,
                ApplyToDescendants = true,
                ImportanceLevel = data.ImportanceLevel,
                EventsToClearDelta = new Delta<RelatedEventRuleSaveModel> { Updated = updates }
            };

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).RelatedEvents.WhereEventsToClear().Single();
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId).RelatedEvents.WhereEventsToClear().Single(_ => _.Inherited == 1);
                var grandchild = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId).RelatedEvents.WhereEventsToClear().Single();

                Assert.AreEqual(data.NewEventToUpdate, parent.RelatedEventId, "Updates related event");
                Assert.AreEqual(data.NewRelativeCycle, parent.RelativeCycleId, "Updates relative cycle");
                Assert.IsTrue(parent.IsClearEvent, "Updates clear event");

                Assert.AreEqual(data.NewEventToUpdate, child.RelatedEventId, "Updates inherited child related event");
                Assert.AreEqual(data.NewRelativeCycle, child.RelativeCycleId, "Updates inherited child relative cycle");
                Assert.IsTrue(child.IsClearEvent, "Updates clear event");

                Assert.AreNotEqual(data.NewEventToUpdate, grandchild.RelatedEventId, "Does not Update uninherited grandchild");
                Assert.AreNotEqual(data.NewRelativeCycle, grandchild.RelativeCycleId, "Does not Update uninherited grandchild");
            }
        }

        [Test]
        public void DeleteEventToClear()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var child1 = new CriteriaBuilder(setup.DbContext).Create("child1", f.CriteriaId);
                var childValidEvent1 = setup.Insert(new ValidEvent(child1.Id, f.EventId, "Pear") { NumberOfCyclesAllowed = 1, Inherited = 1 });

                var eventToClear = new EventBuilder(setup.DbContext).Create();

                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 0) { ClearEvent = 1, Sequence = 0, RelatedEventId = eventToClear.Id, RelativeCycleId = 1, Inherited = 1 });
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 0) { ClearEvent = 1, Sequence = 1, RelatedEventId = eventToClear.Id, RelativeCycleId = 1, Inherited = 1 });
                setup.Insert(new RelatedEventRule(childValidEvent1, 0) { ClearEvent = 1, Sequence = 2, RelatedEventId = eventToClear.Id, RelativeCycleId = 1, Inherited = 0 });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 0) { ClearEvent = 1, Sequence = 0, RelatedEventId = eventToClear.Id, RelativeCycleId = 1, Inherited = 0 });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    Child1Id = child1.Id,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance,
                    EventToClearId = eventToClear.Id
                };
            });

            var deletes = new List<RelatedEventRuleSaveModel>
            {
                new RelatedEventRuleSaveModel
                {
                    Sequence = 0,
                    EventToClearId = data.EventToClearId,
                    ClearEventOnDueDateChange = true // we need this to identify it as a clear event rule
                }
            };

            var formData = new WorkflowEventControlSaveModel
            {
                Description = "Apple",
                MaxCycles = 1,
                ApplyToDescendants = true,
                ImportanceLevel = data.ImportanceLevel,
                EventsToClearDelta = new Delta<RelatedEventRuleSaveModel> { Deleted = deletes }
            };

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentCount = dbContext.Set<RelatedEventRule>().Count(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var childCount = dbContext.Set<RelatedEventRule>().Count(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var child1Count = dbContext.Set<RelatedEventRule>().Count(_ => _.CriteriaId == data.Child1Id && _.EventId == data.EventId);
                var grandchildCount = dbContext.Set<RelatedEventRule>().Count(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(0, parentCount, "Deletes event to clear.");
                Assert.AreEqual(0, childCount, "Deletes Inherited child event to clear.");
                Assert.AreEqual(1, child1Count, "Does not delete non inherited child event to clear.");
                Assert.AreEqual(1, grandchildCount, "Does not delete not-inherited grandchild.");
            }
        }
    }
}