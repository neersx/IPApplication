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
    public class SatisfyingEventTest : IntegrationTest
    {
        [Test]
        public void AddSatisfyingEvent()
        {
            var data = DbSetup.Do(setup =>
            {
                var inheritanceFixture = new EventControlDbSetup().SetupCriteriaInheritance();
                var existingEvent = setup.InsertWithNewId(new Event());
                setup.Insert(new RelatedEventRule(inheritanceFixture.ChildCriteriaId, inheritanceFixture.EventId, 0) { SatisfyEvent = 1, RelatedEventId = existingEvent.Id, RelativeCycleId = 1});

                return new
                {
                    inheritanceFixture.EventId,
                    inheritanceFixture.CriteriaId,
                    ChildId = inheritanceFixture.ChildCriteriaId,
                    GrandchildId = inheritanceFixture.GrandchildCriteriaId,
                    inheritanceFixture.Importance,
                    ExistingEventToUpdate = existingEvent.Id
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                ChangeRespOnDueDates = false,
                SatisfyingEventsDelta = new Delta<RelatedEventRuleSaveModel> { Added = new List<RelatedEventRuleSaveModel>() }
            }.WithMandatoryFields();

            formData.SatisfyingEventsDelta.Added.Add(new RelatedEventRuleSaveModel { RelatedEventId = data.EventId, RelativeCycle = 2 });
            formData.SatisfyingEventsDelta.Added.Add(new RelatedEventRuleSaveModel { RelatedEventId = data.ExistingEventToUpdate, RelativeCycle = 1 }); // existing in child

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var criteriaSatisfyingEvents = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId).RelatedEvents.Where(_ => _.SatisfyEvent == 1);
                var childSatisfyingEvents = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId).RelatedEvents.Where(_ => _.SatisfyEvent == 1 && _.Inherited == 1).ToArray();
                var grandchildSatisfyingEvents = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId).RelatedEvents.Where(_ => _.SatisfyEvent == 1 && _.Inherited == 1).ToArray();

                Assert.AreEqual(2, criteriaSatisfyingEvents.Count(), "Adds new satisfying event.");
                Assert.AreEqual(1, childSatisfyingEvents.Length, "Adds Satisfying Event to child");
                Assert.AreEqual(2, childSatisfyingEvents.First().RelativeCycleId, "Adds Satisfying Event with correct data");
                Assert.AreEqual(1, grandchildSatisfyingEvents.Length, "Adds Satisfying Event to grandchild");
                Assert.AreEqual(2, grandchildSatisfyingEvents.First().RelativeCycleId, "Adds Satisfying Event with correct data");
            }
        }

        [Test]
        public void UpdateSatisfyingEvent()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var eventBuilder = new EventBuilder(setup.DbContext);
                var satisfyingEvent = eventBuilder.Create();

                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 0) { SatisfyEvent = 1, RelatedEventId = satisfyingEvent.Id, RelativeCycleId = 0 });
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 0) { Inherited = 1, SatisfyEvent = 1, RelatedEventId = satisfyingEvent.Id, RelativeCycleId = 0 });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 0) { Inherited = 0, SatisfyEvent = 1, RelatedEventId = satisfyingEvent.Id, RelativeCycleId = 0 });

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
                    SatisfyingEventId = data.NewEventToUpdate,
                    RelativeCycle = data.NewRelativeCycle
                }
            };

            var formData = new WorkflowEventControlSaveModel
            {
                Description = "Apple",
                MaxCycles = 1,
                ApplyToDescendants = true,
                ImportanceLevel = data.ImportanceLevel,
                SatisfyingEventsDelta = new Delta<RelatedEventRuleSaveModel> { Updated = updates }
            };

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<RelatedEventRule>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var child = dbContext.Set<RelatedEventRule>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var grandchild = dbContext.Set<RelatedEventRule>().Single(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(data.NewEventToUpdate, parent.RelatedEventId, "Updates Satisfying Event");
                Assert.AreEqual(data.NewRelativeCycle, parent.RelativeCycleId, "Updates Satisfying Relative Cycle");

                Assert.AreEqual(data.NewEventToUpdate, child.RelatedEventId, "Updates inherited child Satisfying Event");
                Assert.AreEqual(data.NewRelativeCycle, child.RelativeCycleId, "Updates inherited child Relative Cycle");

                Assert.AreNotEqual(data.NewEventToUpdate, grandchild.RelatedEventId, "Does not Update uninherited grandchild");
                Assert.AreNotEqual(data.NewRelativeCycle, grandchild.RelativeCycleId, "Does not Update uninherited grandchild");
            }
        }

        [Test]
        public void DeleteSatisfyingEvent()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var child1 = new CriteriaBuilder(setup.DbContext).Create("child1", f.CriteriaId);
                var childValidEvent1 = setup.Insert(new ValidEvent(child1.Id, f.EventId, "Pear") { NumberOfCyclesAllowed = 1, Inherited = 1 });

                var satisfyingEvent = new EventBuilder(setup.DbContext).Create();

                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 0) { SatisfyEvent = 1, Sequence = 0, RelatedEventId = satisfyingEvent.Id, RelativeCycleId = 1, Inherited = 1 });
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 0) { SatisfyEvent = 1, Sequence = 1, RelatedEventId = satisfyingEvent.Id, RelativeCycleId = 1, Inherited = 1 });
                setup.Insert(new RelatedEventRule(childValidEvent1, 0) { SatisfyEvent = 1, Sequence = 2, RelatedEventId = satisfyingEvent.Id, RelativeCycleId = 1, Inherited = 0 });
                setup.Insert(new RelatedEventRule(f.GrandchildValidEvent, 0) { SatisfyEvent = 1, Sequence = 0, RelatedEventId = satisfyingEvent.Id, RelativeCycleId = 1, Inherited = 0 });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    Child1Id = child1.Id,
                    GrandchildId = f.GrandchildCriteriaId,
                    ImportanceLevel = f.Importance,
                    EventToUpdateId = satisfyingEvent.Id
                };
            });

            var deletes = new List<RelatedEventRuleSaveModel>
            {
                new RelatedEventRuleSaveModel
                {
                    Sequence = 0,
                    SatisfyingEventId = data.EventToUpdateId
                }
            };

            var formData = new WorkflowEventControlSaveModel
            {
                Description = "Apple",
                MaxCycles = 1,
                ChangeRespOnDueDates = false,
                ApplyToDescendants = true,
                ImportanceLevel = data.ImportanceLevel,
                SatisfyingEventsDelta = new Delta<RelatedEventRuleSaveModel> { Deleted = deletes }
            };

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parentCount = dbContext.Set<RelatedEventRule>().Count(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var childCount = dbContext.Set<RelatedEventRule>().Count(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);
                var child1Count = dbContext.Set<RelatedEventRule>().Count(_ => _.CriteriaId == data.Child1Id && _.EventId == data.EventId);
                var grandchildCount = dbContext.Set<RelatedEventRule>().Count(_ => _.CriteriaId == data.GrandchildId && _.EventId == data.EventId);

                Assert.AreEqual(0, parentCount, "Deletes satisfying event.");
                Assert.AreEqual(0, childCount, "Deletes Inherited child satisfying event.");
                Assert.AreEqual(1, child1Count, "Does not delete non inherited child satisfying event.");
                Assert.AreEqual(1, grandchildCount, "Does not delete not-inherited grandchild.");
            }
        }
    }
}