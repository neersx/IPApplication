using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;
using NUnit.Framework;

#pragma warning disable 618
namespace Inprotech.Tests.Integration.IntegrationTests.Workflows.EventControl
{
    [Category(Categories.Integration)]
    [TestFrom(DbCompatLevel.Release14)]
    [TestFixture]
    public class EventControl : IntegrationTest
    {
        [Test]
        public void UpdateLoadEvent()
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var useEvent1 = eventBuilder.Create("Event to Use");
                var adjustDate1 = setup.InsertWithNewId(new DateAdjustment {Description = Fixture.Prefix("Date Adjustment")});
                var useEvent2 = eventBuilder.Create("Event to Use");
                var adjustDate2 = setup.InsertWithNewId(new DateAdjustment {Description = Fixture.Prefix("Date Adjustment")});
                var withRelationship = setup.InsertWithNewId(new CaseRelation {Description = Fixture.Prefix("Relationship")});
                var officialNumber = setup.InsertWithNewId(new NumberType {Name = Fixture.Prefix("Official Number")});

                var fixture = new EventControlDbSetup().SetupCriteriaInheritance(new ValidEvent
                {
                    SyncedFromCaseOption = SyncedFromCaseOption.RelatedCase,
                    SyncedEventId = useEvent1.Id,
                    SyncedEventDateAdjustmentId = adjustDate1.Id,
                    SyncedCaseRelationshipId = withRelationship.Relationship,
                    UseCycle = UseCycleOption.CaseRelationship,
                    SyncedNumberTypeId = officialNumber.NumberTypeCode
                });

                return new
                {
                    fixture.EventId,
                    ParentId = fixture.CriteriaId,
                    ChildId = fixture.ChildCriteriaId,
                    ImportanceLevel = fixture.Importance,
                    NewUseEventId = useEvent2.Id,
                    NewAdjustDateId = adjustDate2.Id
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.ImportanceLevel,
                CaseOption = SyncedFromCaseOption.SameCase,
                FromEvent = data.NewUseEventId,
                DateAdjustment = data.NewAdjustDateId
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.ParentId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ParentId && _.EventId == data.EventId);
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);

                Assert.AreEqual(0, parent.SyncedFromCase);
                Assert.AreEqual(data.NewUseEventId, parent.SyncedEventId);
                Assert.AreEqual(data.NewAdjustDateId, parent.SyncedEventDateAdjustmentId);
                Assert.AreEqual(null, parent.SyncedCaseRelationshipId);
                Assert.AreEqual(null, parent.UseReceivingCycle);
                Assert.AreEqual(null, parent.SyncedNumberTypeId);

                Assert.AreEqual(0, child.SyncedFromCase);
                Assert.AreEqual(data.NewUseEventId, child.SyncedEventId);
                Assert.AreEqual(data.NewAdjustDateId, child.SyncedEventDateAdjustmentId);
                Assert.AreEqual(null, child.SyncedCaseRelationshipId);
                Assert.AreEqual(null, child.UseReceivingCycle);
                Assert.AreEqual(null, child.SyncedNumberTypeId);
            }
        }

        [Test]
        public void UpdateDueDateResponsibilityToNameAndDoNotApplyToCaseEvents()
        {
            var data = new EventControlDbSetup().SetupResponsibilityData();

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                DueDateRespType = DueDateRespTypes.Name,
                DueDateRespNameId = data.NewNameId,
                ChangeRespOnDueDates = false,
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.ParentId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ParentId && _.EventId == data.EventId);
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);

                var parentCaseEvent = dbContext.Set<CaseEvent>().Single(_ => _.CaseId == data.ParentCaseId && _.EventNo == data.EventId);
                var childCaseEvent = dbContext.Set<CaseEvent>().Single(_ => _.CaseId == data.ChildCaseId && _.EventNo == data.EventId);

                Assert.AreEqual(data.NewNameId, parent.DueDateRespNameId, "Updates Parent ValidEvent with submitted Name");
                Assert.AreEqual(null, parent.DueDateRespNameTypeCode);
                Assert.AreEqual(data.NewNameId, child.DueDateRespNameId, "Updates Child ValidEvent with submitted Name");
                Assert.AreEqual(null, child.DueDateRespNameTypeCode);

                Assert.AreNotEqual(data.NewNameId, parentCaseEvent.EmployeeNo, "Does not update parent CaseEvent with submitted Name");
                Assert.AreNotEqual(data.NewNameId, childCaseEvent.EmployeeNo, "Does not update child CaseEvent with submitted Name");
            }
        }

        [Test]
        public void UpdateDueDateResponsibilityToNameTypeAndApplyToCaseEvents()
        {
            var data = new EventControlDbSetup().SetupResponsibilityData();

            var formData = new WorkflowEventControlSaveModel
            {
                ImportanceLevel = data.Importance,
                DueDateRespType = DueDateRespTypes.NameType,
                DueDateRespNameTypeCode = data.CaseNameType,
                ChangeRespOnDueDates = true,
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.ParentId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ParentId && _.EventId == data.EventId);
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);

                var parentCaseEvent = dbContext.Set<CaseEvent>().Single(_ => _.CaseId == data.ParentCaseId && _.EventNo == data.EventId);
                var childCaseEvent = dbContext.Set<CaseEvent>().Single(_ => _.CaseId == data.ChildCaseId && _.EventNo == data.EventId);

                Assert.AreEqual(null, parent.DueDateRespNameId);
                Assert.AreEqual(data.CaseNameType, parent.DueDateRespNameTypeCode, "Updates Parent ValidEvent with submitted NameType");
                Assert.AreEqual(null, child.DueDateRespNameId);
                Assert.AreEqual(data.CaseNameType, child.DueDateRespNameTypeCode, "Updates Child ValidEvent with submitted NameType");

                Assert.AreEqual(data.CaseNameForParent, parentCaseEvent.EmployeeNo, "Updates CaseEvent with the CaseName with submitted NameType on that Case");
                Assert.AreEqual(null, parentCaseEvent.DueDateResponsibilityNameType, "Because there is a matching CaseName for NameType it sets NameType to null");

                Assert.AreEqual(null, childCaseEvent.EmployeeNo, "There is no matching CaseName for the child case");
                Assert.AreEqual(data.CaseNameType, childCaseEvent.DueDateResponsibilityNameType, "Because there is no matching CaseName for NameType, it sets NameType to submitted NameType");
            }
        }

        /*      Complex Inheritance Scenario
                Before Edit:

                Parent {Description:"Apple", MaxCycles: 1}
                    |______Child1 {Description:"Orange", MaxCycles: 1}
                    |           |___GrandChild1 {Description:"Apple", MaxCycles: 9999}
                    |           
                    |______Child2 {Description:"Apple", MaxCycles: 1}


                ***************************************

                After Edit:

                Parent {Description:"Banana", MaxCycles: 2}
                    |______Child1 {Description:"Orange", MaxCycles: 2}
                    |           |___GrandChild1 {Description:"Apple", MaxCycles: 9999}
                    |           
                    |______Child2 {Description:"Banana", MaxCycles: 2}               */

        [Test]
        public void UpdateEventControlAndApplyFieldByFieldToDescendants()
        {
            var data = DbSetup.Do(setup =>
            {
                var dbSetup = new EventControlDbSetup();
                var f = dbSetup.SetupCriteriaInheritance();
                f.ChildValidEvent.Description = "Orange"; // break field inheritance
                f.GrandchildValidEvent.NumberOfCyclesAllowed = 9999; // break field inheritance
                dbSetup.DbContext.SaveChanges();

                var child2 = new CriteriaBuilder(setup.DbContext).Create("child1", f.CriteriaId);
                setup.Insert(new ValidEvent(child2.Id, f.EventId, "Apple") {NumberOfCyclesAllowed = 1, Inherited = 1});

                var status = dbSetup.InsertWithNewId(new Status {Name = Fixture.String(5)});
                var renewalStatus = dbSetup.InsertWithNewId(new Status {Name = Fixture.String(5), RenewalFlag = 1});

                return new
                {
                    f.EventId,
                    ParentId = f.CriteriaId,
                    Child1Id = f.ChildCriteriaId,
                    GrandChild1Id = f.GrandchildCriteriaId,
                    Child2Id = child2.Id,
                    StatusId = status.Id,
                    RenewalStatusId = renewalStatus.Id,
                    UserDefinedStatus = Fixture.String(5)
                };
            });

            var formData = new WorkflowEventControlSaveModel
            {
                Description = "Banana",
                MaxCycles = 2,
                ImportanceLevel = "7",
                Notes = "Update event control integration test",
                ChangeStatusId = data.StatusId,
                ChangeRenewalStatusId = data.RenewalStatusId,
                UserDefinedStatus = data.UserDefinedStatus,
                ApplyToDescendants = true
            };

            ApiClient.Put("configuration/rules/workflows/" + data.ParentId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ParentId && _.EventId == data.EventId);
                var child1 = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.Child1Id && _.EventId == data.EventId);
                var grandChild1 = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandChild1Id && _.EventId == data.EventId);
                var child2 = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.Child2Id && _.EventId == data.EventId);

                Assert.AreEqual("Banana", parent.Description, "Updates parent");
                Assert.AreEqual(2, parent.NumberOfCyclesAllowed);
                Assert.AreEqual(formData.ImportanceLevel, parent.ImportanceLevel);
                Assert.AreEqual(formData.Notes, parent.Notes);
                Assert.AreEqual(formData.ChangeStatusId, parent.ChangeStatusId);
                Assert.AreEqual(formData.ChangeRenewalStatusId, parent.ChangeRenewalStatusId);
                Assert.AreEqual(formData.UserDefinedStatus, parent.UserDefinedStatus);

                Assert.AreEqual("Orange", child1.Description, "Inheritance for description is broken here");
                Assert.AreEqual(2, child1.NumberOfCyclesAllowed, "Value is same as parent so it inherits new value");
                Assert.AreEqual(formData.ImportanceLevel, child1.ImportanceLevel, "parent and child values were null so inherits new value");
                Assert.AreEqual(formData.Notes, child1.Notes, "parent and child values were null so inherits new value");
                Assert.AreEqual(formData.ChangeStatusId, child1.ChangeStatusId, "parent and child values were null so inherits new value");
                Assert.AreEqual(formData.ChangeRenewalStatusId, child1.ChangeRenewalStatusId, "parent and child values were null so inherits new value");
                Assert.AreEqual(formData.UserDefinedStatus, child1.UserDefinedStatus, "parent and child values were null so inherits new value");

                Assert.AreEqual("Apple", grandChild1.Description, "Inheritance was broken by Child1 so GrandChild1 does not inherit new description");
                Assert.AreEqual(9999, grandChild1.NumberOfCyclesAllowed, "Field is different so does not inherit new value");
                Assert.AreEqual(formData.ImportanceLevel, grandChild1.ImportanceLevel);
                Assert.AreEqual(formData.Notes, grandChild1.Notes);
                Assert.AreEqual(formData.ChangeStatusId, grandChild1.ChangeStatusId);
                Assert.AreEqual(formData.ChangeRenewalStatusId, grandChild1.ChangeRenewalStatusId);
                Assert.AreEqual(formData.UserDefinedStatus, grandChild1.UserDefinedStatus);

                Assert.AreEqual("Banana", child2.Description, "Child2 is not affected by the other tree and inherits new value");
                Assert.AreEqual(2, child2.NumberOfCyclesAllowed);
                Assert.AreEqual(formData.ImportanceLevel, child2.ImportanceLevel);
                Assert.AreEqual(formData.Notes, child2.Notes);
                Assert.AreEqual(formData.ChangeStatusId, child2.ChangeStatusId);
                Assert.AreEqual(formData.ChangeRenewalStatusId, child2.ChangeRenewalStatusId);
                Assert.AreEqual(formData.UserDefinedStatus, child2.UserDefinedStatus);
            }
        }

        [Test]
        public void SaveStandingInstruction()
        {
            var data = DbSetup.Do(setup =>
            {
                var instructionTypeBuilder = new InstructionTypeBuilder(setup.DbContext);
                var characteristicBuilder = new CharacteristicBuilder(setup.DbContext);

                var instructionType = instructionTypeBuilder.Create();
                var characteristic1 = characteristicBuilder.Create(instructionType.Code);
                var newCharacteristic = characteristicBuilder.Create(instructionType.Code);

                var f = new EventControlDbSetup().SetupCriteriaInheritance(new ValidEvent
                {
                    FlagNumber = characteristic1.Id,
                    InstructionType = instructionType.Code
                });

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    Child1CriteriaId = f.ChildCriteriaId,
                    GrandChildCriteriaId = f.GrandchildCriteriaId,
                    f.Importance,
                    InstructionTypeCode = instructionType.Code,
                    NewCharacteristicId = newCharacteristic.Id
                };
            });

            var formData = new WorkflowEventControlSaveModel()
            {
                ImportanceLevel = data.Importance,
                InstructionType = data.InstructionTypeCode,
                Characteristic = data.NewCharacteristicId
            }.WithMandatoryFields();

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.Child1CriteriaId && _.EventId == data.EventId);
                var grandChild = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandChildCriteriaId && _.EventId == data.EventId);

                Assert.AreEqual(data.InstructionTypeCode, parent.InstructionType);
                Assert.AreEqual(data.NewCharacteristicId, parent.FlagNumber, "parent characteristic should change");

                Assert.AreEqual(data.InstructionTypeCode, child.InstructionType);
                Assert.AreEqual(data.NewCharacteristicId, child.FlagNumber, "child characteristic should inherit");

                Assert.AreEqual(data.InstructionTypeCode, grandChild.InstructionType);
                Assert.AreEqual(data.NewCharacteristicId, grandChild.FlagNumber, "grandchild characteristic should inherit");
            }
        }

        [Test]
        public void UpdateMultipleRelatedEventRules()
        {
            var data = DbSetup.Do(setup =>
            {
                var f = new EventControlDbSetup().SetupCriteriaInheritance();

                var eventBuilder = new EventBuilder(setup.DbContext);
                var satisfyingEvent = eventBuilder.Create();

                setup.Insert(new RelatedEventRule(f.CriteriaValidEvent, 0) {IsSatisfyingEvent = true, UpdateEvent = 1, RelatedEventId = satisfyingEvent.Id, RelativeCycleId = 1, ClearEvent = 1});
                setup.Insert(new RelatedEventRule(f.ChildValidEvent, 0) {IsSatisfyingEvent = true, Inherited = 1, UpdateEvent = 1, RelatedEventId = satisfyingEvent.Id, RelativeCycleId = 1, ClearEvent = 1});

                return new
                {
                    f.EventId,
                    f.CriteriaId,
                    ChildId = f.ChildCriteriaId,
                    ImportanceLevel = f.Importance,
                    CommonEventId = eventBuilder.Create().Id,
                    RelativeCycle = (short) 1
                };
            });

            var deleteSatisfyingEvent = new List<RelatedEventRuleSaveModel>
            {
                new RelatedEventRuleSaveModel
                {
                    Sequence = 0,
                    SatisfyingEventId = data.CommonEventId,
                    RelativeCycle = data.RelativeCycle
                }
            };

            var updateEventToClear = new List<RelatedEventRuleSaveModel>
            {
                new RelatedEventRuleSaveModel
                {
                    Sequence = 0,
                    EventToClearId = data.CommonEventId,
                    RelativeCycle = data.RelativeCycle,
                    ClearEventOnEventChange = false,
                    ClearDueDateOnEventChange = true,
                    ClearEventOnDueDateChange = false,
                    ClearDueDateOnDueDateChange = false
                }
            };

            var deleteEventToUpdate = new List<RelatedEventRuleSaveModel>
            {
                new RelatedEventRuleSaveModel
                {
                    Sequence = 0,
                    EventToUpdateId = data.CommonEventId,
                    RelativeCycle = data.RelativeCycle
                }
            };

            var formData = new WorkflowEventControlSaveModel
            {
                Description = "Apple",
                MaxCycles = 1,
                ApplyToDescendants = true,
                ImportanceLevel = data.ImportanceLevel,
                SatisfyingEventsDelta = new Delta<RelatedEventRuleSaveModel> {Deleted = deleteSatisfyingEvent},
                EventsToClearDelta = new Delta<RelatedEventRuleSaveModel> {Updated = updateEventToClear},
                EventsToUpdateDelta = new Delta<RelatedEventRuleSaveModel> {Deleted = deleteEventToUpdate}
            };

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId, JsonConvert.SerializeObject(formData));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<RelatedEventRule>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var child = dbContext.Set<RelatedEventRule>().Single(_ => _.CriteriaId == data.ChildId && _.EventId == data.EventId);

                Assert.AreEqual(false, parent.IsSatisfyingEvent, "Deletes Satisfying Event");
                Assert.AreEqual(false, parent.IsClearEvent, "Updates Clear Event");
                Assert.AreEqual(true, parent.IsClearDue, "Updates Clear Event");
                Assert.AreEqual(false, parent.IsUpdateEvent, "Deletes update event");

                Assert.AreEqual(false, child.IsSatisfyingEvent, "Updates inherited child Satisfying Event");
                Assert.AreEqual(false, child.IsClearEvent, "Updates inherited child Event to Clear");
                Assert.AreEqual(true, child.IsClearDue, "Updates inherited child Event to Clear");
                Assert.AreEqual(false, child.IsUpdateEvent, "Deletes update event from child");
            }
        }

        [Test]
        public void UpdateReportToCpa()
        {
            var data = DbSetup.Do(setup =>
            {
                var fixture = new EventControlDbSetup().SetupCriteriaInheritance(new ValidEvent
                {
                    IsThirdPartyOn = true,
                    IsThirdPartyOff = false
                });

                return new
                {
                    fixture.CriteriaId,
                    fixture.ChildCriteriaId,
                    fixture.GrandchildCriteriaId,
                    fixture.EventId,
                    fixture.Importance
                };
            });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(new WorkflowEventControlSaveModel
                          {
                              Report = ReportMode.Off,
                              ImportanceLevel = data.Importance
                          }.WithMandatoryFields()));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildCriteriaId && _.EventId == data.EventId);
                var grandChild = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildCriteriaId && _.EventId == data.EventId);

                Assert.False(parent.IsThirdPartyOn);
                Assert.True(parent.IsThirdPartyOff);
                Assert.False(child.IsThirdPartyOn);
                Assert.True(child.IsThirdPartyOff);
                Assert.False(grandChild.IsThirdPartyOn);
                Assert.True(grandChild.IsThirdPartyOff);
            }
        }

        [Test]
        public void UpdateNameChange()
        {
            var data = DbSetup.Do(setup =>
            {
                var dbSetup = new EventControlDbSetup();
                var f = dbSetup.SetupCriteriaInheritance();
                f.GrandchildValidEvent.DeleteCopyFromName = true; // break inheritance
                dbSetup.DbContext.SaveChanges();

                var changeNameType = setup.InsertWithNewId(new NameType());
                var copyFromNameType = setup.InsertWithNewId(new NameType());
                var moveOldNameType = setup.InsertWithNewId(new NameType());

                return new
                {
                    f.CriteriaId,
                    f.ChildCriteriaId,
                    f.GrandchildCriteriaId,
                    f.EventId,
                    f.Importance,
                    ChangeNameTypeCode = changeNameType.NameTypeCode,
                    CopyFromNameTypeCode = copyFromNameType.NameTypeCode,
                    MoveOldNameTypeCode = moveOldNameType.NameTypeCode
                };
            });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(new WorkflowEventControlSaveModel
                          {
                              ChangeNameTypeCode = data.ChangeNameTypeCode,
                              CopyFromNameTypeCode = data.CopyFromNameTypeCode,
                              DeleteCopyFromName = true,
                              MoveOldNameToNameTypeCode = data.MoveOldNameTypeCode,
                              ImportanceLevel = data.Importance
                          }.WithMandatoryFields()));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildCriteriaId && _.EventId == data.EventId);
                var grandChild = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildCriteriaId && _.EventId == data.EventId);

                Assert.AreEqual(data.ChangeNameTypeCode, parent.ChangeNameTypeCode);
                Assert.AreEqual(data.CopyFromNameTypeCode, parent.CopyFromNameTypeCode);
                Assert.True(parent.DeleteCopyFromName);
                Assert.AreEqual(data.MoveOldNameTypeCode, parent.MoveOldNameToNameTypeCode);

                Assert.AreEqual(data.ChangeNameTypeCode, child.ChangeNameTypeCode, "Child inherits Change Name");
                Assert.AreEqual(data.CopyFromNameTypeCode, child.CopyFromNameTypeCode);
                Assert.True(child.DeleteCopyFromName);
                Assert.AreEqual(data.MoveOldNameTypeCode, child.MoveOldNameToNameTypeCode);

                Assert.IsNull(grandChild.ChangeNameTypeCode, "Grandchild does not inherit because of all or none");
                Assert.IsNull(grandChild.CopyFromNameTypeCode);
                Assert.True(grandChild.DeleteCopyFromName);
                Assert.IsNull(grandChild.MoveOldNameToNameTypeCode);
            }
        }

        [Test]
        public void UpdateActionControl()
        {
            var data = DbSetup.Do(setup =>
            {
                var actionBuilder = new ActionBuilder(setup.DbContext);
                var existingOpenAction = actionBuilder.Create(Fixture.Prefix("1"));
                var existingCloseAction = actionBuilder.Create(Fixture.Prefix("2"));
                var newOpenAction = actionBuilder.Create(Fixture.Prefix("3"));
                var newCloseAction = actionBuilder.Create(Fixture.Prefix("4"));

                var fixture = new EventControlDbSetup().SetupCriteriaInheritance(new ValidEvent
                {
                    OpenActionId = existingOpenAction.Code,
                    CloseActionId = existingCloseAction.Code,
                    RelativeCycle = 1
                });

                return new
                {
                    fixture.CriteriaId,
                    fixture.ChildCriteriaId,
                    fixture.GrandchildCriteriaId,
                    fixture.EventId,
                    fixture.Importance,
                    OpenActionId = newOpenAction.Code,
                    CloseActionId = newCloseAction.Code
                };
            });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(new WorkflowEventControlSaveModel
                          {
                              ImportanceLevel = data.Importance,
                              OpenActionId = data.OpenActionId,
                              CloseActionId = data.CloseActionId,
                              RelativeCycle = 0
                          }.WithMandatoryFields()));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildCriteriaId && _.EventId == data.EventId);
                var grandChild = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildCriteriaId && _.EventId == data.EventId);

                Assert.AreEqual(data.OpenActionId, parent.OpenActionId);
                Assert.AreEqual(data.CloseActionId, parent.CloseActionId);
                Assert.AreEqual(0, parent.RelativeCycle);
                Assert.AreEqual(data.OpenActionId, child.OpenActionId);
                Assert.AreEqual(data.CloseActionId, child.CloseActionId);
                Assert.AreEqual(0, child.RelativeCycle);
                Assert.AreEqual(data.OpenActionId, grandChild.OpenActionId);
                Assert.AreEqual(data.CloseActionId, grandChild.CloseActionId);
                Assert.AreEqual(0, grandChild.RelativeCycle);
            }
        }

        [Test]
        public void UpdateCharges()
        {
            var data = DbSetup.Do(setup =>
            {
                var chargeBuilder = new ChargeTypeBuilder(setup.DbContext);

                var existingCharge1 = chargeBuilder.Create();
                var existingCharge2 = chargeBuilder.Create();
                var newCharge1 = chargeBuilder.Create();
                var newCharge2 = chargeBuilder.Create();

                var fixture = new EventControlDbSetup().SetupCriteriaInheritance(new ValidEvent
                {
                    InitialFeeId = existingCharge1.Id,
                    InitialFee2Id = existingCharge2.Id,
                    IsDirectPay = true,
                    IsPayFee2 = true
                });

                return new
                {
                    fixture.CriteriaId,
                    fixture.ChildCriteriaId,
                    fixture.GrandchildCriteriaId,
                    fixture.EventId,
                    fixture.Importance,
                    Charge1 = newCharge1.Id,
                    Charge2 = newCharge2.Id
                };
            });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId,
                          JsonConvert.SerializeObject(new WorkflowEventControlSaveModel
                          {
                              ImportanceLevel = data.Importance,
                              ChargeType = data.Charge1,
                              IsRaiseCharge = true,
                              IsEstimate = true,
                              ChargeType2 = data.Charge2,
                              IsDirectPay2 = true
                          }.WithMandatoryFields()));

            using (var dbContext = new SqlDbContext())
            {
                var parent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);
                var child = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.ChildCriteriaId && _.EventId == data.EventId);
                var grandChild = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.GrandchildCriteriaId && _.EventId == data.EventId);

                Assert.AreEqual(data.Charge1, parent.InitialFeeId);
                Assert.False(parent.IsDirectPayBool, "old flag is now false");
                Assert.True(parent.IsRaiseCharge);
                Assert.True(parent.IsEstimate);
                Assert.AreEqual(data.Charge2, parent.InitialFee2Id);
                Assert.False(parent.IsPayFee2, "old flag is now false");
                Assert.True(parent.IsDirectPayBool2);

                Assert.AreEqual(data.Charge1, child.InitialFeeId);
                Assert.False(child.IsDirectPayBool);
                Assert.True(child.IsRaiseCharge);
                Assert.True(child.IsEstimate);
                Assert.AreEqual(data.Charge2, child.InitialFee2Id);
                Assert.False(child.IsPayFee2);
                Assert.True(child.IsDirectPayBool2);

                Assert.AreEqual(data.Charge1, grandChild.InitialFeeId);
                Assert.False(grandChild.IsDirectPayBool);
                Assert.True(grandChild.IsRaiseCharge);
                Assert.True(grandChild.IsEstimate);
                Assert.AreEqual(data.Charge2, grandChild.InitialFee2Id);
                Assert.False(grandChild.IsPayFee2);
                Assert.True(grandChild.IsDirectPayBool2);
            }
        }
        
        [Test]
        public void BreakInheritance()
        {
            var data = DbSetup.Do(setup =>
            {

                var f = new EventControlDbSetup().SetupCriteriaInheritance();
                var otherEvent = setup.InsertWithNewId(new Event());

                setup.Insert(new DueDateCalc(f.ChildCriteriaId, f.EventId, 0) {Inherited = 1});
                setup.Insert(new RelatedEventRule(f.ChildCriteriaId, f.EventId, 0) {Inherited = 1});
                setup.Insert(new DatesLogic(f.ChildValidEvent, 0) {Inherited = 1});
                setup.Insert(new ReminderRule(f.ChildValidEvent, 0) {Inherited = 1});

                var nameType = setup.InsertWithNewId(new NameType());
                setup.Insert(new NameTypeMap(f.ChildValidEvent, nameType.NameTypeCode, nameType.NameTypeCode, 0) {Inherited = true});
                setup.Insert(new RequiredEventRule(f.ChildValidEvent, otherEvent) {Inherited = true});
                
                setup.Insert(new ValidEvent(f.CriteriaId, otherEvent.Id, "NotInherited") { NumberOfCyclesAllowed = 1, Inherited = 1 });
                setup.Insert(new DueDateCalc(f.CriteriaId, otherEvent.Id, 0) {Inherited = 1});

                return new
                {
                    f.CriteriaId,
                    f.EventId
                };
            });

            ApiClient.Put("configuration/rules/workflows/" + data.CriteriaId + "/eventcontrol/" + data.EventId + "/break", null);

            using (var dbContext = new SqlDbContext())
            {
                var result = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId == data.EventId);

                Assert.IsTrue(result.Inherited == 0, "Event Control is uninherited");
                Assert.IsTrue(result.ParentCriteriaNo == null, "Event Control is uninherited");
                Assert.IsTrue(result.ParentEventNo == null, "Event Control is uninherited");
                Assert.IsTrue(result.DueDateCalcs.All(_ => _.Inherited == 0), "All Due Date Calcs uninherited");
                Assert.IsTrue(result.RelatedEvents.All(_ => _.Inherited == 0), "All Related Events uninherited");
                Assert.IsTrue(result.DatesLogic.All(_ => _.Inherited == 0), "All Date Entry Rules uninherited");
                Assert.IsTrue(result.Reminders.All(_ => _.Inherited == 0), "All Reminders uninherited");
                Assert.IsTrue(result.NameTypeMaps.All(_ => !_.Inherited), "All Name Type Maps uninherited");
                Assert.IsTrue(result.RequiredEvents.All(_ => !_.Inherited), "All Required Events uninherited");

                var otherValidEvent = dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == data.CriteriaId && _.EventId != data.EventId);

                Assert.IsTrue(otherValidEvent.Inherited == 1, "Only specified event is uninherited");
                Assert.IsTrue(otherValidEvent.DueDateCalcs.All(_ => _.Inherited == 1), "Only specified events Due Date Calcs uninherited");
            }
        }
    }

    internal static class EventControlSaveModelExtension
    {
        internal static WorkflowEventControlSaveModel WithMandatoryFields(this WorkflowEventControlSaveModel saveModel)
        {
            saveModel.Description = "Apple";
            if (saveModel.NumberOfCyclesAllowed == null || saveModel.NumberOfCyclesAllowed < 1) saveModel.NumberOfCyclesAllowed = 1;
            saveModel.ApplyToDescendants = true;
            return saveModel;
        }
    }
}
