using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using Action = InprotechKaizen.Model.Cases.Action;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.Entries
{
    public partial class EntrySteps
    {

        [Test]
        public void SyncTopicControlToScreenControl()
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

                var action = x.InsertWithNewId(new Action(Fixture.String(5))).Code;
                var country = x.InsertWithNewId(new Country { AllMembersFlag = 0, Type = "0", Name = RandomString.Next(15) }).Id;
                var countryFlag = x.Insert(new CountryFlag(country, Fixture.Short(), Fixture.String(5))).FlagNumber.ToString();
                var checklistTypeKey = x.InsertWithNewId(new CheckList { Description = Fixture.String(20) }).Id.ToString();
                var nameGroupKey = x.InsertWithNewId(new NameGroup { Value = Fixture.String(20) }).Id.ToString();
                var nameTypeKey1 = x.Insert(new NameType(Fixture.String(2), Fixture.String(20))).NameTypeCode;
                var nameTypeKey2 = x.Insert(new NameType(Fixture.String(2), Fixture.String(20))).NameTypeCode;
                var textTypeKey1 = x.InsertWithNewId(new TextType(Fixture.String(20))).Id;
                var textTypeKey2 = x.InsertWithNewId(new TextType(Fixture.String(20))).Id;
                var relationship1 = x.InsertWithNewId(new CaseRelation { Description = Fixture.String(20) }).Relationship;
                var relationship2 = x.InsertWithNewId(new CaseRelation { Description = Fixture.String(20) }).Relationship;
                var numberTypeKey = x.InsertWithNewId(new NumberType { Name = Fixture.String(20) }).NumberTypeCode;

                var noFilterScreen = x.Insert(new Screen { ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "G" }); /* G = no filter */

                var checklistFilterScreen = x.Insert(new Screen { ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "C" });
                var countryFlagScreen = x.Insert(new Screen { ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "F" });
                var nameGroupScreen = x.Insert(new Screen { ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "P" });
                var textTypeScreen = x.Insert(new Screen { ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "T" });
                var nameTypeScreen = x.Insert(new Screen { ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "N" });
                var createActionScreen = x.Insert(new Screen { ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "A" });
                var caseRelationScreen = x.Insert(new Screen { ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "R" });
                var mandatoryRelationScreen = x.Insert(new Screen { ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "M" });
                var numberTypeScreen = x.Insert(new Screen { ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "O" });

                var doubleFilterScreen = x.Insert(new Screen { ScreenName = Fixture.String(20), ScreenTitle = Fixture.String(20), ScreenType = "X" });

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

                var noFilterStep = entry.AddStep(noFilterScreen.ScreenName, noFilterScreen.ScreenTitle, generalStepUserTip);

                var checklistStep = entry.AddStep(checklistFilterScreen.ScreenName, checklistFilterScreen.ScreenTitle, checklistStepUserTip, "ChecklistTypeKey", checklistTypeKey);
                var countryFlagStep = entry.AddStep(countryFlagScreen.ScreenName, countryFlagScreen.ScreenTitle, countryFlagStepUserTip, "CountryFlag", countryFlag);
                var nameGroupStep = entry.AddStep(nameGroupScreen.ScreenName, nameGroupScreen.ScreenTitle, nameGroupStepUserTip, "NameGroupKey", nameGroupKey);
                var textTypeStep = entry.AddStep(textTypeScreen.ScreenName, textTypeScreen.ScreenTitle, textTypeStepUserTip, "TextTypeKey", textTypeKey1);
                var nameTypeStep = entry.AddStep(nameTypeScreen.ScreenName, nameTypeScreen.ScreenTitle, nameTypeStepUserTip, "NameTypeKey", nameTypeKey1);
                var createActionStep = entry.AddStep(createActionScreen.ScreenName, createActionScreen.ScreenTitle, createActionStepUserTip, "CreateActionKey", action);
                var caseRelationStep = entry.AddStep(caseRelationScreen.ScreenName, caseRelationScreen.ScreenTitle, caseRelationStepUserTip, "CaseRelationKey", relationship1);
                var mandatoryRelationshipStep = entry.AddStep(mandatoryRelationScreen.ScreenName, mandatoryRelationScreen.ScreenTitle, mandatoryRelationStepUserTip, "CaseRelationKey", relationship2);
                var numberTypeStep = entry.AddStep(numberTypeScreen.ScreenName, numberTypeScreen.ScreenTitle, numberTypeStepUserTip, "NumberTypeKeys", numberTypeKey);
                var nameTextStep = entry.AddStep(doubleFilterScreen.ScreenName, doubleFilterScreen.ScreenTitle, nameTextStepUserTip, "NameTypeKey", nameTypeKey2, "TextTypeKey", textTypeKey2);

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
                var d = ctx.Set<TopicControl>()
                           .Where(_ => new[]
                                       {
                                           data.noFilterStep.Id,
                                           data.checklistStep.Id,
                                           data.countryFlagStep.Id,
                                           data.nameGroupStep.Id,
                                           data.textTypeStep.Id,
                                           data.nameTypeStep.Id,
                                           data.createActionStep.Id,
                                           data.caseRelationStep.Id,
                                           data.mandatoryRelationshipStep.Id,
                                           data.numberTypeStep.Id,
                                           data.nameTextStep.Id
                                       }.Contains(_.Id))
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
    }
}
