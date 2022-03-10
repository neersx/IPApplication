using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.Entries
{
    public partial class EntrySteps
    {
        [Test]
        public void SyncScreenControlToTopicControl()
        {
            var data = DbSetup.Do(x =>
                                  {
                                      var criteria = x.InsertWithNewId(new Criteria
                                                                       {
                                                                           Description = Fixture.Prefix("parent"),
                                                                           PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                                                       });

                                      var entry = x.Insert(new DataEntryTask
                                                           {
                                                               CriteriaId = criteria.Id,
                                                               Description = Fixture.String(30),
                                                               DisplaySequence = 1
                                                           });

                                      var action = x.InsertWithNewId(new Action(Fixture.String(5)));
                                      var country = x.InsertWithNewId(new Country {AllMembersFlag = 0, Type = "0", Name = RandomString.Next(15)}).Id;
                                      var countryFlag = x.Insert(new CountryFlag(country, Fixture.Short(), Fixture.String(5)));
                                      var checklistTypeKey = x.InsertWithNewId(new CheckList {Description = Fixture.String(20)});
                                      var nameGroupKey = x.InsertWithNewId(new NameGroup { Value = Fixture.String(20)});
                                      var nameTypeKey1 = x.Insert(new NameType(Fixture.String(2), Fixture.String(20)));
                                      var nameTypeKey2 = x.Insert(new NameType(Fixture.String(2), Fixture.String(20)));
                                      var textTypeKey1 = x.InsertWithNewId(new TextType(Fixture.String(20)));
                                      var textTypeKey2 = x.InsertWithNewId(new TextType(Fixture.String(20)));
                                      var relationship1 = x.InsertWithNewId(new CaseRelation {Description = Fixture.String(20)});
                                      var relationship2 = x.InsertWithNewId(new CaseRelation {Description = Fixture.String(20)});
                                      var numberTypeKey = x.InsertWithNewId(new NumberType {Name = Fixture.String(20)});

                                      var noFilterScreen = x.Insert(new Screen {ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "G"}); /* G = no filter */

                                      var checklistFilterScreen = x.Insert(new Screen {ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "C"});
                                      var countryFlagScreen = x.Insert(new Screen {ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "F"});
                                      var nameGroupScreen = x.Insert(new Screen {ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "P"});
                                      var textTypeScreen = x.Insert(new Screen {ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "T"});
                                      var nameTypeScreen = x.Insert(new Screen {ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "N"});
                                      var createActionScreen = x.Insert(new Screen {ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "A"});
                                      var caseRelationScreen = x.Insert(new Screen {ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "R"});
                                      var mandatoryRelationScreen = x.Insert(new Screen {ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "M"});
                                      var numberTypeScreen = x.Insert(new Screen {ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "O"});

                                      var doubleFilterScreen = x.Insert(new Screen {ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "X"});

                                      var generalStepUserTip = Fixture.String(20);
                                      var checklistStepUserTip = Fixture.String(20);
                                      var countryFlagStepUserTip = Fixture.String(20);
                                      var nameGroupStepUserTip = Fixture.String(20);
                                      var textTypeStepUserTip = Fixture.String(20);
                                      var nameTypeStepUserTip = Fixture.String(20);
                                      var createActionStepUserTip = Fixture.String(20);
                                      var caseRelationStepUserTip = Fixture.String(20);
                                      var mandatoryRelationStepUserTip = Fixture.String(20);
                                      var numberTypeStepUserTip = Fixture.String(20);
                                      var nameTextStepUserTip = Fixture.String(20);

                                      var screenId = 0;

                                      var noFilterStep = x.Insert(new DataEntryTaskStep(entry.Criteria)
                                                                  {
                                                                      DataEntryTaskId = entry.Id,
                                                                      ScreenName = noFilterScreen.ScreenName,
                                                                      ScreenTitle = noFilterScreen.ScreenTitle,
                                                                      ScreenId = (short) screenId++,
                                                                      ScreenTip = generalStepUserTip
                                                                  });

                                      var checklistStep = x.Insert(new DataEntryTaskStep(entry.Criteria)
                                                                   {
                                                                       DataEntryTaskId = entry.Id,
                                                                       ScreenName = checklistFilterScreen.ScreenName,
                                                                       ScreenTitle = checklistFilterScreen.ScreenTitle,
                                                                       ScreenId = (short) screenId++,
                                                                       ScreenTip = checklistStepUserTip,
                                                                       Checklist = checklistTypeKey
                                                                   });

                                      var countryFlagStep = x.Insert(new DataEntryTaskStep(entry.Criteria)
                                                                     {
                                                                         DataEntryTaskId = entry.Id,
                                                                         ScreenName = countryFlagScreen.ScreenName,
                                                                         ScreenTitle = countryFlagScreen.ScreenTitle,
                                                                         ScreenId = (short) screenId++,
                                                                         ScreenTip = countryFlagStepUserTip,
                                                                         FlagNumber = countryFlag.FlagNumber
                                                                     });

                                      var nameGroupStep = x.Insert(new DataEntryTaskStep(entry.Criteria)
                                                                   {
                                                                       DataEntryTaskId = entry.Id,
                                                                       ScreenName = nameGroupScreen.ScreenName,
                                                                       ScreenTitle = nameGroupScreen.ScreenTitle,
                                                                       ScreenId = (short) screenId++,
                                                                       ScreenTip = nameGroupStepUserTip,
                                                                       NameGroupId = nameGroupKey.Id
                                                                   });

                                      var textTypeStep = x.Insert(new DataEntryTaskStep(entry.Criteria)
                                                                  {
                                                                      DataEntryTaskId = entry.Id,
                                                                      ScreenName = textTypeScreen.ScreenName,
                                                                      ScreenTitle = textTypeScreen.ScreenTitle,
                                                                      ScreenId = (short) screenId++,
                                                                      ScreenTip = textTypeStepUserTip,
                                                                      TextTypeId = textTypeKey1.Id
                                                                  });

                                      var nameTypeStep = x.Insert(new DataEntryTaskStep(entry.Criteria)
                                                                  {
                                                                      DataEntryTaskId = entry.Id,
                                                                      ScreenName = nameTypeScreen.ScreenName,
                                                                      ScreenTitle = nameTypeScreen.ScreenTitle,
                                                                      ScreenId = (short) screenId++,
                                                                      ScreenTip = nameTypeStepUserTip,
                                                                      NameTypeCode = nameTypeKey1.NameTypeCode
                                                                  });

                                      var createActionStep = x.Insert(new DataEntryTaskStep(entry.Criteria)
                                                                      {
                                                                          DataEntryTaskId = entry.Id,
                                                                          ScreenName = createActionScreen.ScreenName,
                                                                          ScreenTitle = createActionScreen.ScreenTitle,
                                                                          ScreenId = (short) screenId++,
                                                                          ScreenTip = createActionStepUserTip,
                                                                          CreateActionId = action.Code
                                                                      });

                                      var caseRelationStep = x.Insert(new DataEntryTaskStep(entry.Criteria)
                                                                      {
                                                                          DataEntryTaskId = entry.Id,
                                                                          ScreenName = caseRelationScreen.ScreenName,
                                                                          ScreenTitle = caseRelationScreen.ScreenTitle,
                                                                          ScreenId = (short) screenId++,
                                                                          ScreenTip = caseRelationStepUserTip,
                                                                          RelationshipId = relationship1.Relationship
                                                                      });

                                      var mandatoryRelationshipStep = x.Insert(new DataEntryTaskStep(entry.Criteria)
                                                                               {
                                                                                   DataEntryTaskId = entry.Id,
                                                                                   ScreenName = mandatoryRelationScreen.ScreenName,
                                                                                   ScreenTitle = mandatoryRelationScreen.ScreenTitle,
                                                                                   ScreenId = (short) screenId++,
                                                                                   ScreenTip = mandatoryRelationStepUserTip,
                                                                                   RelationshipId = relationship2.Relationship
                                                                               });

                                      var numberTypeStep = x.Insert(new DataEntryTaskStep(entry.Criteria)
                                                                    {
                                                                        DataEntryTaskId = entry.Id,
                                                                        ScreenName = numberTypeScreen.ScreenName,
                                                                        ScreenTitle = numberTypeScreen.ScreenTitle,
                                                                        ScreenId = (short) screenId++,
                                                                        ScreenTip = numberTypeStepUserTip,
                                                                        GenericParameter = numberTypeKey.NumberTypeCode
                                                                    });

                                      var nameTextStep = x.Insert(new DataEntryTaskStep(entry.Criteria)
                                                                  {
                                                                      DataEntryTaskId = entry.Id,
                                                                      ScreenName = doubleFilterScreen.ScreenName,
                                                                      ScreenTitle = doubleFilterScreen.ScreenTitle,
                                                                      ScreenId = (short) screenId,
                                                                      ScreenTip = nameTextStepUserTip,
                                                                      NameTypeCode = nameTypeKey2.NameTypeCode,
                                                                      TextTypeId = textTypeKey2.Id
                                                                  });

                                      return new
                                             {
                                                 entry,
                                                 noFilterStep,
                                                 checklistStep,
                                                 countryFlagStep,
                                                 nameGroupStep,
                                                 textTypeStep,
                                                 nameTypeStep,
                                                 createActionStep,
                                                 caseRelationStep,
                                                 mandatoryRelationshipStep,
                                                 numberTypeStep,
                                                 nameTextStep
                                             };
                                  });

            using (var ctx = new SqlDbContext())
            {
                var d = ctx.Set<DataEntryTask>()
                           .Single(_ => _.CriteriaId == data.entry.CriteriaId && _.Id == data.entry.Id)
                           .TaskSteps
                           .SelectMany(_ => _.TopicControls)
                           .ToDictionary(k => k.TopicSuffix, v => v);

                var result = (from step in ctx.Set<DataEntryTaskStep>()
                              join screen in ctx.Set<Screen>() on step.ScreenName equals screen.ScreenName into js
                              from screen in js.DefaultIfEmpty()
                              where step.CriteriaId == data.entry.CriteriaId && step.DataEntryTaskId == data.entry.Id
                              select new
                                     {
                                         screen.ScreenType,
                                         step
                                     })
                    .ToDictionary(k => k.ScreenType, v => v.step);

                foreach (var r in result.Keys)
                {
                    var screenControl = result[r];
                    TopicControl topicControl;

                    d.TryGetValue(screenControl.ScreenId.ToString(), out topicControl);

                    Assert.NotNull(topicControl, $"Should be able to link from screen control to topic control via TopicSuffix - {screenControl.ScreenId}, type='{r}'");

                    Assert.AreEqual(topicControl.ScreenTip, screenControl.ScreenTip, $"Should have same screentip for {topicControl.Name}");
                    Assert.AreEqual(topicControl.Title, screenControl.ScreenTitle, $"Should have same title for {topicControl.Name}");
                    Assert.AreEqual(topicControl.IsMandatory, screenControl.IsMandatoryStep, $"Should have same mandatory flag for {topicControl.Name}");
                    Assert.AreEqual(topicControl.IsInherited, screenControl.IsInherited, $"Should have same inherited flag for {topicControl.Name}");

                    switch (r)
                    {
                        case "G":
                            break;

                        case "C":
                            Assert.AreEqual("ChecklistTypeKey", topicControl.Filter1Name);
                            Assert.AreEqual(topicControl.Filter1Value, screenControl.ChecklistType.ToString(), "Should have same Checklist Type");
                            break;

                        case "F":
                            Assert.AreEqual("CountryFlag", topicControl.Filter1Name);
                            Assert.AreEqual(topicControl.Filter1Value, screenControl.FlagNumber.ToString(), "Should have same Flag Number");
                            break;

                        case "P":
                            Assert.AreEqual("NameGroupKey", topicControl.Filter1Name);
                            Assert.AreEqual(topicControl.Filter1Value, screenControl.NameGroupId.ToString(), "Should have same Name Group");
                            break;

                        case "T":
                            Assert.AreEqual("TextTypeKey", topicControl.Filter1Name);
                            Assert.AreEqual(topicControl.Filter1Value, screenControl.TextTypeId, "Should have same Text Type");
                            break;

                        case "N":
                            Assert.AreEqual("NameTypeKey", topicControl.Filter1Name);
                            Assert.AreEqual(topicControl.Filter1Value, screenControl.NameTypeCode, "Should have same Name Type");
                            break;

                        case "A":
                            Assert.AreEqual("CreateActionKey", topicControl.Filter1Name);
                            Assert.AreEqual(topicControl.Filter1Value, screenControl.CreateActionId, "Should have same Action");
                            break;

                        case "R":
                        case "M":
                            Assert.AreEqual("CaseRelationKey", topicControl.Filter1Name);
                            Assert.AreEqual(topicControl.Filter1Value, screenControl.RelationshipId, "Should have same Relationship");
                            break;

                        case "O":
                            Assert.AreEqual("NumberTypeKeys", topicControl.Filter1Name);
                            Assert.AreEqual(topicControl.Filter1Value, screenControl.GenericParameter, "Should have same Number Type");
                            break;

                        case "X":
                            Assert.AreEqual("NameTypeKey", topicControl.Filter1Name);
                            Assert.AreEqual(topicControl.Filter1Value, screenControl.NameTypeCode, "Should have same Name Type for Name Text step");

                            Assert.AreEqual("TextTypeKey", topicControl.Filter2Name);
                            Assert.AreEqual(topicControl.Filter2Value, screenControl.TextTypeId, "Should have same Text Type for Name Text step");
                            break;
                    }
                }
            }
        }

        public void VerifyDeletesAreSyncedToScreenControl(CriteriaTreeBuilder.CriteriaTreeFixture data)
        {
            using (var ctx = new SqlDbContext())
            {
                var result = ctx.Set<DataEntryTaskStep>()
                                .Where(_ => data.CriteriaIds.Contains(_.CriteriaId))
                                .GroupBy(_ => _.CriteriaId)
                                .ToDictionary(g => g.Key, g => g.Select(d => d).ToArray());

                var parent = result[data.Parent.Id];
                var child1 = result[data.Child1.Id];
                var child2 = result[data.Child2.Id];
                var grandChild21 = result[data.GrandChild21.Id];

                Assert.AreEqual(2, parent.Length);

                Assert.AreEqual(4, child1.Length);

                Assert.AreEqual(3, child2.Length);
                Assert.IsFalse(child2.Single(_ => _.ScreenName == "frmCheckList").IsInherited);

                Assert.AreEqual(4, grandChild21.Length);
                Assert.IsTrue(grandChild21.Single(_ => _.ScreenName == "frmCheckList").IsInherited);
            }
        }

        public void VerifyAdditionsAreSyncedWithScreenControl(CriteriaTreeBuilder.CriteriaTreeFixture data)
        {
            using (var ctx = new SqlDbContext())
            {
                var result = ctx.Set<DataEntryTaskStep>()
                                .Where(_ => data.CriteriaIds.Contains(_.CriteriaId) && _.DataEntryTaskId != null)
                                .GroupBy(_ => _.CriteriaId)
                                .ToDictionary(g => g.Key, g => g.Select(d => d).ToArray());

                var parent = result[data.Parent.Id];
                var child1 = result[data.Child1.Id];
                var child2 = result[data.Child2.Id];
                var grandChild21 = result[data.GrandChild21.Id];

                Assert.AreEqual(6, parent.Length);

                Assert.AreEqual(6, child1.Length);
                Assert.IsTrue(child1.Single(_ => _.ScreenName == "frmNames").IsInherited);

                Assert.AreEqual(6, child2.Length);
                Assert.IsTrue(child2.All(_ =>_.IsInherited));

                Assert.AreEqual(5, grandChild21.Length);
                Assert.IsTrue(grandChild21.Single(_ => _.ScreenName == "frmNames").IsInherited);
            }
        }
    }
}