using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using NUnit.Framework;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.Entries
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class EntryControlActions : IntegrationTest
    {
        void ResetEntry(bool checkBasedOnFuzzyMatch)
        {
            var data = CriteriaTreeBuilder.Build();
            AddEvents(data);
            AddSteps(data);
            AddDocuments(data);
            AddUserAccess(data);

            var entryToUpdate = data.Child2.FirstEntry();

            if (checkBasedOnFuzzyMatch)
            {
                DbSetup.Do(setup =>
                {
                    var entry = setup.DbContext.Set<DataEntryTask>()
                                     .First(_ => _.Id == entryToUpdate.Id && _.CriteriaId == entryToUpdate.CriteriaId);
                    entry.RemoveInheritance();
                    setup.DbContext.SaveChanges();

                    Assert.AreEqual(3, entry.AvailableEvents.Count, "entry should have 3 events");
                    Assert.AreEqual(3, entry.TaskSteps.SelectMany(_ => _.TopicControls).Count(), "entry should have 4 steps");
                    Assert.AreEqual(2, entry.DocumentRequirements.Count, "entry should have 2 documents");
                    Assert.AreEqual(0, entry.AvailableEvents.Count(_ => _.IsInherited)
                                       + entry.TaskSteps.SelectMany(_ => _.TopicControls).Count(_ => _.IsInherited)
                                       + entry.DocumentRequirements.Count(_ => _.IsInherited), "Nothing should be inherited");
                });
            }

            var res = ApiClient.Post<dynamic>($"configuration/rules/workflows/{entryToUpdate.CriteriaId}/entrycontrol/{entryToUpdate.Id}/reset", string.Empty);

            Assert.NotNull(res);
            Assert.AreEqual("success", res.status.ToString());

            DbSetup.Do(setup =>
            {
                var result = setup.DbContext.Set<DataEntryTask>()
                                  .Where(_ => data.CriteriaIds.Contains(_.CriteriaId))
                                  .ToDictionary(k => k.CriteriaId, v => v);
                var db = new
                {
                    parent = result[data.Parent.Id],
                    child2 = result[data.Child2.Id],
                    grandChild21 = result[data.GrandChild21.Id]
                };
                Assert.AreEqual(3, db.parent.AvailableEvents.Count, "parent should have 3 events");
                Assert.AreEqual(3, db.parent.TaskSteps.SelectMany(_ => _.TopicControls).Count(), "parent should have 3 steps");
                Assert.AreEqual(2, db.parent.DocumentRequirements.Count, "parent should have 2 documents");

                Assert.AreEqual(3, db.child2.AvailableEvents.Count, "child should have 3 events");
                Assert.AreEqual(3, db.child2.AvailableEvents.Count(_ => _.IsInherited), "child should have 3 inherited events");
                Assert.AreEqual(3, db.child2.TaskSteps.SelectMany(_ => _.TopicControls).Count(), "child should have 3 steps");
                Assert.AreEqual(3, db.child2.TaskSteps.SelectMany(_ => _.TopicControls).Count(_ => _.IsInherited), "child should have 3 inherited steps");
                Assert.AreEqual(2, db.child2.DocumentRequirements.Count, "child should have 2 documents");
                Assert.AreEqual(2, db.child2.DocumentRequirements.Count(_ => _.IsInherited), "child should have 2 inherited documents");
                Assert.AreEqual(2, db.child2.RolesAllowed.Count, "child should have 2 User Access Roles");
                Assert.AreEqual(2, db.child2.RolesAllowed.Count(_ => _.Inherited.GetValueOrDefault()), "child should have 2 inherited User Access Roles");

                var orderedEvents = db.child2.AvailableEvents.OrderBy(_ => _.DisplaySequence);
                Assert.True(orderedEvents.First().Event.Description.EndsWith("apple"), "reset events ordered in parent order");
                Assert.True(orderedEvents.ElementAt(1).Event.Description.EndsWith("banana"), "reset events ordered in parent order");
                Assert.True(orderedEvents.ElementAt(2).Event.Description.EndsWith("orange"), "reset events ordered in parent order");

                var orderedSteps = db.child2.WorkflowWizard.TopicControls.OrderBy(_ => _.RowPosition);
                Assert.AreEqual("frmAttributes", orderedSteps.First().Name, "reset steps ordered in parent order");
                Assert.AreEqual("frmDesignation", orderedSteps.ElementAt(1).Name, "reset steps ordered in parent order");
                Assert.AreEqual("C - ChecklistTypeKey1", orderedSteps.ElementAt(2).Title, "reset steps ordered in parent order");
            });
        }

        [Test]
        public void ResetEntryWithInheritance()
        {
            var data = CriteriaTreeBuilder.Build();
            AddEvents(data);
            AddSteps(data);
            AddDocuments(data);
            AddUserAccess(data);
            
            DbSetup.Do(setup =>
            {
                var tasks = setup.DbContext.Set<DataEntryTask>()
                                 .Where(_ => data.CriteriaIds.Contains(_.CriteriaId));
                var child = tasks.Single(_ => _.CriteriaId == data.Child2.Id);
                var grandChild = tasks.Single(_ => _.CriteriaId == data.GrandChild21.Id);

                // setup AvailableEvents
                var updateEvent = child.AvailableEvents.Single(_ => _.EventId == data.Events["apple"].Id);
                updateEvent.IsInherited = false;
                updateEvent.DueAttribute = 1;

                var updateEventGrandChild = grandChild.AvailableEvents.Single(_ => _.EventId == data.Events["apple"].Id);
                updateEventGrandChild.DueAttribute = 1;

                // setup steps
                var updateStep = child.WorkflowWizard.TopicControls.Single(_ => _.Name == "frmAttributes");
                updateStep.IsInherited = false;
                updateStep.IsMandatory = true;

                var updateStepGc = grandChild.WorkflowWizard.TopicControls.Single(_ => _.Name == "frmAttributes");
                updateStepGc.IsInherited = true;
                updateStepGc.IsMandatory = true;

                // setup documents
                var updateDoc = child.DocumentRequirements.Single(_ => _.Document.Name.EndsWith("document1"));
                updateDoc.InternalMandatoryFlag = 1;

                var updateDocGc = grandChild.DocumentRequirements.Single(_ => _.Document.Name.EndsWith("document1"));
                updateDocGc.InternalMandatoryFlag = 1;

                setup.DbContext.SaveChanges();

            });

            var entryToUpdate = data.Child2.FirstEntry();

            var res = ApiClient.Post<dynamic>($"configuration/rules/workflows/{entryToUpdate.CriteriaId}/entrycontrol/{entryToUpdate.Id}/reset?appliesToDescendants=true", string.Empty);

            Assert.NotNull(res);
            Assert.AreEqual("success", res.status.ToString());

            DbSetup.Do(setup =>
                {
                    var result = setup.DbContext.Set<DataEntryTask>()
                                      .Where(_ => data.CriteriaIds.Contains(_.CriteriaId))
                                      .ToDictionary(k => k.CriteriaId, v => v);
                    var db = new
                    {
                        parent = result[data.Parent.Id],
                        child2 = result[data.Child2.Id],
                        grandChild21 = result[data.GrandChild21.Id]
                    };
                    Assert.AreEqual(3, db.parent.AvailableEvents.Count, "parent should have 3 events");
                    Assert.AreEqual(3, db.parent.TaskSteps.SelectMany(_ => _.TopicControls).Count(), "parent should have 3 steps");
                    Assert.AreEqual(2, db.parent.DocumentRequirements.Count, "parent should have 2 documents");

                    Assert.AreEqual(3, db.child2.AvailableEvents.Count, "child should have 3 events");
                    Assert.AreEqual(3, db.child2.AvailableEvents.Count(_ => _.IsInherited), "child should have 3 inherited events");
                    Assert.AreEqual(3, db.child2.TaskSteps.SelectMany(_ => _.TopicControls).Count(), "child should have 3 steps");
                    Assert.AreEqual(3, db.child2.TaskSteps.SelectMany(_ => _.TopicControls).Count(_ => _.IsInherited), "child should have 3 inherited steps");
                    Assert.AreEqual(2, db.child2.DocumentRequirements.Count, "child should have 2 documents");
                    Assert.AreEqual(2, db.child2.DocumentRequirements.Count(_ => _.IsInherited), "child should have 2 inherited documents");
                    Assert.AreEqual(2, db.child2.RolesAllowed.Count, "child should have 2 User Access Roles");
                    Assert.AreEqual(2, db.child2.RolesAllowed.Count(_ => _.Inherited.GetValueOrDefault()), "child should have 2 inherited User Access Roles");

                    // test Available Events
                    Assert.AreEqual(4, db.grandChild21.AvailableEvents.Count, "grand child should have 4 events");
                    Assert.IsNull(db.grandChild21.AvailableEvents.Single(_ => _.EventId == data.Events["apple"].Id).DueAttribute, "Inherited Entry Event in grandchild should be updated to what changed in child");
                    Assert.IsNull(db.grandChild21.AvailableEvents.SingleOrDefault(_ => _.EventId == data.Events["papaya"].Id), "Inherited Entry Event deleted in child should be deleted in grandchild");
                    Assert.NotNull(db.grandChild21.AvailableEvents.SingleOrDefault(_ => _.EventId == data.Events["banana"].Id), "Inherited Entry Event added in child should be added in grandchild");
                    Assert.NotNull(db.grandChild21.AvailableEvents.SingleOrDefault(_ => _.EventId == data.Events["orange"].Id), "Inherited Entry Event added in child should be added in grandchild");
                    Assert.False(db.grandChild21.AvailableEvents.Single(_ => _.EventId == data.Events["peach"].Id).IsInherited, "Not Inherited Entry Event should remain unchanged in grandchild");

                    // test task steps
                    var tc = db.grandChild21.WorkflowWizard.TopicControls;
                    Assert.AreEqual(false, tc.Single(_ => _.Name == "frmAttributes").IsMandatory, "Inherited Step in grandchild should be updated");
                    Assert.IsNull(tc.SingleOrDefault(_ => _.Name == "frmCheckList" && _.Title == "C - ChecklistTypeKey2"), "Inherited Step deleted in child should be deleted in grandChild");
                    Assert.NotNull(tc.SingleOrDefault(_ => _.Name == "frmDesignation"), "Step added in child should be added in grandchild");
                    Assert.NotNull(tc.SingleOrDefault(_ => _.Name == "frmText"), "Not Inherited Step should remain unchanged in grandchild");
                    
                    // test document requirements
                    var d = db.grandChild21.DocumentRequirements;
                    Assert.AreEqual(false, d.Single(_ => _.Document.Name.EndsWith("document1")).IsMandatory, "Inherited document in grandchild should be updated to what changed in child");
                    Assert.NotNull(d.SingleOrDefault(_ => _.Document.Name.EndsWith("document2")), "Document added in child should be added to grandchild");
                    Assert.Null(d.SingleOrDefault(_ => _.Document.Name.EndsWith("document3")), "Inherited document deleted in child should be deleted in grandchild");
                    Assert.NotNull(d.SingleOrDefault(_ => _.Document.Name.EndsWith("document4")), "Not inherited Document in grandchild should remain unchanged");

                    // test User Access (roles)
                    var ua = db.grandChild21.RolesAllowed;
                    Assert.NotNull(ua.SingleOrDefault(_ => _.Role.RoleName.EndsWith("role1") && _.Inherited == true), "Role added in child should be inherited to grandchild");
                    Assert.NotNull(ua.SingleOrDefault(_ => _.Role.RoleName.EndsWith("role2") && _.Inherited == true), "Role already in child should be left inherited in grandchild");
                    Assert.Null(ua.SingleOrDefault(_ => _.Role.RoleName.EndsWith("role3")), "Role deleted in child should be inherently deleted in grandchild");
                    Assert.NotNull(ua.SingleOrDefault(_ => _.Role.RoleName.EndsWith("role4") && _.Inherited == false), "Not inherited Role grandchild should remain unchanged");                    
                });
        }

        [Test]
        public void ResetEntry()
        {
            ResetEntry(false);
        }

        [Test]
        public void ResetEntryBasedOnFuzzyMatch()
        {
            ResetEntry(true);
        }

        [Test]
        public void BreakEntryInheritance()
        {
            var data = CriteriaTreeBuilder.Build();
            AddEvents(data);
            AddSteps(data);
            AddDocuments(data);
            AddUserAccess(data);

            var entryToUpdate = data.Child2.FirstEntry();

            var res = ApiClient.Post<dynamic>($"configuration/rules/workflows/{entryToUpdate.CriteriaId}/entrycontrol/{entryToUpdate.Id}/break", string.Empty);

            Assert.NotNull(res);
            Assert.AreEqual("success", res.status.ToString());

            DbSetup.Do(setup =>
            {
                var result = setup.DbContext.Set<DataEntryTask>()
                                  .Where(_ => data.CriteriaIds.Contains(_.CriteriaId))
                                  .ToDictionary(k => k.CriteriaId, v => v);
                var db = new
                {
                    parent = result[data.Parent.Id],
                    child2 = result[data.Child2.Id],
                    grandChild21 = result[data.GrandChild21.Id]
                };
                Assert.AreEqual(3, db.parent.AvailableEvents.Count, "parent should have 3 events");
                Assert.AreEqual(3, db.parent.TaskSteps.SelectMany(_ => _.TopicControls).Count(), "parent should have 3 steps");
                Assert.AreEqual(2, db.parent.DocumentRequirements.Count, "parent should have 2 documents");
                Assert.AreEqual(2, db.parent.RolesAllowed.Count, "parent should have 2 User Access Roles");

                Assert.AreEqual(3, db.child2.AvailableEvents.Count, "entry should have 3 events");
                Assert.AreEqual(3, db.child2.TaskSteps.SelectMany(_ => _.TopicControls).Count(), "entry should have 4 steps");
                Assert.AreEqual(2, db.child2.DocumentRequirements.Count, "entry should have 2 documents");
                Assert.AreEqual(0, db.child2.AvailableEvents.Count(_ => _.IsInherited)
                                   + db.child2.TaskSteps.SelectMany(_ => _.TopicControls).Count(_ => _.IsInherited)
                                   + db.child2.DocumentRequirements.Count(_ => _.IsInherited), "Nothing should be inherited");
                Assert.AreEqual(2, db.child2.RolesAllowed.Count(r => r.Inherited.GetValueOrDefault() == false), "child should break inheritance for User Access Roles");

                Assert.AreEqual(3, db.grandChild21.AvailableEvents.Count, "grand child should have 3 events");
                Assert.AreEqual(2, db.grandChild21.AvailableEvents.Count(_ => _.IsInherited), "grand child should have 2 inherited event from child2");
                Assert.AreEqual(4, db.grandChild21.TaskSteps.SelectMany(_ => _.TopicControls).Count(), "grand child should have 4 steps");
                Assert.AreEqual(2, db.grandChild21.TaskSteps.SelectMany(_ => _.TopicControls).Count(_ => _.IsInherited), "grand child should have 1 inherited step from child2");
                Assert.AreEqual(3, db.grandChild21.DocumentRequirements.Count, "grand child should have 2 documents");
                Assert.AreEqual(2, db.grandChild21.DocumentRequirements.Count(_ => _.IsInherited), "grand child should have 2 inherited documnet from child2");
                Assert.AreEqual(2, db.grandChild21.RolesAllowed.Count(r => r.Inherited.GetValueOrDefault()), "grand child should keep its inheritance for User Access Roles");
            });
        }

        void AddEvents(CriteriaTreeBuilder.CriteriaTreeFixture data)
        {
            var apple = data.Events["apple"];
            var banana = data.Events["banana"];
            var orange = data.Events["orange"];
            var papaya = data.Events["papaya"];
            var watermelon = data.Events["watermelon"];
            var peach = data.Events["peach"];

            AddEvent(data.Parent.FirstEntry(), false, apple, banana, orange);

            AddEvent(data.Child2.FirstEntry(), false, papaya, watermelon);
            AddEvent(data.Child2.FirstEntry(), true, apple);

            AddEvent(data.GrandChild21.FirstEntry(), true, apple, papaya);
            AddEvent(data.GrandChild21.FirstEntry(), false, peach);
        }

        void AddSteps(CriteriaTreeBuilder.CriteriaTreeFixture data)
        {
            using (var setup = new EntryDbSetup())
            {
                var country = setup.InsertWithNewId(new Country {AllMembersFlag = 0, Type = "0", Name = RandomString.Next(15)}).Id;
                var countryFlag = setup.Insert(new CountryFlag(country, Fixture.Short(), Fixture.String(5))).FlagNumber.ToString();
                var checklistTypeKey1 = setup.InsertWithNewId(new CheckList {Description = Fixture.String(20)}).Id.ToString();
                var checklistTypeKey2 = setup.InsertWithNewId(new CheckList {Description = Fixture.String(20)}).Id.ToString();
                var textTypeKey = setup.InsertWithNewId(new TextType(Fixture.String(20))).Id;

                var tcAttributes = setup.CreateStep("frmAttributes", "G", inherited: true);
                var tcDesignation = setup.CreateStep("frmDesignation", "F - CountryFlag", filter1Name: "CountryFlag", filter1Value: countryFlag, inherited: true);
                var tcChecklist1 = setup.CreateStep("frmCheckList", "C - ChecklistTypeKey1", filter1Name: "ChecklistTypeKey", filter1Value: checklistTypeKey1);
                var tcChecklist2 = setup.CreateStep("frmCheckList", "C - ChecklistTypeKey2", filter1Name: "ChecklistTypeKey", filter1Value: checklistTypeKey2, inherited: true);
                var tcTextType = setup.CreateStep("frmText", "T - TextTypeKey", filter1Name: "TextTypeKey", filter1Value: textTypeKey);

                data.Parent.FirstEntry().QuickAddSteps(tcAttributes.Clone(), tcDesignation.Clone(), tcChecklist1.Clone());
                data.Child2.FirstEntry().QuickAddSteps(tcAttributes.Clone(), tcChecklist1.Clone(), tcChecklist2.Clone());
                data.GrandChild21.FirstEntry().QuickAddSteps(tcAttributes.Clone(), tcChecklist1.Clone(), tcChecklist2.Clone(), tcTextType.Clone());
            }
        }

        void AddDocuments(CriteriaTreeBuilder.CriteriaTreeFixture data)
        {
            DbSetup.Do(setup =>
            {
                var document1 = setup.InsertWithNewId(new Document
                {
                    Name = Fixture.Prefix("document1"),
                    DocumentType = 1
                });
                var document2 = setup.InsertWithNewId(new Document
                {
                    Name = Fixture.Prefix("document2"),
                    DocumentType = 1
                });
                var document3 = setup.InsertWithNewId(new Document
                {
                    Name = Fixture.Prefix("document3"),
                    DocumentType = 1
                });
                var document4 = setup.InsertWithNewId(new Document
                {
                    Name = Fixture.Prefix("document4"),
                    DocumentType = 1
                });

                setup.Insert(new DocumentRequirement(data.Parent, data.Parent.FirstEntry(), document1));
                setup.Insert(new DocumentRequirement(data.Parent, data.Parent.FirstEntry(), document2));

                setup.Insert(new DocumentRequirement(data.Child2, data.Child2.FirstEntry(), document1) {IsInherited = true});
                setup.Insert(new DocumentRequirement(data.Child2, data.Child2.FirstEntry(), document3));

                setup.Insert(new DocumentRequirement(data.GrandChild21, data.GrandChild21.FirstEntry(), document1) {IsInherited = true});
                setup.Insert(new DocumentRequirement(data.GrandChild21, data.GrandChild21.FirstEntry(), document3) {IsInherited = true});
                setup.Insert(new DocumentRequirement(data.GrandChild21, data.GrandChild21.FirstEntry(), document4));
            });
        }

        void AddUserAccess(CriteriaTreeBuilder.CriteriaTreeFixture data)
        {
            DbSetup.Do(setup =>
            {
                var role1 = setup.InsertWithNewId(new Role
                {
                    RoleName = Fixture.Prefix("role1")
                });
                var role2 = setup.InsertWithNewId(new Role
                {
                    RoleName = Fixture.Prefix("role2")
                });
                var role3 = setup.InsertWithNewId(new Role
                {
                    RoleName = Fixture.Prefix("role3")
                });
                var role4 = setup.InsertWithNewId(new Role
                {
                    RoleName = Fixture.Prefix("role4")
                });

                setup.Insert(new RolesControl(role1.Id, data.Parent.Id, data.Parent.FirstEntry().Id));
                setup.Insert(new RolesControl(role2.Id, data.Parent.Id, data.Parent.FirstEntry().Id));

                setup.Insert(new RolesControl(role2.Id, data.Child2.Id, data.Child2.FirstEntry().Id));
                setup.Insert(new RolesControl(role3.Id, data.Child2.Id, data.Child2.FirstEntry().Id));

                setup.Insert(new RolesControl(role2.Id, data.GrandChild21.Id, data.GrandChild21.FirstEntry().Id) { Inherited = true });
                setup.Insert(new RolesControl(role3.Id, data.GrandChild21.Id, data.GrandChild21.FirstEntry().Id) {Inherited = true});
                setup.Insert(new RolesControl(role4.Id, data.GrandChild21.Id, data.GrandChild21.FirstEntry().Id) { Inherited = false });
            });
        }

        void AddEvent(DataEntryTask entry, bool inherit, params Event[] events)
        {
            DbSetup.Do(setup =>
            {
                for (var i = 0; i < events.Length; i++)
                    setup.Insert(new AvailableEvent
                    {
                        CriteriaId = entry.Criteria.Id,
                        EventId = events[i].Id,
                        DataEntryTaskId = entry.Id,
                        DisplaySequence = (short) i,
                        Inherited = inherit ? 1 : 0
                    });
            });
        }
    }
}