using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NUnit.Framework;
using Action = InprotechKaizen.Model.Cases.Action;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.Entries
{
    [Category(Categories.Integration)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release14)]
    public partial class EntrySteps : IntegrationTest
    {
        [Test]
        public void ShouldIdentifyInheritanceLevel()
        {
            var data = CriteriaTreeBuilder.Build();

            var arg = DbSetup.Do(x =>
                                      {
                                          var action = x.InsertWithNewId(new Action(Fixture.String(5))).Code;
                                          var country = x.InsertWithNewId(new Country {AllMembersFlag = 0, Type = "0", Name = RandomString.Next(15)}).Id;
                                          var countryFlag = x.Insert(new CountryFlag(country, Fixture.Short(), Fixture.String(5))).FlagNumber.ToString();

                                          return new
                                          {
                                              action,
                                              countryFlag
                                          };
                                      });

            data.Parent.FirstEntry().AddStep("frmAttributes", "G");
            data.Parent.FirstEntry().AddStep("frmCaseHistory", "A - CreateActionKey", filter1Name: "CreateActionKey", filter1Value: arg.action);
            data.Parent.FirstEntry().AddStep("frmDesignation", "F - CountryFlag", filter1Name: "CountryFlag", filter1Value: arg.countryFlag);

            data.Child1.FirstEntry().AddStep("frmAttributes", "G", inherited: true);
            data.Child1.FirstEntry().AddStep("frmCaseHistory", "A - CreateActionKey", filter1Name: "CreateActionKey", filter1Value: arg.action, inherited: true);
            data.Child1.FirstEntry().AddStep("frmDesignation", "F - CountryFlag", filter1Name: "CountryFlag", filter1Value: arg.countryFlag, inherited: true);

            data.Child2.FirstEntry().AddStep("frmAttributes", "G", inherited: true);

            data.GrandChild21.FirstEntry().AddStep("frmAttributes", "G", inherited: true);

            data.GreatGrandChild211.FirstEntry().AddStep("frmAttributes", "G");

            var parent = ApiClient.Get<JObject>($"configuration/rules/workflows/{data.Parent.Id}/entrycontrol/{data.Parent.FirstEntry().Id}");

            var child1 = ApiClient.Get<JObject>($"configuration/rules/workflows/{data.Child1.Id}/entrycontrol/{data.Child1.FirstEntry().Id}");

            var child2 = ApiClient.Get<JObject>($"configuration/rules/workflows/{data.Child2.Id}/entrycontrol/{data.Child2.FirstEntry().Id}");

            var grandChild21 = ApiClient.Get<JObject>($"configuration/rules/workflows/{data.GrandChild21.Id}/entrycontrol/{data.GrandChild21.FirstEntry().Id}");

            var greatGrandChild211 = ApiClient.Get<JObject>($"configuration/rules/workflows/{data.GreatGrandChild211.Id}/entrycontrol/{data.GreatGrandChild211.FirstEntry().Id}");

            Assert.AreEqual("None", (string) parent["inheritanceLevel"], "Should have inheritance level of 'None' since it is top level.");

            Assert.AreEqual("Full", (string) child1["inheritanceLevel"], "Should have inheritance level of 'Full' as it has all necessary steps from parent.");

            Assert.AreEqual("Partial", (string) child2["inheritanceLevel"], "Should have inheritance level of 'Partial' as it has less steps from parent.");

            Assert.AreEqual("Full", (string) grandChild21["inheritanceLevel"], "Should have inheritance level of 'Full' as it has all steps from immediate parent");

            Assert.AreEqual("Partial", (string) greatGrandChild211["inheritanceLevel"], "Should have inheritance level of 'Partial' as it is not inherited although same number of steps from its immediate parent");
        }

        [Test]
        public void ShouldPropagateUpdatesToDescendants()
        {
            var data = CriteriaTreeBuilder.Build();

            var arg = DbSetup.Do(x =>
                                      {
                                          var action = x.InsertWithNewId(new Action(Fixture.String(5))).Code;
                                          var country = x.InsertWithNewId(new Country {AllMembersFlag = 0, Type = "0", Name = RandomString.Next(15)}).Id;
                                          var countryFlag = x.Insert(new CountryFlag(country, Fixture.Short(), Fixture.String(5))).FlagNumber.ToString();
                                          var checklistTypeKey1 = x.InsertWithNewId(new CheckList {Description = Fixture.String(20)}).Id.ToString();
                                          var checklistTypeKey2 = x.InsertWithNewId(new CheckList {Description = Fixture.String(20)}).Id.ToString();
                                          var nameTypeKey = x.Insert(new NameType(Fixture.String(2), Fixture.String(20))).NameTypeCode;
                                          var textTypeKey = x.InsertWithNewId(new TextType(Fixture.String(20))).Id;

                                          var newAction = x.InsertWithNewId(new Action(Fixture.String(5))).Code;
                                          var newCountryFlag = x.Insert(new CountryFlag(country, Fixture.Short(), Fixture.String(5))).FlagNumber.ToString();
                                          var newNameTypeKey = x.Insert(new NameType(Fixture.String(2), Fixture.String(20))).NameTypeCode;
                                          var newTextTypeKey = x.InsertWithNewId(new TextType(Fixture.String(20))).Id;
                                          var newChecklistTypeKey2 = x.InsertWithNewId(new CheckList {Description = Fixture.String(20)}).Id.ToString();

                                          var randomOtherChecklistTypeKey1 = x.InsertWithNewId(new CheckList {Description = Fixture.String(20)}).Id.ToString();
                                          var randomOtherChecklistTypeKey2 = x.InsertWithNewId(new CheckList {Description = Fixture.String(20)}).Id.ToString();

                                          return new
                                          {
                                              action,
                                              countryFlag,
                                              checklistTypeKey1,
                                              checklistTypeKey2,
                                              nameTypeKey,
                                              textTypeKey,
                                              randomOtherChecklistTypeKey1,
                                              randomOtherChecklistTypeKey2,
                                              newAction,
                                              newCountryFlag,
                                              newNameTypeKey,
                                              newTextTypeKey,
                                              newChecklistTypeKey2
                                          };
                                      });

            var entryToUpdate = data.Parent.FirstEntry();

            var frmAttributes = entryToUpdate.AddStep("frmAttributes", "G");
            var frmCaseHistory = entryToUpdate.AddStep("frmCaseHistory", "A - CreateActionKey", filter1Name: "CreateActionKey", filter1Value: arg.action);
            var frmDesignation = entryToUpdate.AddStep("frmDesignation", "F - CountryFlag", filter1Name: "CountryFlag", filter1Value: arg.countryFlag);
            entryToUpdate.AddStep("frmCheckList", "C - ChecklistTypeKey", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey1);
            var frmChecklist2 = entryToUpdate.AddStep("frmCheckList", "C - ChecklistTypeKey", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey2);
            var frmNameText = entryToUpdate.AddStep("frmNameText", "X - NameTypeKey, TextTypeKey", filter1Name: "NameTypeKey", filter1Value: arg.nameTypeKey, filter2Name: "TextTypeKey", filter2Value: arg.textTypeKey);

            data.Child1.FirstEntry().AddStep("frmAttributes", "G");
            data.Child1.FirstEntry().AddStep("frmNameText", filter1Name: "NameTypeKey", filter1Value: arg.nameTypeKey, filter2Name: "TextTypeKey", filter2Value: arg.textTypeKey, inherited: true);
            data.Child1.FirstEntry().AddStep("frmCheckList", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey1, inherited: true);

            data.Child2.FirstEntry().AddStep("frmAttributes", "G", inherited: true);
            data.Child2.FirstEntry().AddStep("frmCheckList", usertip: "Not inherited", filter1Name: "ChecklistTypeKey", filter1Value: arg.randomOtherChecklistTypeKey1);
            data.Child2.FirstEntry().AddStep("frmCheckList", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey2, inherited: true);
            data.Child2.FirstEntry().AddStep("frmDesignation", filter1Name: "CountryFlag", filter1Value: arg.countryFlag, inherited: true);
            data.Child2.FirstEntry().AddStep("frmNameText", filter1Name: "NameTypeKey", filter1Value: arg.nameTypeKey, filter2Name: "TextTypeKey", filter2Value: arg.textTypeKey, inherited: true);
            data.Child2.FirstEntry().AddStep("frmNameText", filter1Name: "NameTypeKey", filter1Value: arg.newNameTypeKey, filter2Name: "TextTypeKey", filter2Value: arg.newTextTypeKey);

            data.GrandChild21.FirstEntry().AddStep("frmAttributes", "G", inherited: true);
            data.GrandChild21.FirstEntry().AddStep("frmCheckList", usertip: "Not inherited", filter1Name: "ChecklistTypeKey", filter1Value: arg.randomOtherChecklistTypeKey2);
            data.GrandChild21.FirstEntry().AddStep("frmCheckList", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey2, inherited: true);
            data.GrandChild21.FirstEntry().AddStep("frmDesignation", filter1Name: "CountryFlag", filter1Value: arg.countryFlag);
            data.GrandChild21.FirstEntry().AddStep("frmNameText", filter1Name: "NameTypeKey", filter1Value: arg.nameTypeKey, filter2Name: "TextTypeKey", filter2Value: arg.textTypeKey, inherited: true);

            data.GreatGrandChild211.FirstEntry().AddStep("frmCheckList", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey2, inherited: true);

            ApiClient.Put($"configuration/rules/workflows/{data.Parent.Id}/entrycontrol/{entryToUpdate.Id}",
                          JsonConvert.SerializeObject(new WorkflowEntryControlSaveModel
                                                      {
                                                          CriteriaId = data.Parent.Id,
                                                          Id = entryToUpdate.Id,
                                                          Description = entryToUpdate.Description,
                                                          ApplyToDescendants = true,
                                                          StepsDelta = new Delta<StepDelta>
                                                          {
                                                              Updated = new[]
                                                              {
                                                                  new StepDelta("frmAttributes", "G")
                                                                  {
                                                                      Id = frmAttributes.Id,
                                                                      Title = frmAttributes.Title,
                                                                      ScreenTip = "hello", /* updated */
                                                                      IsMandatory = frmAttributes.IsMandatory
                                                                  },
                                                                  new StepDelta("frmCaseHistory", "A", "action", arg.newAction)
                                                                  {
                                                                      Id = frmCaseHistory.Id,
                                                                      Title = frmCaseHistory.Title,
                                                                      ScreenTip = frmCaseHistory.ScreenTip,
                                                                      IsMandatory = true /* updated */
                                                                  },
                                                                  new StepDelta("frmDesignation", "F", "designationStage", arg.newCountryFlag)
                                                                  {
                                                                      Id = frmDesignation.Id,
                                                                      Title = frmDesignation.Title,
                                                                      ScreenTip = frmDesignation.ScreenTip,
                                                                      IsMandatory = frmDesignation.IsMandatory
                                                                  },
                                                                  new StepDelta("frmNameText", "X", "nameType", arg.newNameTypeKey, "textType", arg.newTextTypeKey)
                                                                  {
                                                                      Id = frmNameText.Id,
                                                                      Title = frmNameText.Title,
                                                                      ScreenTip = frmNameText.ScreenTip,
                                                                      IsMandatory = frmNameText.IsMandatory
                                                                  },
                                                                  new StepDelta("frmCheckList", "C", "checklist", arg.newChecklistTypeKey2)
                                                                  {
                                                                      Id = frmChecklist2.Id,
                                                                      Title = frmChecklist2.Title,
                                                                      ScreenTip = frmChecklist2.ScreenTip,
                                                                      IsMandatory = true /* updated */
                                                                  }
                                                              }
                                                          }
                                                      }));

            using (var ctx = new SqlDbContext())
            {
                var result = ctx.Set<DataEntryTask>()
                                .Include(_ => _.TaskSteps.Select(w => w.TopicControls))
                                .Where(_ => data.CriteriaIds.Contains(_.CriteriaId))
                                .ToDictionary(k => k.CriteriaId, v => v);

                var parent = result[data.Parent.Id];
                var child1 = result[data.Child1.Id];
                var child2 = result[data.Child2.Id];
                var grandChild21 = result[data.GrandChild21.Id];
                var grandChild22 = result[data.GrandChild22.Id];
                var greatGrandChild211 = result[data.GreatGrandChild211.Id];

                Assert.AreEqual("hello", parent.SingleStepByName("frmAttributes").ScreenTip, "frmAttributes: should set screen tip to 'hello' in parent.");

                Assert.IsNull(child1.SingleStepByName("frmAttributes").ScreenTip, "frmAttributes: should not propagate 'hello' screentip to 'child1' as it is not inherited.");

                Assert.AreEqual("hello", child2.SingleStepByName("frmAttributes").ScreenTip, "frmAttributes: should propagate 'hello' to 'child2' as it is inherited.");
                Assert.IsTrue(child2.SingleStepByName("frmAttributes").IsInherited, "frmAttributes: 'child2' should remain inherited.");

                Assert.AreEqual("hello", grandChild21.SingleStepByName("frmAttributes").ScreenTip, "frmAttributes: should propagate 'hello' to 'grandChild21' as it is inherited.");
                Assert.IsTrue(grandChild21.SingleStepByName("frmAttributes").IsInherited, "frmAttributes: 'grandChild21' should remain inherited.");

                /* ---------------- */

                Assert.AreEqual(arg.newAction, parent.SingleStepByName("frmCaseHistory").Filter1Value, $"frmCaseHistory: should set 'CreateActionKey' to {arg.newAction}");
                Assert.IsTrue(parent.SingleStepByName("frmCaseHistory").IsMandatory, "frmCaseHistory: should set as mandatory");

                /* ---------------- */

                Assert.AreEqual(arg.newCountryFlag, parent.SingleStepByName("frmDesignation").Filter1Value, $"frmDesignation: should set 'CountryFlag' to {arg.newCountryFlag}");
                Assert.AreEqual(arg.newCountryFlag, child2.SingleStepByName("frmDesignation").Filter1Value, $"frmDesignation: should propagate 'CountryFlag' as {arg.newCountryFlag} to 'child2' as it is inherited.");
                Assert.AreEqual(arg.countryFlag, grandChild21.SingleStepByName("frmDesignation").Filter1Value, $"frmDesignation: should not propagate 'CountryFlag' as {arg.newCountryFlag} to 'grandChild21' as it is not inherited.  It should have {arg.countryFlag} instead.");

                /* ---------------- */

                Func<TopicControl, bool> hasNewParametersForNameTextStep = step => step.Filter1Value == arg.newNameTypeKey && step.Filter2Value == arg.newTextTypeKey;
                Func<TopicControl, bool> hasExistingParametersForNameTextStepAndIsNotInherited = step => step.Filter1Value == arg.nameTypeKey && step.Filter2Value == arg.textTypeKey && !step.IsInherited;
                Func<TopicControl, bool> hasExistingParametersForNameTextStepAndIsInherited = step => step.Filter1Value == arg.nameTypeKey && step.Filter2Value == arg.textTypeKey && step.IsInherited;

                Assert.IsTrue(parent.StepsByName("frmNameText").Any(hasNewParametersForNameTextStep), $"frmNameText: should set 'NameTypeKey' to {arg.newNameTypeKey} and 'TextTypeKey' to {arg.newTextTypeKey}");
                Assert.IsTrue(child1.StepsByName("frmNameText").Any(hasNewParametersForNameTextStep), $"frmNameText: should propagate 'NameTypeKey' as {arg.newNameTypeKey} and 'TextTypeKey' to {arg.newTextTypeKey} to 'child1' as it is inherited.");
                Assert.IsTrue(child2.StepsByName("frmNameText").Any(hasExistingParametersForNameTextStepAndIsNotInherited), "frmNameText-1: should not propagate 'NameTypeKey' and 'TextTypeKey' to 'child2' as it is collided, break inheritance as a result.");
                Assert.IsTrue(child2.StepsByName("frmNameText").Any(hasNewParametersForNameTextStep), "frmNameText-1: child2 should also have the collided item.");
                Assert.IsTrue(grandChild21.StepsByName("frmNameText").Any(hasExistingParametersForNameTextStepAndIsInherited), "frmNameText: nameTypeKey should not change.");

                /* ---------------- */

                Func<TopicControl, bool> hasNewChecklistTypeKeyAndIsMandatory = step => step.Filter1Value == arg.newChecklistTypeKey2 && step.IsMandatory;
                Func<TopicControl, bool> hasExistingChecklistTypeKey = step => step.Filter1Value != arg.newChecklistTypeKey2;

                Assert.IsTrue(parent.StepsByName("frmCheckList").Any(hasNewChecklistTypeKeyAndIsMandatory), $"frmChecklist: should set 'ChecklistTypeKey' to {arg.newChecklistTypeKey2} and set as mandatory");
                Assert.IsTrue(child2.StepsByName("frmCheckList").Any(hasNewChecklistTypeKeyAndIsMandatory), $"frmChecklist: should propagate 'ChecklistTypeKey' as {arg.newChecklistTypeKey2} and set as mandatory to 'child2' as it is inherited.");
                Assert.IsTrue(child2.StepsByName("frmCheckList").Any(hasExistingChecklistTypeKey), $"frmChecklist: should should not change as it is not inherited.");
                Assert.IsTrue(grandChild21.StepsByName("frmCheckList").Any(hasNewChecklistTypeKeyAndIsMandatory), $"frmChecklist: should propagate 'ChecklistTypeKey' as {arg.newChecklistTypeKey2} and set as mandatory to 'grandChild21' as it is inherited.");

                Assert.IsTrue(child2.StepsByName("frmCheckList").Any(hasExistingChecklistTypeKey), $"frmChecklist: should not change as it is not inherited.");
                Assert.IsTrue(greatGrandChild211.StepsByName("frmCheckList").Any(hasNewChecklistTypeKeyAndIsMandatory), $"frmChecklist: should propagate 'ChecklistTypeKey' as {arg.newChecklistTypeKey2} and set as mandatory to 'greatGrandChild211' as it is inherited.");

                /* ---------------- */

                CollectionAssert.IsEmpty(grandChild22.TaskSteps.SelectMany(_ => _.TopicControls).ToArray(), "should not have any topic controls in 'grandChild21'");
            }
        }

        [Test]
        public void ShouldPropogateDeletesToDescendents()
        {
            var data = CriteriaTreeBuilder.Build();

            var arg = DbSetup.Do(x =>
                                      {
                                          var action = x.InsertWithNewId(new Action(Fixture.String(5))).Code;
                                          var checklistTypeKey1 = x.InsertWithNewId(new CheckList {Description = Fixture.String(20)}).Id.ToString();

                                          return new
                                          {
                                              action,
                                              checklistTypeKey1
                                          };
                                      });

            var entryToBeDeleted = data.Parent.FirstEntry();

            var frmAttributes = entryToBeDeleted.AddStep("frmAttributes", "G");
            var frmCaseHistory = entryToBeDeleted.AddStep("frmCaseHistory", "A - CreateActionKey", filter1Name: "CreateActionKey", filter1Value: arg.action);
            var checklist = entryToBeDeleted.AddStep("frmCheckList", "C - ChecklistTypeKey", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey1);

            data.Child1.FirstEntry().AddStep("frmAttributes", "G");
            data.Child1.FirstEntry().AddStep("frmCaseHistory", "A - CreateActionKey", filter1Name: "CreateActionKey", filter1Value: arg.action, inherited: true);
            data.Child1.FirstEntry().AddStep("frmCheckList", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey1);

            data.Child2.FirstEntry().AddStep("frmCaseHistory", "A - CreateActionKey", filter1Name: "CreateActionKey", filter1Value: arg.action, inherited: true);
            data.Child2.FirstEntry().AddStep("frmCheckList", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey1, inherited: true);

            data.GrandChild21.FirstEntry().AddStep("frmAttributes", "G");
            data.GrandChild21.FirstEntry().AddStep("frmCaseHistory", "A - CreateActionKey", filter1Name: "CreateActionKey", filter1Value: arg.action, inherited: true);
            data.GrandChild21.FirstEntry().AddStep("frmCheckList", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey1, inherited: true);

            ApiClient.Put($"configuration/rules/workflows/{data.Parent.Id}/entrycontrol/{entryToBeDeleted.Id}",
                          JsonConvert.SerializeObject(new WorkflowEntryControlSaveModel
                                                      {
                                                          CriteriaId = data.Parent.Id,
                                                          Id = entryToBeDeleted.Id,
                                                          Description = entryToBeDeleted.Description,
                                                          ApplyToDescendants = true,
                                                          StepsDelta = new Delta<StepDelta>
                                                          {
                                                              Deleted = new[]
                                                              {
                                                                  new StepDelta("frmCaseHistory", "A", "action", null)
                                                                  {
                                                                      Id = frmCaseHistory.Id,
                                                                      Title = frmCaseHistory.Title
                                                                  },
                                                                  new StepDelta("frmAttributes", "G", null, null)
                                                                  {
                                                                      Id = frmAttributes.Id,
                                                                      Title = frmAttributes.Title
                                                                  }
                                                              }
                                                          }
                                                      }));

            using (var ctx = new SqlDbContext())
            {
                var result = ctx.Set<DataEntryTask>()
                                .Include(_ => _.TaskSteps.Select(w => w.TopicControls))
                                .Where(_ => data.CriteriaIds.Contains(_.CriteriaId))
                                .ToDictionary(k => k.CriteriaId, v => v);

                var parent = result[data.Parent.Id];
                var child1 = result[data.Child1.Id];
                var child2 = result[data.Child2.Id];
                var grandChild21 = result[data.GrandChild21.Id];

                Assert.AreEqual(0, parent.StepsByName("frmAttributes").Count(), "frmAttributes: should be deleted in parent");
                Assert.AreEqual(0, parent.StepsByName("frmCaseHistory").Count(), "frmCaseHistory: should be deleted in parent");

                Assert.AreEqual(1, child1.StepsByName("frmAttributes").Count(), "frmAttributes: should not be deleted in 'child1' as it is not inherited");
                Assert.AreEqual(0, child1.StepsByName("frmCaseHistory").Count(), "frmCaseHistory: should be deleted in 'child1'");

                Assert.AreEqual(0, child2.StepsByName("frmCaseHistory").Count(), "frmCaseHistory: should be deleted in 'child2'");

                Assert.AreEqual(1, grandChild21.StepsByName("frmAttributes").Count(), "frmAttributes: should not be deleted in 'grandChild21' as it is not inherited");
                Assert.AreEqual(0, grandChild21.StepsByName("frmCaseHistory").Count(), "frmCaseHistory: should be deleted in 'grandChild21'");
            }

            ApiClient.Put($"configuration/rules/workflows/{data.Parent.Id}/entrycontrol/{entryToBeDeleted.Id}",
                          JsonConvert.SerializeObject(new WorkflowEntryControlSaveModel
                                                      {
                                                          CriteriaId = data.Parent.Id,
                                                          Id = entryToBeDeleted.Id,
                                                          Description = entryToBeDeleted.Description,
                                                          ApplyToDescendants = false,
                                                          StepsDelta = new Delta<StepDelta>
                                                          {
                                                              Deleted = new[]
                                                              {
                                                                  new StepDelta("frmCheckList", "C", null, null)
                                                                  {
                                                                      Id = checklist.Id,
                                                                      Title = "Some random text" //updated on client
                                                                  }
                                                              }
                                                          }
                                                      }));

            using (var ctx = new SqlDbContext())
            {
                var result = ctx.Set<DataEntryTask>()
                                .Include(_ => _.TaskSteps.Select(w => w.TopicControls))
                                .Where(_ => data.CriteriaIds.Contains(_.CriteriaId))
                                .ToDictionary(k => k.CriteriaId, v => v);

                var parent = result[data.Parent.Id];
                var child1 = result[data.Child1.Id];
                var child2 = result[data.Child2.Id];
                var grandChild21 = result[data.GrandChild21.Id];

                Assert.AreEqual(0, parent.StepsByName("frmCheckList").Count(), "frmCheckList: should be deleted in parent");
                CollectionAssert.IsEmpty(parent.TaskSteps.SelectMany(_ => _.TopicControls).ToArray(), "should not have any topic controls in parent");

                Assert.IsNotNull(child1.SingleStepByName("frmCheckList"), "frmCheckList: should not be deleted in 'child1' as ApplyToDescendants is false and is not inherited");

                Assert.IsFalse(child2.SingleStepByName("frmCheckList").IsInherited, "frmCheckList: should not be deleted in 'child2' as ApplyToDescendants is false. Instead IsInherited is set to false.");

                Assert.IsTrue(grandChild21.SingleStepByName("frmCheckList").IsInherited, "frmCheckList: continues to inherit from its parent-> 'child1'");
            }

            VerifyDeletesAreSyncedToScreenControl(data);
        }

        [Test]
        public void ShouldPropogateAdditionsToDescendents()
        {
            var data = CriteriaTreeBuilder.Build();

            var arg = DbSetup.Do(x =>
                                 {
                                     var action = x.InsertWithNewId(new Action(Fixture.String(5))).Code;
                                     var country = x.InsertWithNewId(new Country {AllMembersFlag = 0, Type = "0", Name = RandomString.Next(15)}).Id;
                                     var countryFlag = x.Insert(new CountryFlag(country, Fixture.Short(), Fixture.String(5))).FlagNumber.ToString();
                                     var checklistTypeKey1 = x.InsertWithNewId(new CheckList {Description = Fixture.String(20)}).Id.ToString();
                                     var checklistTypeKey2 = x.InsertWithNewId(new CheckList {Description = Fixture.String(20)}).Id.ToString();
                                     var nameTypeKey = x.Insert(new NameType(Fixture.String(2), Fixture.String(20))).NameTypeCode;
                                     var textTypeKey = x.InsertWithNewId(new TextType(Fixture.String(20))).Id;

                                     return new
                                     {
                                         action,
                                         country,
                                         countryFlag,
                                         checklistTypeKey1,
                                         checklistTypeKey2,
                                         nameTypeKey,
                                         textTypeKey
                                     };
                                 });

            var entry = data.Parent.FirstEntry();
            var frmAttributes = entry.AddStep("frmAttributes", "G");
            var frmDesignation = entry.AddStep("frmDesignation", "F - CountryFlag", filter1Name: "CountryFlag", filter1Value: arg.countryFlag);
            var checklist = entry.AddStep("frmCheckList", "C - ChecklistTypeKey", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey1);

            data.Child1.FirstEntry().AddStep("frmAttributes", "G", inherited: true);
            data.Child1.FirstEntry().AddStep("frmDesignation", "F - CountryFlag", filter1Name: "CountryFlag", filter1Value: arg.countryFlag, inherited: true);
            data.Child1.FirstEntry().AddStep("frmCheckList", "C - ChecklistTypeKey", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey1);
            data.Child1.FirstEntry().AddStep("frmCheckList", "C - ChecklistTypeKey", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey2);
            data.Child1.FirstEntry().AddStep("frmText", "T - TextTypeKey", filter1Name: "TextTypeKey", filter1Value: arg.textTypeKey);

            data.Child2.FirstEntry().AddStep("frmDesignation", "F - CountryFlag", filter1Name: "CountryFlag", filter1Value: arg.countryFlag, inherited: true);
            data.Child2.FirstEntry().AddStep("frmAttributes", "G", inherited: true);
            data.Child2.FirstEntry().AddStep("frmCheckList", "C - ChecklistTypeKey", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey1, inherited: true);

            data.GrandChild21.FirstEntry().AddStep("frmCaseHistory", "A - CreateActionKey", filter1Name: "CreateActionKey", filter1Value: arg.action);
            data.GrandChild21.FirstEntry().AddStep("frmCheckList", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey1, inherited: true);
            data.GrandChild21.FirstEntry().AddStep("frmCheckList", filter1Name: "ChecklistTypeKey", filter1Value: arg.checklistTypeKey2);
            data.GrandChild21.FirstEntry().AddStep("frmText", "T - TextTypeKey", filter1Name: "TextTypeKey", filter1Value: arg.textTypeKey);

            ApiClient.Put($"configuration/rules/workflows/{data.Parent.Id}/entrycontrol/{entry.Id}",
                          JsonConvert.SerializeObject(new WorkflowEntryControlSaveModel
                                                      {
                                                          CriteriaId = data.Parent.Id,
                                                          Id = entry.Id,
                                                          Description = entry.Description,
                                                          ApplyToDescendants = true,
                                                          StepsDelta = new Delta<StepDelta>
                                                          {
                                                              Added = new[]
                                                              {
                                                                  new StepDelta("frmNames", "N", "nameType", arg.nameTypeKey)
                                                                  {
                                                                      NewItemId = "A",
                                                                      Title = "Names1",
                                                                      RelativeId = frmAttributes.Id.ToString()
                                                                  },
                                                                  new StepDelta("frmText", "T", "textType", arg.textTypeKey)
                                                                  {
                                                                      NewItemId = "B",
                                                                      Title = "Text1",
                                                                      RelativeId = checklist.Id.ToString()
                                                                  },
                                                                  new StepDelta("frmCheckList", "C", "checklist", arg.checklistTypeKey2)
                                                                  {
                                                                      NewItemId = "C",
                                                                      Title = "Checklist2",
                                                                      RelativeId = "B"
                                                                  }
                                                              }
                                                          }
                                                      }));

            using (var ctx = new SqlDbContext())
            {
                var result = ctx.Set<DataEntryTask>()
                                .Include(_ => _.TaskSteps.Select(w => w.TopicControls))
                                .Where(_ => data.CriteriaIds.Contains(_.CriteriaId))
                                .ToDictionary(k => k.CriteriaId, v => v);

                var parent = result[data.Parent.Id];
                var child1 = result[data.Child1.Id];
                var child2 = result[data.Child2.Id];
                var grandChild21 = result[data.GrandChild21.Id];

                //Parent
                var parentSteps = parent.WorkflowWizard.TopicControls.OrderBy(t => t.RowPosition).ToArray();
                Assert.AreEqual(frmAttributes.Name, parentSteps[0].Name, "In Parent - Existing General step is at the first place");

                Assert.AreEqual("frmNames", parentSteps[1].Name, $"In Parent - Names should be added after {frmAttributes.Name}");
                Assert.AreEqual("Names1", parentSteps[1].Title, "In Parent - Names should have 'Names1' as title");
                Assert.AreEqual(arg.nameTypeKey, parentSteps[1].Filter1Value, $"In Parent - Names should have correct filter value as {arg.nameTypeKey}");

                Assert.AreEqual(frmDesignation.Name, parentSteps[2].Name, "In Parent - Existing Designation flag step is moved to after newly added step of name");
                Assert.AreEqual(checklist.Name, parentSteps[3].Name, "In Parent - Existing Checklist step is after Designation Flag step");

                Assert.AreEqual("frmText", parentSteps[4].Name, $"In Parent - Text should be added after {checklist.Name}");
                Assert.AreEqual("Text1", parentSteps[4].Title, "In Parent - Text should have 'Text1' as title");
                Assert.AreEqual(arg.textTypeKey, parentSteps[4].Filter1Value, $"In Parent - Text should have correct filter value as {arg.textTypeKey}");

                Assert.AreEqual("frmCheckList", parentSteps[5].Name, "In Parent - Checklist should be added after newly added Text");
                Assert.AreEqual("Checklist2", parentSteps[5].Title, "In Parent - Checklist should have 'Checklist2' as title");
                Assert.AreEqual(arg.checklistTypeKey2, parentSteps[5].Filter1Value, $"In Parent - Checklist should have correct filter value as {arg.checklistTypeKey2}");

                //Child1
                var child1Steps = child1.WorkflowWizard.TopicControls.OrderBy(t => t.RowPosition).ToArray();
                Assert.AreEqual(frmAttributes.Name, child1Steps[0].Name, "In Child1 - Existing General step is at the first place");

                Assert.AreEqual("frmNames", child1Steps[1].Name, $"In Child1 - Names should be added after {frmAttributes.Name}");
                Assert.AreEqual("Names1", child1Steps[1].Title, "In Child1 - Names should have 'Names1' as title");
                Assert.AreEqual(arg.nameTypeKey, child1Steps[1].Filter1Value, $"In Child1 - Names should have correct filter value as {arg.nameTypeKey}");
                Assert.IsTrue(child1Steps[1].IsInherited, "In Child1 - Names should idInherited flag as true");

                Assert.AreEqual(frmDesignation.Name, child1Steps[2].Name, "In Child1 - Existing Designation flag step is moved to after newly added step of name");
                Assert.AreEqual(checklist.Name, child1Steps[3].Name, "In Child1 - Existing Checklist step is after Designation Flag step");

                Assert.AreEqual("frmCheckList", child1Steps[4].Name, "In Child1 - Does not take addition of Thecklist with type 2, since it already has it");
                Assert.IsFalse(child1Steps[4].IsInherited, "In Child1 - Does not take addition of Checklist with type 2, since it already has it");

                Assert.AreEqual("frmText", child1Steps[5].Name, "In Parent -  Does not take addition of Text, since it already has it");
                Assert.IsFalse(child1Steps[4].IsInherited, "In Child1 - Does not take addition of Checklist with type 2, since it already has it");

                //Child2
                var child2Steps = child2.WorkflowWizard.TopicControls.OrderBy(t => t.RowPosition).ToArray();

                Assert.AreEqual(frmDesignation.Name, child2Steps[0].Name, "In Child2 - Existing Designation flag step is at first place");
                Assert.AreEqual(frmAttributes.Name, child2Steps[1].Name, "In Child2 - Existing General step is after Designation flag step");

                Assert.AreEqual("frmNames", child2Steps[2].Name, $"In Child2 - Names should be added after {frmAttributes.Name}");
                Assert.AreEqual("Names1", child2Steps[2].Title, "In Child2 - Names should have 'Names1' as title");
                Assert.AreEqual(arg.nameTypeKey, child2Steps[2].Filter1Value, $"In Child2 - Names should have correct filter value as {arg.nameTypeKey}");
                Assert.IsTrue(child2Steps[2].IsInherited, "In Child2 - Names should have IsInherited flag set to true");

                Assert.AreEqual(checklist.Name, child2Steps[3].Name, "In Child2 - Existing Checklist step is after newly added step for Names");

                Assert.AreEqual("frmText", child2Steps[4].Name, $"In Child2 - Text should be added after {checklist.Name}");
                Assert.AreEqual("Text1", child2Steps[4].Title, "In Child2 - Text should have 'Text1' as title");
                Assert.AreEqual(arg.textTypeKey, child2Steps[4].Filter1Value, $"In Child2 - Text should have correct filter value as {arg.textTypeKey}");
                Assert.IsTrue(child2Steps[1].IsInherited, "In Child2 - Text should have IsInherited flag set to true");

                Assert.AreEqual("frmCheckList", child2Steps[5].Name, "In Child2 - Checklist should be added after newly added Text");
                Assert.AreEqual("Checklist2", child2Steps[5].Title, "In Child2 - Checklist should have 'Checklist2' as title");
                Assert.AreEqual(arg.checklistTypeKey2, child2Steps[5].Filter1Value, $"In Child2 - Checklist should have correct filter value as {arg.checklistTypeKey2}");
                Assert.IsTrue(child2Steps[1].IsInherited, "In Child2 - Newly added Checklist step should have IsInherited flag set to true");

                //GrandChild21
                var child21Steps = grandChild21.WorkflowWizard.TopicControls.OrderBy(t => t.RowPosition).ToArray();
                Assert.AreEqual("frmCaseHistory", child21Steps[0].Name, "In Child21 - Existing Case History Step is at first place");
                Assert.AreEqual("frmCheckList", child21Steps[1].Name, "In Child21 - Checklist with filter type 1 is after Case History step");

                Assert.AreEqual("frmCheckList", child21Steps[2].Name, "In Child21 - Does not take addition of Checklist with filter typ 2, since its already existing");
                Assert.IsFalse(child21Steps[2].IsInherited, "In Child21 - Does not take addition of Checklist with type 2, since it already has it");

                Assert.AreEqual("frmText", child21Steps[3].Name, "In Child21 -Does not take addition of text, since its already existing");
                Assert.IsFalse(child21Steps[3].IsInherited, "In Child21 - Does not take addition ofText, since it already has it");

                Assert.AreEqual("frmNames", child21Steps[4].Name, $"In Child21 - Names should be added at the end since {frmAttributes.Name} does not exist");
                Assert.AreEqual("Names1", child21Steps[4].Title, "In Child21 - Names should have 'Names1' as title");
                Assert.AreEqual(arg.nameTypeKey, child21Steps[4].Filter1Value, $"In Child21 - Names should have correct filter value as {arg.nameTypeKey}");
                Assert.IsTrue(child21Steps[4].IsInherited, "In Child21 - Names should have IsInherited flag set to true");
            }

            VerifyAdditionsAreSyncedWithScreenControl(data);
        }

        static string[] Names(params TopicControl[] steps)
        {
            return steps.Select(_ => _.Name).ToArray();
        }

        [Test]
        public void ReorderStepsAndPropogateToDescendents()
        {
            var data = CriteriaTreeBuilder.Build();
            TopicControl tcAttributes, tcDesignation, tcChecklist1, tcChecklist2, tcTextType;
            Dictionary<string, int> parentStepIds;

            using (var setup = new EntryDbSetup())
            {
                var country = setup.InsertWithNewId(new Country {AllMembersFlag = 0, Type = "0", Name = RandomString.Next(15)}).Id;
                var countryFlag = setup.Insert(new CountryFlag(country, Fixture.Short(), Fixture.String(5))).FlagNumber.ToString();
                var checklistTypeKey1 = setup.InsertWithNewId(new CheckList {Description = Fixture.String(20)}).Id.ToString();
                var checklistTypeKey2 = setup.InsertWithNewId(new CheckList {Description = Fixture.String(20)}).Id.ToString();
                var textTypeKey = setup.InsertWithNewId(new TextType(Fixture.String(20))).Id;

                tcAttributes = setup.CreateStep("frmAttributes", "G", inherited: true);
                tcDesignation = setup.CreateStep("frmDesignation", "F - CountryFlag", filter1Name: "CountryFlag", filter1Value: countryFlag, inherited: true);
                tcChecklist1 = setup.CreateStep("frmCheckList", "C - ChecklistTypeKey", filter1Name: "ChecklistTypeKey", filter1Value: checklistTypeKey1);
                tcChecklist2 = setup.CreateStep("frmCheckList", "C - ChecklistTypeKey", filter1Name: "ChecklistTypeKey", filter1Value: checklistTypeKey2);
                tcTextType = setup.CreateStep("frmText", "T - TextTypeKey", filter1Name: "TextTypeKey", filter1Value: textTypeKey);

                data.Parent.FirstEntry().QuickAddSteps(tcAttributes.Clone(), tcDesignation.Clone(), tcChecklist1.Clone());
                data.Child1.FirstEntry().QuickAddSteps(tcAttributes.Clone(), tcDesignation.Clone(), tcChecklist1.Clone(), tcChecklist2.Clone(), tcTextType.Clone());

                data.Child2.FirstEntry().QuickAddSteps(tcAttributes.Clone(), tcDesignation.Clone(), tcChecklist1.Clone(), tcChecklist2.Clone());
                data.GrandChild21.FirstEntry().QuickAddSteps(tcChecklist1.Clone(), tcAttributes.Clone(), tcTextType.Clone());
                data.GrandChild22.FirstEntry().QuickAddSteps(tcAttributes.Clone(), tcDesignation.Clone(), tcChecklist2.Clone(), tcChecklist1.Clone());
                data.GreatGrandChild211.FirstEntry().QuickAddSteps(tcAttributes.Clone(), tcDesignation.Clone(), tcChecklist1.Clone());

                var parent = setup.DbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == data.Parent.Id);
                parentStepIds = parent.WorkflowWizard.TopicControls.ToDictionary(k => k.Name, v => v.Id);
            }

            ApiClient.Put($"configuration/rules/workflows/{data.Parent.Id}/entrycontrol/{data.Parent.FirstEntry().Id}",
                          JsonConvert.SerializeObject( new WorkflowEntryControlSaveModel
                                                      {
                                                          CriteriaId = data.Parent.Id,
                                                          Id = data.Parent.FirstEntry().Id,
                                                          Description = data.Parent.FirstEntry().Description,
                                                          ApplyToDescendants = true,
                                                          StepsDelta = new Delta<StepDelta>
                                                          {
                                                              Added = new[]
                                                              {
                                                                  new StepDelta("frmBudget", "G" )
                                                                  {
                                                                      NewItemId = "A",
                                                                      Title = "Budget",
                                                                      RelativeId = parentStepIds["frmCheckList"].ToString()
                                                                  }
                                                              }
                                                          },
                                                          StepsMoved = new[]
                                                          {
                                                              new StepMovements(parentStepIds["frmDesignation"]),
                                                              new StepMovements(parentStepIds["frmAttributes"], "A"),
                                                          }
                                                      }
                                                     ));

            using (var ctx = new SqlDbContext())
            {
                var tcBudget = new TopicControl("frmBudget");
                var result = ctx.Set<WindowControl>()
                                .Include(_ => _.TopicControls)
                                .Where(_ => data.CriteriaIds.Contains((int)_.CriteriaId))
                                .Select(_ => new {_.CriteriaId, TopicControls = _.TopicControls.OrderBy(t => t.RowPosition)})
                                .ToArray()
                                .ToDictionary(k => k.CriteriaId, v => v.TopicControls.ToArray());

                CollectionAssert.AreEqual(Names(tcDesignation, tcChecklist1, tcBudget, tcAttributes), Names(result[data.Parent.Id]), "Movements in parent is correct");

                CollectionAssert.AreEqual(Names(tcDesignation, tcChecklist1, tcBudget, tcAttributes, tcChecklist2, tcTextType), Names(result[data.Child1.Id]), "Movement in parent replicated in child #1, which has additional steps");

                CollectionAssert.AreEqual(Names(tcDesignation, tcChecklist1, tcBudget, tcAttributes, tcChecklist2), Names(result[data.Child2.Id]), "Movement in parent replicated in child #2, which has less steps, ignores movement that cannot be actioned.");
                Assert.AreEqual(tcChecklist1.Filter1Value, result[data.Child2.Id].Skip(1).First().Filter1Value, $"Filter values considered while determining step, Checklist step with value {tcChecklist1.Filter1Value}");
                Assert.AreEqual(tcChecklist2.Filter1Value, result[data.Child2.Id].Last().Filter1Value, $"Filter values considered while determining step, Checklist step with value {tcChecklist2.Filter1Value}");

                CollectionAssert.AreEqual(Names(tcChecklist1, tcBudget, tcAttributes, tcTextType), Names(result[data.GrandChild21.Id].ToArray()), "Movement in parent cannot be replicated in grand child #21");

                CollectionAssert.AreEqual(Names(tcDesignation, tcChecklist2, tcChecklist1, tcBudget, tcAttributes), Names(result[data.GrandChild22.Id]), "Movements in parent replicated in grand child #22, which has different additional steps in order");

                CollectionAssert.AreEqual(Names(tcAttributes, tcDesignation, tcChecklist1, tcBudget), Names(result[data.GreatGrandChild211.Id]), "Movements in parent cannot be replicated because grand child #21 did not move in the hierarchy chain");
            }
        }
    }
}