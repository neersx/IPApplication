using System.Data.Entity;
using System.Linq;
using System.Net;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class CriteriaInheritanceIntegration : IntegrationTest
    {
        [Test]
        public void BreakInheritanceForCriteria()
        {
            CriteriaInheritanceDbSetup.InheritanceDataFixture dataFixture;
            using (var setup = new CriteriaInheritanceDbSetup())
            {
                dataFixture = setup.SetupForBreakInheritance();
            }

            var result = ApiClient.Delete("configuration/rules/workflows/" + dataFixture.Tree.ChildId + "/inheritance/");

            using (var dbContext = new SqlDbContext())
            {
                Assert.AreEqual(result, HttpStatusCode.NoContent);
                Assert.False(dbContext.Set<Inherits>().Any(_ => _.CriteriaNo == dataFixture.Tree.ChildId));
                Assert.Null(dbContext.Set<Criteria>().Single(_ => _.Id == dataFixture.Tree.ChildId).ParentCriteriaId);
                Assert.True(dbContext.Set<Inherits>().Any(_ => _.CriteriaNo == dataFixture.Tree.GrandchildId));
                Assert.AreEqual(dataFixture.Tree.ChildId, dbContext.Set<Criteria>().Single(_ => _.Id == dataFixture.Tree.GrandchildId).ParentCriteriaId);
                Assert.False(dbContext.Set<ValidEvent>().Single(_ => _.Description == dataFixture.ValidEvent).IsInherited);
                Assert.AreEqual(0, dbContext.Set<DataEntryTask>().Single(_ => _.Id == dataFixture.EntryId).Inherited);
            }
        }

        /*      Without Replace Scenario (Same applies to both Events and Entries)
                Before Move:

                Orphan (SameEvent - ReplacedEventDescription), (NewEvent)
                | 
                Parent (SameEvent - EventDescription)
                    |______Child (SameEvent - EventDescription)
                    |______Child2


                ***************************************

                After Move:

                Orphan (SameEvent - ReplacedEventDescription), (NewEvent)
                        | 
                        Parent (SameEvent - EventDescription), (NewEvent)
                            |______Child (SameEvent - EventDescription), (NewEvent)
                            |______Child2 (NewEvent)
        */

        [Test]
        public void ChangeParentageOfCriteriaWithoutReplace()
        {
            CriteriaInheritanceDbSetup.ChangeParentageDataFixture dataFixture;
            using (var setup = new CriteriaInheritanceDbSetup())
            {
                dataFixture = setup.SetupForChangeParentage(true);
            }

            var body = new WorkflowInheritanceController.ChangeParentInheritanceParams
                       {
                           NewParent = dataFixture.Tree.OrphanId,
                           ReplaceCommonRules = false
                       };

            var result = ApiClient.Put<dynamic>("configuration/rules/workflows/" + dataFixture.Tree.ParentId + "/inheritance/", JsonConvert.SerializeObject(body));

            using (var db = new SqlDbContext())
            {
                var parent = db.Set<Criteria>().Include(_ => _.ValidEvents).Include(_ => _.DataEntryTasks).Single(_ => _.Id == dataFixture.Tree.ParentId);
                var child = db.Set<Criteria>().Include(_ => _.ValidEvents).Include(_ => _.DataEntryTasks).Single(_ => _.Id == dataFixture.Tree.ChildId);
                var child2 = db.Set<Criteria>().Include(_ => _.ValidEvents).Include(_ => _.DataEntryTasks).Single(_ => _.Id == dataFixture.Tree.Child2Id);
                var workflowWizard = db.Set<WindowControl>().Where(_ => new[] { parent.Id, child.Id, child2.Id }.Contains((int)_.CriteriaId));

                Assert.NotNull(db.Set<Inherits>().SingleOrDefault(_ => _.CriteriaNo == parent.Id && _.FromCriteriaNo == dataFixture.Tree.OrphanId), "Parent criteria now inherits from orphan criteria");

                Assert.AreEqual(2, parent.ValidEvents.Count);
                Assert.AreEqual(dataFixture.ValidEvent, parent.ValidEvents.Single(_ => _.EventId == dataFixture.SameEventId).Description, "Moved criteria's event is not replaced (this breaks inheritance for this event down the tree)");
                Assert.AreEqual(dataFixture.NewEvent, parent.ValidEvents.Single(_ => _.EventId == dataFixture.NewEventId).Description);

                Assert.AreEqual(2, child.ValidEvents.Count);
                Assert.AreEqual(dataFixture.ValidEvent, child.ValidEvents.Single(_ => _.EventId == dataFixture.SameEventId).Description, "The same event is not replaced");
                Assert.AreEqual(dataFixture.NewEvent, child.ValidEvents.Single(_ => _.EventId == dataFixture.NewEventId).Description);

                Assert.AreEqual(1, child2.ValidEvents.Count);
                Assert.Null(child2.ValidEvents.SingleOrDefault(_ => _.EventId == dataFixture.SameEventId), "The parent criteria did not re-inherit so Child 2 does not get the non replaced event");
                Assert.AreEqual(dataFixture.NewEvent, child2.ValidEvents.Single(_ => _.EventId == dataFixture.NewEventId).Description, "Child 2 still receives the new event");
                
                Assert.AreEqual(2, parent.DataEntryTasks.Count);
                Assert.NotNull(parent.DataEntryTasks.SingleOrDefault(_ => _.Description == dataFixture.SameEntryDescInChild), "Moved criteria's entry is not replaced (this breaks inheritance for this entry down the tree)");
                Assert.NotNull(parent.DataEntryTasks.SingleOrDefault(_ => _.Description == dataFixture.NewEntryDesc));

                Assert.AreEqual(2, child.DataEntryTasks.Count);
                Assert.NotNull(child.DataEntryTasks.Single(_ => _.Description == dataFixture.SameEntryDescInChild), "The same entry is not replaced");
                Assert.NotNull(child.DataEntryTasks.Single(_ => _.Description == dataFixture.NewEntryDesc));

                Assert.AreEqual(1, child2.DataEntryTasks.Count);
                Assert.Null(child2.DataEntryTasks.SingleOrDefault(_ => _.Description == dataFixture.SameEntryDescInParent), "Child 2 does not receive the same entry because its parent's version wasn't replaced");
                Assert.NotNull(child2.DataEntryTasks.SingleOrDefault(_ => _.Description == dataFixture.NewEntryDesc), "Child 2 still receives the new entry");

                Assert.AreEqual(1, workflowWizard.Single(_ => _.CriteriaId == parent.Id).TopicControls.Count(_=> _.Name == dataFixture.EntryStepName1));
                Assert.AreEqual(1, workflowWizard.Single(_ => _.CriteriaId == child.Id).TopicControls.Count(_ => _.Name == dataFixture.EntryStepName1));
                Assert.AreEqual(1, workflowWizard.Single(_ => _.CriteriaId == child2.Id).TopicControls.Count(_ => _.Name == dataFixture.EntryStepName1));

                Assert.AreEqual(1, workflowWizard.Single(_ => _.CriteriaId == parent.Id).TopicControls.Count(_ => _.Name == dataFixture.EntryStepName2));
                Assert.AreEqual(1, workflowWizard.Single(_ => _.CriteriaId == child.Id).TopicControls.Count(_ => _.Name == dataFixture.EntryStepName2));
                Assert.AreEqual(1, workflowWizard.Single(_ => _.CriteriaId == child2.Id).TopicControls.Count(_ => _.Name == dataFixture.EntryStepName2));

                Assert.True((bool) result.usedByCase, "Criteria was set up as being used by a live case");
            }
        }

        /*  Replace Scenario (Same applies to both Events and Entries)
            Before Move:

            Orphan (SameEvent - ReplacedEventDescription), (NewEvent)
            | 
            Parent (SameEvent - EventDescription)
                |______Child (SameEvent - EventDescription)
                |______Child2


            **************************************

            After Move:

            Orphan (SameEvent - ReplacedEventDescription), (NewEvent)
                    | 
                    Parent (SameEvent - ReplacedEventDescription), (NewEvent)
                        |______Child (SameEvent - ReplacedEventDescription), (NewEvent)
                        |______Child2 (SameEvent - ReplacedEventDescription), (NewEvent)

        */

        [Test]
        public void ChangeParentageOfCriteriaWithReplace()
        {
            CriteriaInheritanceDbSetup.ChangeParentageDataFixture dataFixture;
            using (var setup = new CriteriaInheritanceDbSetup())
            {
                dataFixture = setup.SetupForChangeParentage();
            }

            var body = new WorkflowInheritanceController.ChangeParentInheritanceParams
                       {
                           NewParent = dataFixture.Tree.OrphanId,
                           ReplaceCommonRules = true
                       };

            var result = ApiClient.Put<dynamic>("configuration/rules/workflows/" + dataFixture.Tree.ParentId + "/inheritance/", JsonConvert.SerializeObject(body));

            using (var db = new SqlDbContext())
            {
                var parent = db.Set<Criteria>().Include(_ => _.ValidEvents).Single(_ => _.Id == dataFixture.Tree.ParentId);
                var child = db.Set<Criteria>().Include(_ => _.ValidEvents).Single(_ => _.Id == dataFixture.Tree.ChildId);
                var child2 = db.Set<Criteria>().Include(_ => _.ValidEvents).Single(_ => _.Id == dataFixture.Tree.Child2Id);
                var workflowWizards = db.Set<WindowControl>().Where(_ => new [] {parent.Id,child.Id,child2.Id}.Contains((int)_.CriteriaId));

                Assert.NotNull(db.Set<Inherits>().SingleOrDefault(_ => (_.CriteriaNo == parent.Id) && (_.FromCriteriaNo == dataFixture.Tree.OrphanId)), "Parent criteria now inherits from orphan criteria");

                Assert.AreEqual(2, parent.ValidEvents.Count);
                Assert.AreEqual(dataFixture.ReplacedEvent, parent.ValidEvents.Single(_ => _.EventId == dataFixture.SameEventId).Description, "Event description matches the event it was replaced with");
                Assert.AreEqual(dataFixture.NewEvent, parent.ValidEvents.Single(_ => _.EventId == dataFixture.NewEventId).Description, "New event was also added");

                Assert.AreEqual(2, child.ValidEvents.Count);
                Assert.AreEqual(dataFixture.ReplacedEvent, child.ValidEvents.Single(_ => _.EventId == dataFixture.SameEventId).Description);
                Assert.AreEqual(dataFixture.NewEvent, child.ValidEvents.Single(_ => _.EventId == dataFixture.NewEventId).Description);

                Assert.AreEqual(2, child2.ValidEvents.Count);
                Assert.AreEqual(dataFixture.ReplacedEvent, child2.ValidEvents.Single(_ => _.EventId == dataFixture.SameEventId).Description, "Child 2 receives the replaced event that it didn't have before");
                Assert.AreEqual(dataFixture.NewEvent, child2.ValidEvents.Single(_ => _.EventId == dataFixture.NewEventId).Description);

                Assert.AreEqual(2, parent.DataEntryTasks.Count);
                Assert.NotNull(parent.DataEntryTasks.SingleOrDefault(_ => _.Description == dataFixture.SameEntryDescInParent), "Entry description matches the entry it was replaced with");
                Assert.NotNull(parent.DataEntryTasks.SingleOrDefault(_ => _.Description == dataFixture.NewEntryDesc));

                Assert.AreEqual(2, child.DataEntryTasks.Count);
                Assert.NotNull(child.DataEntryTasks.Single(_ => _.Description == dataFixture.SameEntryDescInParent), "The same entry is also replaced in child");
                Assert.NotNull(child.DataEntryTasks.Single(_ => _.Description == dataFixture.NewEntryDesc));

                Assert.AreEqual(2, child2.DataEntryTasks.Count, "Child 2 receives replaced entry in parent");
                Assert.NotNull(child2.DataEntryTasks.SingleOrDefault(_ => _.Description == dataFixture.SameEntryDescInParent), "Child 2 receives the same entry because its parent's version was replaced");
                Assert.NotNull(child2.DataEntryTasks.SingleOrDefault(_ => _.Description == dataFixture.NewEntryDesc), "Child 2 still receives the new entry");

                Assert.AreEqual(1, workflowWizards.Single(_ => _.CriteriaId == parent.Id).TopicControls.Count(_=> _.Name == dataFixture.EntryStepName1));
                Assert.AreEqual(1, workflowWizards.Single(_ => _.CriteriaId == child.Id).TopicControls.Count(_ => _.Name == dataFixture.EntryStepName1));
                Assert.AreEqual(1, workflowWizards.Single(_ => _.CriteriaId == child2.Id).TopicControls.Count(_ => _.Name == dataFixture.EntryStepName1));

                Assert.AreEqual(1, workflowWizards.Single(_ => _.CriteriaId == parent.Id).TopicControls.Count(_ => _.Name == dataFixture.EntryStepName2));
                Assert.AreEqual(1, workflowWizards.Single(_ => _.CriteriaId == child.Id).TopicControls.Count(_ => _.Name == dataFixture.EntryStepName2));
                Assert.AreEqual(1, workflowWizards.Single(_ => _.CriteriaId == child2.Id).TopicControls.Count(_ => _.Name == dataFixture.EntryStepName2));

                Assert.False((bool) result.usedByCase, "Criteria was not set up to be used by a live case");
            }
        }

        /* Retain order of events and entries
        Before Move:

        Orphan - Events/Entries: A, B, C, D
        | 
        Parent - Events/Entries: C, B, E, F
            |______Child - Events/Entries: C, B, E, F
                    |______Grandchild - Events/Entries: C, B, E, F

        ***************************************

        After Move:
        Orphan - Events/Entries: A, B, C, D
                | 
                Child - Events/Entries: C, B, E, F, A, D
                    |______Grandchild - Events/Entries: C, B, E, F, A, D
        */

        [Test]
        public void ChangingParentageRetainsOrderOfEventsInCriteria()
        {
            CriteriaInheritanceDbSetup.ChangeParentageEventOrderingDataFixture dataFixture;
            using (var setup = new CriteriaInheritanceDbSetup())
            {
                dataFixture = setup.SetupForChangeParentageEventOrdering();
            }

            var body = new WorkflowInheritanceController.ChangeParentInheritanceParams
                       {
                           NewParent = dataFixture.Tree.OrphanId,
                           ReplaceCommonRules = true
                       };

            ApiClient.Put<dynamic>("configuration/rules/workflows/" + dataFixture.Tree.ChildId + "/inheritance/", JsonConvert.SerializeObject(body));

            using (var db = new SqlDbContext())
            {
                var orphanEvents = db.Set<Criteria>().Include(_ => _.ValidEvents).Single(_ => _.Id == dataFixture.Tree.OrphanId).ValidEvents.OrderBy(_ => _.DisplaySequence).Select(_ => _.EventId).ToArray();
                var childEvents = db.Set<Criteria>().Include(_ => _.ValidEvents).Single(_ => _.Id == dataFixture.Tree.ChildId).ValidEvents.OrderBy(_ => _.DisplaySequence).Select(_ => _.EventId).ToArray();
                var grandChildEvents = db.Set<Criteria>().Include(_ => _.ValidEvents).Single(_ => _.Id == dataFixture.Tree.GrandchildId).ValidEvents.OrderBy(_ => _.DisplaySequence).Select(_ => _.EventId).ToArray();

                Assert.AreEqual(4, orphanEvents.Length);
                Assert.AreEqual(dataFixture.EventA, orphanEvents[0]);
                Assert.AreEqual(dataFixture.EventB, orphanEvents[1]);
                Assert.AreEqual(dataFixture.EventC, orphanEvents[2]);
                Assert.AreEqual(dataFixture.EventD, orphanEvents[3]);

                Assert.AreEqual(6, childEvents.Length);
                Assert.AreEqual(dataFixture.EventC, childEvents[0]);
                Assert.AreEqual(dataFixture.EventB, childEvents[1]);
                Assert.AreEqual(dataFixture.EventE, childEvents[2]);
                Assert.AreEqual(dataFixture.EventF, childEvents[3]);
                Assert.AreEqual(dataFixture.EventA, childEvents[4]);
                Assert.AreEqual(dataFixture.EventD, childEvents[5]);

                Assert.AreEqual(6, grandChildEvents.Length);
                Assert.AreEqual(dataFixture.EventC, childEvents[0]);
                Assert.AreEqual(dataFixture.EventB, childEvents[1]);
                Assert.AreEqual(dataFixture.EventE, childEvents[2]);
                Assert.AreEqual(dataFixture.EventF, childEvents[3]);
                Assert.AreEqual(dataFixture.EventA, childEvents[4]);
                Assert.AreEqual(dataFixture.EventD, childEvents[5]);
            }
        }

        [Test]
        public void ChangingParentageRetainsOrderOfEntriesInCriteria()
        {
            CriteriaInheritanceDbSetup.ChangeParentageEntriesOrderingDataFixture dataFixture;
            using (var setup = new CriteriaInheritanceDbSetup())
            {
                dataFixture = setup.SetupForChangeParentageEntriesOrdering();
            }

            var body = new WorkflowInheritanceController.ChangeParentInheritanceParams
            {
                NewParent = dataFixture.Tree.OrphanId,
                ReplaceCommonRules = true
            };

            ApiClient.Put<dynamic>("configuration/rules/workflows/" + dataFixture.Tree.ChildId + "/inheritance/", JsonConvert.SerializeObject(body));

            using (var db = new SqlDbContext())
            {
                var orphanEntries =
                    db.Set<Criteria>()
                      .Include(_ => _.DataEntryTasks)
                      .Single(_ => _.Id == dataFixture.Tree.OrphanId)
                      .DataEntryTasks
                      .OrderBy(_ => _.DisplaySequence)
                      .Select(_ => _.Description)
                      .ToArray();

                var childEvents =
                    db.Set<Criteria>()
                      .Include(_ => _.DataEntryTasks)
                      .Single(_ => _.Id == dataFixture.Tree.ChildId)
                      .DataEntryTasks.OrderBy(_ => _.DisplaySequence)
                      .Select(_ => _.Description).ToArray();
                var grandChildEvents = db.Set<Criteria>()
                                         .Include(_ => _.DataEntryTasks).Single(_ => _.Id == dataFixture.Tree.GrandchildId).DataEntryTasks.OrderBy(_ => _.DisplaySequence).Select(_ => _.Description).ToArray();

                Assert.AreEqual(4, orphanEntries.Length);
                Assert.AreEqual(dataFixture.EntryA, orphanEntries[0]);
                Assert.AreEqual(dataFixture.EntryB, orphanEntries[1]);
                Assert.AreEqual(dataFixture.EntryC, orphanEntries[2]);
                Assert.AreEqual(dataFixture.EntryD, orphanEntries[3]);

                Assert.AreEqual(6, childEvents.Length);
                Assert.AreEqual(dataFixture.EntryC, childEvents[0]);
                Assert.AreEqual(dataFixture.EntryB, childEvents[1]);
                Assert.AreEqual(dataFixture.EntryE, childEvents[2]);
                Assert.AreEqual(dataFixture.EntryF, childEvents[3]);
                Assert.AreEqual(dataFixture.EntryA, childEvents[4]);
                Assert.AreEqual(dataFixture.EntryD, childEvents[5]);

                Assert.AreEqual(6, grandChildEvents.Length);
                Assert.AreEqual(dataFixture.EntryC, childEvents[0]);
                Assert.AreEqual(dataFixture.EntryB, childEvents[1]);
                Assert.AreEqual(dataFixture.EntryE, childEvents[2]);
                Assert.AreEqual(dataFixture.EntryF, childEvents[3]);
                Assert.AreEqual(dataFixture.EntryA, childEvents[4]);
                Assert.AreEqual(dataFixture.EntryD, childEvents[5]);
            }
        }

        [Test]
        public void DeletesCriteriaAndAllRelevantTables()
        {
            var data = DbSetup.Do(setup =>
                                  {
                                      var criteria = setup.InsertWithNewId(new Criteria
                                                                           {
                                                                               Description = Fixture.Prefix("1"),
                                                                               PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                                                           });

                                      var @event = setup.InsertWithNewId(new Event
                                                                         {
                                                                             Description = Fixture.Prefix("event")
                                                                         });

                                      // setup eventcontrol
                                      var eventcontrol = setup.Insert(new ValidEvent(criteria, @event));

                                      setup.Insert(new DueDateCalc(eventcontrol, 0));
                                      setup.Insert(new DatesLogic(eventcontrol, 0));
                                      setup.Insert(new ReminderRule(eventcontrol, 0));
                                      setup.Insert(new RelatedEventRule(eventcontrol, 0));

                                      var nameType = setup.InsertWithNewId(new NameType {Name = Fixture.String(10)});
                                      setup.Insert(new NameTypeMap(eventcontrol, nameType.NameTypeCode, nameType.NameTypeCode, 0));
                                      setup.Insert(new RequiredEventRule(eventcontrol, @event));

                                      // setup entrycontrol
                                      var entry = setup.Insert(new DataEntryTask(criteria, 0));

                                      setup.Insert(new AvailableEvent(entry, @event));

                                      var doc = setup.Insert(new Document(Fixture.String(10), Fixture.String(10)));
                                      setup.Insert(new DocumentRequirement(criteria, entry, doc));

                                      var screen = setup.Insert(new Screen {ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20)});

                                      entry.AddWorkflowWizardStep(new TopicControl(screen.ScreenName) {Title = screen.ScreenTitle });

                                      setup.Insert(new GroupControl {CriteriaId = criteria.Id, EntryId = entry.Id, SecurityGroup = "System Administrator"});

                                      setup.Insert(new UserControl("public", criteria.Id, entry.Id));

                                      return new
                                             {
                                                 CriteriaId = criteria.Id
                                             };
                                  });

            using (var db = new SqlDbContext())
            {
                Assert.IsTrue(db.Set<Criteria>().Any(_ => _.Id == data.CriteriaId));
                Assert.IsTrue(db.Set<ValidEvent>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsTrue(db.Set<DueDateCalc>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsTrue(db.Set<DatesLogic>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsTrue(db.Set<ReminderRule>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsTrue(db.Set<RelatedEventRule>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsTrue(db.Set<NameTypeMap>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsTrue(db.Set<RequiredEventRule>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsTrue(db.Set<DataEntryTask>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsTrue(db.Set<DocumentRequirement>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsTrue(db.Set<WindowControl>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsTrue(db.Set<GroupControl>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsTrue(db.Set<UserControl>().Any(_ => _.CriteriaNo == data.CriteriaId));
            }

            ApiClient.Delete($"configuration/rules/workflows/{data.CriteriaId}");

            using (var db = new SqlDbContext())
            {
                Assert.IsFalse(db.Set<Criteria>().Any(_ => _.Id == data.CriteriaId));
                Assert.IsFalse(db.Set<ValidEvent>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsFalse(db.Set<DueDateCalc>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsFalse(db.Set<DatesLogic>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsFalse(db.Set<ReminderRule>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsFalse(db.Set<RelatedEventRule>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsFalse(db.Set<NameTypeMap>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsFalse(db.Set<RequiredEventRule>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsFalse(db.Set<DataEntryTask>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsFalse(db.Set<DocumentRequirement>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsFalse(db.Set<WindowControl>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsFalse(db.Set<GroupControl>().Any(_ => _.CriteriaId == data.CriteriaId));
                Assert.IsFalse(db.Set<UserControl>().Any(_ => _.CriteriaNo == data.CriteriaId));
            }
        }

        [Test]
        public void ShouldReturnTheEntireFamilyTree()
        {
            CriteriaInheritanceDbSetup.InheritanceDataFixture dataFixture;
            using (var setup = new CriteriaInheritanceDbSetup())
            {
                dataFixture = new CriteriaInheritanceDbSetup.InheritanceDataFixture {Tree = setup.SetupTree()};
            }

            var result = ApiClient.Get<WorkflowInheritanceController.SearchResult>("configuration/rules/workflows/inheritance?criteriaIds=" + dataFixture.Tree.ChildId);
            var root = result.Trees.Single();

            Assert.AreEqual(4, result.TotalCount);
            Assert.AreEqual(dataFixture.ParentName, root.Name);
            Assert.True(root.IsProtected);
            Assert.IsFalse(root.IsInSearch);
            Assert.AreEqual(dataFixture.ChildName, root.Items.First().Name);
            Assert.True(root.Items.First().IsProtected);
            Assert.IsTrue(root.Items.First().IsInSearch);
            Assert.AreEqual(dataFixture.Child2Name, root.Items.Last().Name);
            Assert.False(root.Items.Last().IsProtected);
            Assert.IsFalse(root.Items.Last().IsInSearch);
            Assert.AreEqual(dataFixture.GrandChildName, root.Items.First().Items.Single().Name);
            Assert.False(root.Items.First().Items.Single().IsProtected);
            Assert.IsFalse(root.Items.First().Items.Single().IsInSearch);
        }

        [Test]
        public void ShouldSortByDescriptionAtEachLevel()
        {
            CriteriaInheritanceDbSetup.InheritanceDataFixture dataFixture;
            using (var setup = new CriteriaInheritanceDbSetup())
            {
                dataFixture = new CriteriaInheritanceDbSetup.InheritanceDataFixture {Tree = setup.SetupTree()};
            }

            var results = ApiClient.Get<WorkflowInheritanceController.SearchResult>("configuration/rules/workflows/inheritance?criteriaIds=" + dataFixture.Tree.ParentId + "," + dataFixture.Tree.OrphanId);
            var tree1 = results.Trees.First();
            var tree2 = results.Trees.Last();

            Assert.AreEqual(dataFixture.OrphanName, tree1.Name);
            Assert.AreEqual(dataFixture.ParentName, tree2.Name);
            Assert.AreEqual(dataFixture.ChildName, tree2.Items.First().Name);
            Assert.AreEqual(dataFixture.Child2Name, tree2.Items.Last().Name);
        }
    }
}