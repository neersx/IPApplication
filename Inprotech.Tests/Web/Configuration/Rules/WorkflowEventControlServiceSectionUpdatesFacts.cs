using System.Collections.Generic;
using System.Linq;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web.Configuration.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;

#pragma warning disable 618

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowEventControlServiceSectionUpdatesFacts
    {
        public class SetInheritedValuesForEventMethod : FactBase
        {
            [Theory]
            [InlineData(2, "B")]
            [InlineData(3, null)]
            [InlineData(null, "C")]
            public void UpdatesRespIfBothFieldsAreInherited(int? nameId, string nameCode)
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var @event = new ValidEventBuilder
                {
                    DueDateRespNameId = 1,
                    DueDateRespNameTypeCode = "A"
                }.Build();

                var newValues = new WorkflowEventControlSaveModel
                {
                    DueDateRespNameId = nameId,
                    DueDateRespNameTypeCode = nameCode
                };

                var shouldInherit = new EventControlFieldsToUpdate
                {
                    DueDateRespNameId = true,
                    DueDateRespNameTypeCode = true
                };

                f.Subject.SetUpdatedValuesForEvent(@event, newValues, shouldInherit);

                Assert.Equal(nameId, @event.DueDateRespNameId);
                Assert.Equal(nameCode, @event.DueDateRespNameTypeCode);
            }

            [Fact]
            public void DoesNotSetValueIfShouldInheritIsFalse()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var @event = new ValidEventBuilder
                {
                    Description = "description",
                    ImportanceLevel = "importance",
                    MaxCycles = 1,
                    Notes = "notes"
                }.Build();

                var newValues = new WorkflowEventControlSaveModel
                {
                    Description = "new description",
                    ImportanceLevel = "new importance",
                    NumberOfCyclesAllowed = 2,
                    Notes = "new notes"
                };

                var shouldInherit = new EventControlFieldsToUpdate
                {
                    Description = false,
                    ImportanceLevel = false,
                    Notes = false,
                    NumberOfCyclesAllowed = false
                };

                f.Subject.SetUpdatedValuesForEvent(@event, newValues, shouldInherit);

                Assert.Equal("description", @event.Description);
                Assert.Equal("importance", @event.ImportanceLevel);
                Assert.Equal(1, @event.NumberOfCyclesAllowed.GetValueOrDefault());
                Assert.Equal("notes", @event.Notes);
            }

            [Fact]
            public void DoesNotUpdateDueDateRespIfEitherFieldIsNotInherited()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var @event = new ValidEventBuilder
                {
                    DueDateRespNameId = 1,
                    DueDateRespNameTypeCode = "A"
                }.Build();

                var newValues = new WorkflowEventControlSaveModel
                {
                    DueDateRespNameId = 2,
                    DueDateRespNameTypeCode = "B"
                };

                var shouldInherit = new EventControlFieldsToUpdate
                {
                    DueDateRespNameId = true,
                    DueDateRespNameTypeCode = false
                };

                f.Subject.SetUpdatedValuesForEvent(@event, newValues, shouldInherit);

                Assert.Equal(1, @event.DueDateRespNameId);
                Assert.Equal("A", @event.DueDateRespNameTypeCode);
            }

            [Fact]
            public void DoesNotUpdatesDueDateCalcSettingsIfNotAllFieldsInherited()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var @event = new ValidEventBuilder
                {
                    SaveDueDate = 0,
                    DateToUse = "E",
                    RecalcDueDate = false,
                    ExtendPeriod = 3,
                    ExtendPeriodType = "M",
                    SuppressDueDateCalculation = true
                }.Build();

                var newValues = new WorkflowEventControlSaveModel
                {
                    SaveDueDate = 1,
                    DateToUse = "L",
                    RecalcEventDate = true,
                    ExtendPeriod = 1,
                    ExtendPeriodType = "Days",
                    SuppressDueDateCalculation = false
                };

                var shouldInherit = new EventControlFieldsToUpdate
                {
                    IsSaveDueDate = true,
                    DateToUse = false,
                    RecalcEventDate = true,
                    ExtendPeriod = false,
                    ExtendPeriodType = true,
                    SuppressDueDateCalculation = false
                };

                f.Subject.SetUpdatedValuesForEvent(@event, newValues, shouldInherit);

                Assert.Equal(0, @event.SaveDueDate.GetValueOrDefault());
                Assert.Equal("E", @event.DateToUse);
                Assert.Equal(false, @event.RecalcEventDate);
                Assert.Equal(3, @event.ExtendPeriod.GetValueOrDefault());
                Assert.Equal("M", @event.ExtendPeriodType);
                Assert.Equal(true, @event.SuppressDueDateCalculation);
            }

            [Fact]
            public void DoesNotUpdatesLoadEventIfNotAllFieldsInherited()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var @event = new ValidEventBuilder
                {
                    SyncedFromCase = 1,
                    UseReceivingCycle = true,
                    SyncedEventId = 123,
                    SyncedCaseRelationshipId = "A",
                    SyncedNumberTypeId = "B",
                    SyncedEventDateAdjustmentId = "C"
                }.Build();

                var newValues = new WorkflowEventControlSaveModel
                {
                    SyncedFromCase = 0,
                    UseReceivingCycle = false,
                    SyncedEventId = 456,
                    SyncedCaseRelationshipId = "D",
                    SyncedNumberTypeId = "E",
                    SyncedEventDateAdjustmentId = "F"
                };

                var shouldInherit = new EventControlFieldsToUpdate
                {
                    SyncedFromCase = true,
                    UseReceivingCycle = true,
                    SyncedEventId = false,
                    SyncedCaseRelationshipId = true,
                    SyncedNumberTypeId = true,
                    SyncedEventDateAdjustmentId = true
                };

                f.Subject.SetUpdatedValuesForEvent(@event, newValues, shouldInherit);

                Assert.Equal(1, @event.SyncedFromCase);
                Assert.Equal(true, @event.UseReceivingCycle);
                Assert.Equal(123, @event.SyncedEventId);
                Assert.Equal("A", @event.SyncedCaseRelationshipId);
                Assert.Equal("B", @event.SyncedNumberTypeId);
                Assert.Equal("C", @event.SyncedEventDateAdjustmentId);
            }

            [Fact]
            public void SetsValueIfShouldInheritIsTrue()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var @event = new ValidEventBuilder
                {
                    Description = "description",
                    ImportanceLevel = "importance",
                    MaxCycles = 1,
                    Notes = "notes"
                }.Build();

                var newValues = new WorkflowEventControlSaveModel
                {
                    Description = "new description",
                    ImportanceLevel = "new importance",
                    NumberOfCyclesAllowed = 2,
                    Notes = "new notes"
                };

                var shouldInherit = new EventControlFieldsToUpdate
                {
                    Description = true,
                    ImportanceLevel = true,
                    Notes = true,
                    NumberOfCyclesAllowed = true
                };

                f.Subject.SetUpdatedValuesForEvent(@event, newValues, shouldInherit);

                Assert.Equal("new description", @event.Description);
                Assert.Equal("new importance", @event.ImportanceLevel);
                Assert.Equal(2, @event.NumberOfCyclesAllowed.GetValueOrDefault());
                Assert.Equal("new notes", @event.Notes);
            }

            [Fact]
            public void UpdatesDueDateCalcSettingsIfAllFieldsInherited()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var @event = new ValidEventBuilder
                {
                    SaveDueDate = 0,
                    DateToUse = "E",
                    RecalcDueDate = false,
                    ExtendPeriod = 3,
                    ExtendPeriodType = "M",
                    SuppressDueDateCalculation = true
                }.Build();

                var newValues = new WorkflowEventControlSaveModel
                {
                    SaveDueDate = 3,
                    DateToUse = "L",
                    RecalcEventDate = true,
                    ExtendPeriod = 1,
                    ExtendPeriodType = "Days",
                    SuppressDueDateCalculation = false
                };

                var shouldInherit = new EventControlFieldsToUpdate
                {
                    IsSaveDueDate = true,
                    DateToUse = true,
                    RecalcEventDate = true,
                    ExtendPeriod = true,
                    ExtendPeriodType = true,
                    SuppressDueDateCalculation = true
                };

                f.Subject.SetUpdatedValuesForEvent(@event, newValues, shouldInherit);

                Assert.Equal(3, @event.SaveDueDate.GetValueOrDefault());
                Assert.Equal("L", @event.DateToUse);
                Assert.Equal(true, @event.RecalcEventDate);
                Assert.Equal(1, @event.ExtendPeriod.GetValueOrDefault());
                Assert.Equal("Days", @event.ExtendPeriodType);
                Assert.Equal(false, @event.SuppressDueDateCalculation);
            }

            [Fact]
            public void UpdatesLoadEventIfAllFieldsInherited()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var @event = new ValidEventBuilder
                {
                    SyncedFromCase = 1,
                    UseReceivingCycle = true,
                    SyncedEventId = 123,
                    SyncedCaseRelationshipId = "A",
                    SyncedNumberTypeId = "B",
                    SyncedEventDateAdjustmentId = "C"
                }.Build();

                var newValues = new WorkflowEventControlSaveModel
                {
                    SyncedFromCase = 0,
                    UseReceivingCycle = false,
                    SyncedEventId = 456,
                    SyncedCaseRelationshipId = "D",
                    SyncedNumberTypeId = "E",
                    SyncedEventDateAdjustmentId = "F"
                };

                var shouldInherit = new EventControlFieldsToUpdate
                {
                    SyncedFromCase = true,
                    UseReceivingCycle = true,
                    SyncedEventId = true,
                    SyncedCaseRelationshipId = true,
                    SyncedNumberTypeId = true,
                    SyncedEventDateAdjustmentId = true
                };

                f.Subject.SetUpdatedValuesForEvent(@event, newValues, shouldInherit);

                Assert.Equal(0, @event.SyncedFromCase);
                Assert.Equal(false, @event.UseReceivingCycle);
                Assert.Equal(456, @event.SyncedEventId);
                Assert.Equal("D", @event.SyncedCaseRelationshipId);
                Assert.Equal("E", @event.SyncedNumberTypeId);
                Assert.Equal("F", @event.SyncedEventDateAdjustmentId);
            }
        }

        public class GetDueDatesForEventControlMethod : FactBase
        {
            [Fact]
            public void DoesNotReturnCaseEventsWithOpenActionPoliceEventsFalse()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var @case = new CaseBuilder().Build().In(Db);
                var action = new ActionBuilder().Build().In(Db);

                var openActionBuilder = OpenActionBuilder.ForCaseAsValid(Db, @case, action, criteria);
                openActionBuilder.IsOpen = false;
                openActionBuilder.Build().In(Db);

                var @event = new EventBuilder {ControllingAction = action.Code}.Build().In(Db);
                new ValidEventBuilder().For(criteria, @event).Build().In(Db);

                new CaseEventBuilder().BuildForCase(@case).In(Db);
                new CaseEventBuilder {Event = @event}.BuildForCase(@case).In(Db);

                var r = f.Subject.GetDueDatesForEventControl(criteria.Id, @event.Id).ToArray();

                Assert.Empty(r);
            }

            [Fact]
            public void ReturnsCaseEventsCreatedByCriteria()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var @case = new CaseBuilder().Build().In(Db);
                var action = new ActionBuilder().Build().In(Db);

                var openActionBuilder = OpenActionBuilder.ForCaseAsValid(Db, @case, action, criteria);
                openActionBuilder.IsOpen = true;
                openActionBuilder.Build().In(Db);

                var @event = new EventBuilder {ControllingAction = null}.Build().In(Db);
                new ValidEventBuilder().For(criteria, @event).Build().In(Db);

                new CaseEventBuilder().BuildForCase(@case).In(Db); // decoy
                var caseEvent = new CaseEventBuilder {Event = @event, CreatedByCriteriaKey = criteria.Id}.BuildForCase(@case).In(Db);

                var r = f.Subject.GetDueDatesForEventControl(criteria.Id, @event.Id).ToArray();

                Assert.Single(r);
                Assert.Equal(caseEvent.CaseId, r[0].CaseId);
                Assert.Equal(caseEvent.EventNo, r[0].EventNo);
            }

            [Fact]
            public void ReturnsCaseEventsWithControllingAction()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var @case = new CaseBuilder().Build().In(Db);
                var action = new ActionBuilder().Build().In(Db);

                var openActionBuilder = OpenActionBuilder.ForCaseAsValid(Db, @case, action, criteria);
                openActionBuilder.IsOpen = true;
                openActionBuilder.Build().In(Db);

                var @event = new EventBuilder {ControllingAction = action.Code}.Build().In(Db);
                new ValidEventBuilder().For(criteria, @event).Build().In(Db);

                new CaseEventBuilder().BuildForCase(@case).In(Db); // decoy
                var caseEvent = new CaseEventBuilder {Event = @event}.BuildForCase(@case).In(Db);

                var r = f.Subject.GetDueDatesForEventControl(criteria.Id, @event.Id).ToArray();

                Assert.Single(r);
                Assert.Equal(caseEvent.CaseId, r[0].CaseId);
                Assert.Equal(caseEvent.EventNo, r[0].EventNo);
            }
        }

        public class UpdateDueDateResponsibilityMethod : FactBase
        {
            public UpdateDueDateResponsibilityMethod()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                _subject = Substitute.ForPartsOf<WorkflowEventControlService>(f.DbContext, f.PreferredCultureResolver, f.PermissionHelper, f.Inheritance, f.WorkflowEventInheritanceService, f.InprotechVersionChecker, f.Sections, f.TaskSecurity, f.CharacteristicsServiceIndex);
                _dueDates = new[] {new CaseEventBuilder().Build(), new CaseEventBuilder().Build()}.AsQueryable();
            }

            readonly IQueryable<CaseEvent> _dueDates;

            readonly WorkflowEventControlService _subject;

            [Fact]
            public void CallsClearResponsibility()
            {
                _subject.UpdateDueDatesResponsibilityOnCaseEvents(1, 2, new WorkflowEventControlSaveModel
                {
                    DueDateRespType = DueDateRespTypes.NotApplicable
                });

                _subject.Received(1).GetDueDatesForEventControl(1, 2);
                _subject.Received(1).ClearResponsibility(_dueDates);
            }

            [Fact]
            public void CallsUpdateNameResponsibility()
            {
                _subject.UpdateDueDatesResponsibilityOnCaseEvents(1, 2, new WorkflowEventControlSaveModel
                {
                    DueDateRespType = DueDateRespTypes.Name,
                    DueDateRespNameId = 3
                });

                _subject.Received(1).GetDueDatesForEventControl(1, 2);
                _subject.Received(1).UpdateNameResponsibility(3, _dueDates);
            }

            [Fact]
            public void CallsUpdateNameTypeResponsibility()
            {
                _subject.UpdateDueDatesResponsibilityOnCaseEvents(1, 2, new WorkflowEventControlSaveModel
                {
                    DueDateRespType = DueDateRespTypes.NameType,
                    DueDateRespNameTypeCode = "E"
                });

                _subject.Received(1).GetDueDatesForEventControl(1, 2);
                _subject.Received(1).UpdateNameTypeResponsibility("E", _dueDates);
            }
        }

        public class UpdateNameResponsibilityMethod : FactBase
        {
            [Fact]
            public void DoesNotUpdateOccurredCaseEvents()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var occurredEvent = new CaseEventBuilder {DueDateResponsibilityNameType = "A", EmployeeNo = 1, IsOccurredFlag = 1}.Build();

                f.Subject.UpdateNameResponsibility(22, new[] {occurredEvent}.AsQueryable());

                Assert.Equal(1, occurredEvent.EmployeeNo);
                Assert.Equal("A", occurredEvent.DueDateResponsibilityNameType);
            }

            [Fact]
            public void UpdatesResponsibilityToNameOnCaseEvents()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var dueDate1 = new CaseEventBuilder {DueDateResponsibilityNameType = Fixture.String(), EmployeeNo = Fixture.Integer()}.Build();
                var dueDate2 = new CaseEventBuilder {DueDateResponsibilityNameType = Fixture.String(), EmployeeNo = Fixture.Integer()}.Build();

                f.Subject.UpdateNameResponsibility(22, new[] {dueDate1, dueDate2}.AsQueryable());

                Assert.Equal(22, dueDate1.EmployeeNo);
                Assert.Null(dueDate1.DueDateResponsibilityNameType);
                Assert.Equal(22, dueDate2.EmployeeNo);
                Assert.Null(dueDate2.DueDateResponsibilityNameType);
            }
        }

        public class UpdateNameTypeResponsibilityMethod : FactBase
        {
            [Fact]
            public void HandlesMultipleCasesWithDifferentCaseNamesForCaseEvents()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var case1 = new CaseBuilder().Build().In(Db);
                var case2 = new CaseBuilder().Build().In(Db);
                var dueDate1 = new CaseEventBuilder {DueDateResponsibilityNameType = Fixture.String(), EmployeeNo = Fixture.Integer()}.BuildForCase(case1);
                var dueDate2 = new CaseEventBuilder {DueDateResponsibilityNameType = Fixture.String(), EmployeeNo = Fixture.Integer()}.BuildForCase(case2);

                var nameType = new NameTypeBuilder {NameTypeCode = "emp"}.Build().In(Db);
                var name1 = new Name(1);
                var name2 = new Name(2);
                new CaseNameBuilder(Db) {NameType = nameType, Name = name1}.BuildWithCase(case1, 0).In(Db);
                new CaseNameBuilder(Db) {NameType = nameType, Name = name2}.BuildWithCase(case2, 0).In(Db);

                f.Subject.UpdateNameTypeResponsibility("emp", new[] {dueDate1, dueDate2}.AsQueryable());

                Assert.Equal(name1.Id, dueDate1.EmployeeNo);
                Assert.Null(dueDate1.DueDateResponsibilityNameType);
                Assert.Equal(name2.Id, dueDate2.EmployeeNo);
                Assert.Null(dueDate2.DueDateResponsibilityNameType);
            }

            [Fact]
            public void UpdatesResponsibilityToLowestSequenceCaseNameForNameTypeOnCaseEvents()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var @case = new CaseBuilder().Build().In(Db);
                var dueDate1 = new CaseEventBuilder {DueDateResponsibilityNameType = Fixture.String(), EmployeeNo = Fixture.Integer()}.BuildForCase(@case);
                var dueDate2 = new CaseEventBuilder {DueDateResponsibilityNameType = Fixture.String(), EmployeeNo = Fixture.Integer()}.BuildForCase(@case);

                var nameType = new NameTypeBuilder {NameTypeCode = "emp"}.Build().In(Db);
                var name = new Name(1);
                new CaseNameBuilder(Db) {Sequence = 3, Name = new Name(3)}.BuildWithCase(@case, 0).In(Db); // decoy different name type
                new CaseNameBuilder(Db) {NameType = nameType, Sequence = 2, Name = new Name(2)}.BuildWithCase(@case, 0).In(Db); // decoy higher sequence
                new CaseNameBuilder(Db) {NameType = nameType, Name = name, Sequence = 1}.BuildWithCase(@case, 0).In(Db); // target
                new CaseNameBuilder(Db) {NameType = nameType, Sequence = 0, ExpiryDate = Fixture.PastDate(), Name = new Name(0)}.BuildWithCase(@case, 0).In(Db); // decoy expired

                f.Subject.UpdateNameTypeResponsibility("emp", new[] {dueDate1, dueDate2}.AsQueryable());

                Assert.Equal(name.Id, dueDate1.EmployeeNo);
                Assert.Null(dueDate1.DueDateResponsibilityNameType);
                Assert.Equal(name.Id, dueDate2.EmployeeNo);
                Assert.Null(dueDate2.DueDateResponsibilityNameType);
            }

            [Fact]
            public void UpdatesResponsibilityToNameTypeOnCaseEventsWhenCaseNameNull()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var dueDate1 = new CaseEventBuilder {DueDateResponsibilityNameType = Fixture.String(), EmployeeNo = Fixture.Integer()}.Build();
                var dueDate2 = new CaseEventBuilder {DueDateResponsibilityNameType = Fixture.String(), EmployeeNo = Fixture.Integer()}.Build();

                f.Subject.UpdateNameTypeResponsibility("emp", new[] {dueDate1, dueDate2}.AsQueryable());

                Assert.Null(dueDate1.EmployeeNo);
                Assert.Equal("emp", dueDate1.DueDateResponsibilityNameType);
                Assert.Null(dueDate2.EmployeeNo);
                Assert.Equal("emp", dueDate2.DueDateResponsibilityNameType);
            }
        }

        public class ClearResponsibilityMethod : FactBase
        {
            [Fact]
            public void ClearsResponsibilityOnCaseEvents()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var dueDate1 = new CaseEventBuilder {DueDateResponsibilityNameType = Fixture.String(), EmployeeNo = Fixture.Integer()}.Build();
                var dueDate2 = new CaseEventBuilder {DueDateResponsibilityNameType = Fixture.String(), EmployeeNo = Fixture.Integer()}.Build();

                f.Subject.ClearResponsibility(new[] {dueDate1, dueDate2}.AsQueryable());

                Assert.Null(dueDate1.EmployeeNo);
                Assert.Null(dueDate1.DueDateResponsibilityNameType);
                Assert.Null(dueDate2.EmployeeNo);
                Assert.Null(dueDate2.DueDateResponsibilityNameType);
            }
        }

        public class ValidateSaveModelMethod : FactBase
        {
            Criteria _criteria;
            WorkflowEventControlServiceFixture _f;
            WorkflowEventControlSaveModel _saveModel;
            Status _status;

            void PrepareData(bool isRenewal, Country country = null)
            {
                _f = new WorkflowEventControlServiceFixture(Db);
                _status = new StatusBuilder {IsRenewalStatus = isRenewal}.Build().In(Db);
                _criteria = new CriteriaBuilder().WithCaseType().WithCountry().WithPropertyType().Build().In(Db);

                var dummyStatus = new StatusBuilder {IsRenewalStatus = isRenewal}.Build().In(Db);
                new ValidStatusBuilder {CaseType = _criteria.CaseType, Country = country ?? _criteria.Country, PropertyType = _criteria.PropertyType, Status = dummyStatus}.Build().In(Db);

                _saveModel = new WorkflowEventControlSaveModel
                {
                    OriginatingCriteriaId = _criteria.Id,
                    ChangeStatusId = !isRenewal ? (short?) _status.Id : null,
                    ChangeRenewalStatusId = isRenewal ? (short?) _status.Id : null
                };
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ValidatesValidStatus(bool isRenewal)
            {
                PrepareData(isRenewal);
                var result = _f.Subject.ValidateSaveModel(_saveModel).ToArray();
                Assert.NotEmpty(result);
                Assert.True(result.All(_ => _.Topic == "changeStatus"));

                new ValidStatusBuilder {CaseType = _criteria.CaseType, Country = _criteria.Country, PropertyType = _criteria.PropertyType, Status = _status}.Build().In(Db);
                result = _f.Subject.ValidateSaveModel(_saveModel).ToArray();
                Assert.Empty(result);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void FallsBackToZzzValidStatus(bool isRenewal)
            {
                var country = new CountryBuilder {Id = "ZZZ"}.Build();
                PrepareData(isRenewal, country);

                var result = _f.Subject.ValidateSaveModel(_saveModel).ToArray();
                Assert.NotEmpty(result);
                Assert.True(result.All(_ => _.Topic == "changeStatus"));

                new ValidStatusBuilder {CaseType = _criteria.CaseType, Country = new CountryBuilder {Id = "ZZZ"}.Build(), PropertyType = _criteria.PropertyType, Status = _status}.Build().In(Db);
                result = _f.Subject.ValidateSaveModel(_saveModel).ToArray();
                Assert.Empty(result);
            }

            [Fact]
            public void ValidatesCaseStatus()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var status = new StatusBuilder().Build().In(Db);
                var renewalStatus = new StatusBuilder().ForRenewal().Build().In(Db);
                var criteria = new CriteriaBuilder().WithPropertyType().WithCaseType().Build().In(Db);

                var saveModel = new WorkflowEventControlSaveModel
                {
                    OriginatingCriteriaId = criteria.Id,
                    ChangeStatusId = status.Id,
                    ChangeRenewalStatusId = renewalStatus.Id
                };

                var exception = Record.Exception(() => f.Subject.ValidateSaveModel(saveModel));
                Assert.Null(exception);

                saveModel.ChangeStatusId = renewalStatus.Id;
                var result = f.Subject.ValidateSaveModel(saveModel).ToArray();
                Assert.NotEmpty(result);
                Assert.True(result.All(_ => _.Topic == "changeStatus"));
            }

            [Fact]
            public void ValidatesRenewalStatus()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var status = new StatusBuilder().Build().In(Db);
                var renewalStatus = new StatusBuilder().ForRenewal().Build().In(Db);
                var criteria = new CriteriaBuilder().WithPropertyType().WithCaseType().Build().In(Db);

                var saveModel = new WorkflowEventControlSaveModel
                {
                    OriginatingCriteriaId = criteria.Id,
                    ChangeRenewalStatusId = renewalStatus.Id
                };
                var result = f.Subject.ValidateSaveModel(saveModel).ToArray();

                Assert.Empty(result);

                saveModel.ChangeRenewalStatusId = status.Id;
                result = f.Subject.ValidateSaveModel(saveModel).ToArray();
                Assert.NotEmpty(result);
                Assert.True(result.All(_ => _.Topic == "changeStatus"));
            }
        }

        public class SetOriginalHashesMethod : FactBase
        {
            [Fact]
            public void StoresOriginalEventIdsForSatisfyingEvents()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var eventControl = new ValidEventBuilder().Build().In(Db);

                var satisfyingEventToUpdate = new RelatedEventRuleBuilder().AsSatisfyingEvent().For(eventControl).Build();
                satisfyingEventToUpdate.Sequence = 0;
                satisfyingEventToUpdate.RelativeCycleId = 1;
                eventControl.RelatedEvents.Add(satisfyingEventToUpdate);
                var satisfyingEventToDelete = new RelatedEventRuleBuilder().AsSatisfyingEvent().For(eventControl).Build();
                satisfyingEventToDelete.Sequence = 1;
                satisfyingEventToDelete.RelativeCycleId = 1;
                eventControl.RelatedEvents.Add(satisfyingEventToDelete);

                var updatedSatisfyingEvent = new SatisfyingEventSaveModelBuilder().For(eventControl).Build();
                updatedSatisfyingEvent.Sequence = satisfyingEventToUpdate.Sequence;
                var deletedSatisfyingEvent = new SatisfyingEventSaveModelBuilder().For(eventControl).Build();
                deletedSatisfyingEvent.Sequence = satisfyingEventToDelete.Sequence;

                var formData = new WorkflowEventControlSaveModel
                {
                    Description = Fixture.String(),
                    ImportanceLevel = Fixture.String(),
                    NumberOfCyclesAllowed = Fixture.Short(),
                    SatisfyingEventsDelta = new Delta<RelatedEventRuleSaveModel> {Updated = new[] {updatedSatisfyingEvent}, Deleted = new[] {deletedSatisfyingEvent}}
                };

                f.Subject.SetOriginalHashes(eventControl, formData);

                Assert.Equal(satisfyingEventToUpdate.HashKey(), formData.SatisfyingEventsDelta.Updated.Single().OriginalHashKey);
                Assert.Equal(satisfyingEventToDelete.HashKey(), formData.SatisfyingEventsDelta.Deleted.Single().OriginalHashKey);
            }

            [Fact]
            public void StoresOriginalHashesForDateComparisons()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var eventControl = new ValidEventBuilder().Build().In(Db);

                var dateComparisonToUpdate = new DueDateCalcBuilder().For(eventControl).Build();
                dateComparisonToUpdate.Comparison = ">";
                dateComparisonToUpdate.Sequence = 0;
                eventControl.DueDateCalcs.Add(dateComparisonToUpdate);
                var dateComparisonToDelete = new DueDateCalcBuilder().For(eventControl).Build();
                dateComparisonToDelete.Comparison = "<";
                dateComparisonToDelete.Sequence = 1;
                eventControl.DueDateCalcs.Add(dateComparisonToDelete);

                var updatedDateComparison = new DateComparisonSaveModelBuilder().For(eventControl).Build();
                updatedDateComparison.CompareSystemDate = true; // make it valid
                updatedDateComparison.Sequence = dateComparisonToUpdate.Sequence;
                var deletedDateComparision = new DateComparisonSaveModelBuilder().For(eventControl).Build();
                deletedDateComparision.Sequence = dateComparisonToDelete.Sequence;

                var formData = new WorkflowEventControlSaveModel
                {
                    Description = Fixture.String(),
                    ImportanceLevel = Fixture.String(),
                    NumberOfCyclesAllowed = Fixture.Short(),
                    DateComparisonDelta = new Delta<DateComparisonSaveModel> {Updated = new[] {updatedDateComparison}, Deleted = new[] {deletedDateComparision}}
                };

                f.Subject.SetOriginalHashes(eventControl, formData);

                Assert.Equal(dateComparisonToUpdate.HashKey(), formData.DateComparisonDelta.Updated.Single().OriginalHashKey);
                Assert.Equal(dateComparisonToDelete.HashKey(), formData.DateComparisonDelta.Deleted.Single().OriginalHashKey);
            }

            [Fact]
            public void StoresOriginalHashesForDatesLogic()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var eventControl = new ValidEventBuilder().Build().In(Db);

                var datesLogicToUpdate = new DatesLogicBuilder().For(eventControl).Build();
                var datesLogicToDelete = new DatesLogicBuilder().For(eventControl).Build();
                datesLogicToUpdate.Sequence = 0;
                datesLogicToDelete.Sequence = 1;
                eventControl.DatesLogic.Add(datesLogicToUpdate);
                eventControl.DatesLogic.Add(datesLogicToDelete);

                var updateDatesLogic = new DatesLogicSaveModel();
                updateDatesLogic.CopyFrom(datesLogicToUpdate, false);
                updateDatesLogic.CriteriaId = datesLogicToUpdate.CriteriaId;
                updateDatesLogic.EventId = datesLogicToUpdate.EventId;
                updateDatesLogic.Sequence = datesLogicToUpdate.Sequence;
                // simluating changing hash data
                updateDatesLogic.ErrorMessage = Fixture.String();

                var deleteDatesLogic = new DatesLogicSaveModel
                {
                    CriteriaId = datesLogicToDelete.CriteriaId,
                    EventId = datesLogicToDelete.EventId,
                    Sequence = datesLogicToDelete.Sequence
                };

                var formData = new WorkflowEventControlSaveModel
                {
                    Description = Fixture.String(),
                    ImportanceLevel = Fixture.String(),
                    NumberOfCyclesAllowed = Fixture.Short(),
                    DatesLogicDelta = new Delta<DatesLogicSaveModel> {Updated = new[] {updateDatesLogic}, Deleted = new[] {deleteDatesLogic}}
                };

                f.Subject.SetOriginalHashes(eventControl, formData);

                Assert.Equal(datesLogicToUpdate.HashKey(), formData.DatesLogicDelta.Updated.Single().OriginalHashKey);
                Assert.Equal(datesLogicToDelete.HashKey(), formData.DatesLogicDelta.Deleted.Single().OriginalHashKey);
            }

            [Fact]
            public void StoresOriginalHashesForDueDates()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var eventControl = new ValidEventBuilder().Build().In(Db);

                var dueDateCalcToUpdate = new DueDateCalcBuilder().For(eventControl).Build();
                dueDateCalcToUpdate.Sequence = 0;
                eventControl.DueDateCalcs.Add(dueDateCalcToUpdate);
                var dueDateCalcToDelete = new DueDateCalcBuilder().For(eventControl).Build();
                dueDateCalcToDelete.Sequence = 1;
                eventControl.DueDateCalcs.Add(dueDateCalcToDelete);

                var updateDueDateCalc = new DueDateCalcSaveModelBuilder().For(eventControl).Build();
                updateDueDateCalc.Sequence = dueDateCalcToUpdate.Sequence;
                // simluating changing hash data
                updateDueDateCalc.Cycle = (short) (dueDateCalcToUpdate.Cycle.GetValueOrDefault() + 1);
                updateDueDateCalc.JurisdictionId = Fixture.String();
                var deletedDueDateCalc = new DueDateCalcSaveModelBuilder().For(eventControl).Build();
                deletedDueDateCalc.Sequence = dueDateCalcToDelete.Sequence;

                var formData = new WorkflowEventControlSaveModel
                {
                    Description = Fixture.String(),
                    ImportanceLevel = Fixture.String(),
                    NumberOfCyclesAllowed = Fixture.Short(),
                    DueDateCalcDelta = new Delta<DueDateCalcSaveModel> {Updated = new[] {updateDueDateCalc}, Deleted = new[] {deletedDueDateCalc}}
                };

                f.Subject.SetOriginalHashes(eventControl, formData);

                Assert.Equal(dueDateCalcToUpdate.HashKey(), formData.DueDateCalcDelta.Updated.Single().OriginalHashKey);
                Assert.Equal(dueDateCalcToDelete.HashKey(), formData.DueDateCalcDelta.Deleted.Single().OriginalHashKey);
            }

            [Fact]
            public void StoresOriginalHashesForReminderRules()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var eventControl = new ValidEventBuilder().Build().In(Db);

                var reminderRuleToUpdate = new ReminderRuleBuilder().For(eventControl).Build();
                var reminderRuleToDelete = new ReminderRuleBuilder().For(eventControl).Build();
                reminderRuleToUpdate.Sequence = 0;
                reminderRuleToDelete.Sequence = 1;
                eventControl.Reminders.Add(reminderRuleToUpdate);
                eventControl.Reminders.Add(reminderRuleToDelete);

                var updateReminder = new ReminderRuleSaveModelBuilder().For(eventControl).Build();
                DataFiller.Fill(updateReminder);
                updateReminder.Sequence = reminderRuleToUpdate.Sequence;
                // simluating changing hash data
                updateReminder.LeadTime = (short) (reminderRuleToUpdate.LeadTime.GetValueOrDefault() + 1);
                updateReminder.Message1 = Fixture.String();
                var deleteReminder = new ReminderRuleSaveModelBuilder().For(eventControl).Build();
                deleteReminder.Sequence = reminderRuleToDelete.Sequence;
                deleteReminder.Message1 = Fixture.String();
                var formData = new WorkflowEventControlSaveModel
                {
                    Description = Fixture.String(),
                    ImportanceLevel = Fixture.String(),
                    NumberOfCyclesAllowed = Fixture.Short(),
                    ReminderRuleDelta = new Delta<ReminderRuleSaveModel> {Updated = new[] {updateReminder}, Deleted = new[] {deleteReminder}}
                };

                f.Subject.SetOriginalHashes(eventControl, formData);

                Assert.Equal(reminderRuleToUpdate.HashKey(), formData.ReminderRuleDelta.Updated.Single().OriginalHashKey);
                Assert.Equal(reminderRuleToDelete.HashKey(), formData.ReminderRuleDelta.Deleted.Single().OriginalHashKey);
            }
        }
    }

    public class WorkflowEventControlServiceFixture : IFixture<WorkflowEventControlService>
    {
        public WorkflowEventControlServiceFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            PermissionHelper = Substitute.For<IWorkflowPermissionHelper>();
            Inheritance = Substitute.For<IInheritance>();
            WorkflowEventInheritanceService = Substitute.For<IWorkflowEventInheritanceService>();
            InprotechVersionChecker = Substitute.For<IInprotechVersionChecker>();
            InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(true);
            DbContext = db;
            TaskSecurity = Substitute.For<ITaskSecurityProvider>();
            CharacteristicsService = Substitute.For<ICharacteristicsService>();
            
            CharacteristicsServiceIndex = Substitute.For<IIndex<string, ICharacteristicsService>>();
            CharacteristicsServiceIndex[CriteriaPurposeCodes.EventsAndEntries].Returns(CharacteristicsService);
            Sections = new List<IEventSectionMaintenance> {Substitute.For<IEventSectionMaintenance>(), Substitute.For<IEventSectionMaintenance>()};

            Subject = Substitute.ForPartsOf<WorkflowEventControlService>(DbContext, PreferredCultureResolver, PermissionHelper, Inheritance, WorkflowEventInheritanceService, InprotechVersionChecker, Sections, TaskSecurity, CharacteristicsServiceIndex);
        }

        public IWorkflowEventInheritanceService WorkflowEventInheritanceService { get; }

        public IPreferredCultureResolver PreferredCultureResolver { get; }

        public IWorkflowPermissionHelper PermissionHelper { get; }

        public IInheritance Inheritance { get; }

        public IInprotechVersionChecker InprotechVersionChecker { get; }

        public List<IEventSectionMaintenance> Sections { get; }

        public IDbContext DbContext { get; }

        public ITaskSecurityProvider TaskSecurity { get; }

        public ICharacteristicsService CharacteristicsService { get; }

        public IIndex<string, ICharacteristicsService> CharacteristicsServiceIndex;

        public WorkflowEventControlService Subject { get; }
    }
}