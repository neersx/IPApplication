using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Documents;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Configuration.Rules.Workflow;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;
using Event = InprotechKaizen.Model.Cases.Events.Event;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowEventControlControllerFacts
    {
        public class UpdateEventControlMethod : FactBase
        {
            [Theory]
            [InlineData("", 1, "abc")]
            [InlineData("abc", null, "def")]
            [InlineData("abc", 0, "def")]
            [InlineData("abc", 1, "")]
            public void ValidatesMandatoryFields(string description, int? maxCycles, string importanceLevel)
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var formData = new WorkflowEventControlSaveModel
                {
                    Description = description,
                    NumberOfCyclesAllowed = (short?) maxCycles,
                    ImportanceLevel = importanceLevel
                };

                Assert.Throws<ArgumentNullException>(() => f.Subject.UpdateEventControl(123, -11, formData));
            }

            [Theory]
            [InlineData(DueDateRespTypes.Name, 5, null)]
            [InlineData(DueDateRespTypes.NameType, null, "emp")]
            [InlineData(DueDateRespTypes.NotApplicable, null, null)]
            public void UpdatesFormDataToToggleResponsibilityNameOrNameType(DueDateRespTypes respType, int? newName, string newNameType)
            {
                var f = new WorkFlowEventControlControllerFixture(Db);

                var eventControl = new ValidEventBuilder
                    {
                        DueDateRespNameId = 0,
                        DueDateRespNameTypeCode = "old"
                    }.Build()
                     .In(Db);

                var saveModel = new WorkflowEventControlSaveModel
                {
                    Description = Fixture.String(),
                    ImportanceLevel = Fixture.String(),
                    NumberOfCyclesAllowed = Fixture.Short(),
                    DueDateRespType = respType,
                    DueDateRespNameId = newName ?? Fixture.Short(),
                    DueDateRespNameTypeCode = newNameType ?? Fixture.String(),
                    ApplyToDescendants = true
                };

                f.Subject.UpdateEventControl(eventControl.CriteriaId, eventControl.EventId, saveModel);

                f.WorkflowEventControlService.Received(1).UpdateEventControl(eventControl, Arg.Any<WorkflowEventControlSaveModel>(), Arg.Any<EventControlFieldsToUpdate>());
            }

            [Fact]
            public void ChecksTaskSecurity()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var validEvent = new ValidEventBuilder().Build().In(Db);
                f.Subject.UpdateEventControl(validEvent.CriteriaId, validEvent.EventId, new WorkflowEventControlSaveModel
                {
                    Description = "abc",
                    ImportanceLevel = "def",
                    NumberOfCyclesAllowed = 1
                });

                f.WorkflowPermissionHelper.Received(1).EnsureEditEventControlPermission(validEvent.CriteriaId, validEvent.EventId);
            }

            [Fact]
            public void SavesChangesToEventControl()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);

                var eventControl = new ValidEventBuilder().Build().In(Db);

                var saveModel = new WorkflowEventControlSaveModel
                {
                    Description = "new description",
                    ImportanceLevel = "new importance",
                    NumberOfCyclesAllowed = 2
                };

                f.Subject.UpdateEventControl(eventControl.CriteriaId, eventControl.EventId, saveModel);
                f.WorkflowEventControlService.Received(1).NormaliseSaveModel(saveModel);
                f.WorkflowEventControlService.Received(1).ValidateSaveModel(saveModel);
                f.WorkflowEventControlService.Received(1).SetOriginalHashes(eventControl, saveModel);
                f.WorkflowEventControlService.Received(1).UpdateEventControl(eventControl, saveModel);
                f.DbContext.Received(1).SaveChanges();
            }
        }

        public class ResetEventControl : FactBase
        {
            [Fact]
            public void EnsuresCorrectPermissionsAndResetsEventControl()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var criteriaId = Fixture.Integer();
                var eventId = Fixture.Integer();
                var applyToDescendants = Fixture.Boolean();
                f.Subject.ResetEventControl(criteriaId, eventId, applyToDescendants);
                f.WorkflowPermissionHelper.Received(1).EnsureEditEventControlPermission(criteriaId, eventId);
                f.WorkflowEventControlService.Received(1).ResetEventControl(criteriaId, eventId, applyToDescendants);
            }
        }

        public class BreakEventInheritance : FactBase
        {
            [Fact]
            public void EnsuresCorrectPermissionsAndBreaksInheritance()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var criteriaId = Fixture.Integer();
                var eventId = Fixture.Integer();
                f.Subject.BreakEventControl(criteriaId, eventId);
                f.WorkflowPermissionHelper.Received(1).EnsureEditEventControlPermission(criteriaId, eventId);
                f.WorkflowEventInheritanceService.Received(1).BreakEventsInheritance(criteriaId, eventId);
            }
        }

        public class GetDueDateCalcData : FactBase
        {
            [Fact]
            public void ReturnsGetDueDateCalcGridData()
            {
                var eventId = 1;
                var c = new Criteria {UserDefinedRule = 0}.In(Db);
                var e = new ValidEvent(c.Id, eventId, "b") {Description = "Description of ValidEvent"}.In(Db);
                var fromEventId = 2;
                var fromEvent = new Event(fromEventId) {Description = "Description of fromEvent"}.In(Db);
                var jurisdiction = new CountryBuilder().Build();
                var overrideLetter = new DocumentBuilder().Build();
                new DueDateCalc(e, 0)
                {
                    Inherited = 1,
                    Cycle = 1,
                    Jurisdiction = jurisdiction,
                    JurisdictionId = jurisdiction.Id,
                    EventId = eventId,
                    Operator = "operator",
                    PeriodType = "M",
                    DeadlinePeriod = 12,
                    RelativeCycle = 1,
                    ValidEvent = e,
                    FromEvent = fromEvent,
                    MustExist = 0,
                    EventDateFlag = 1,
                    Adjustment = "A",
                    Message2Flag = 1,
                    Workday = 2,
                    OverrideLetter = overrideLetter
                }.In(Db);

                var f = new WorkFlowEventControlControllerFixture(Db);
                var r = f.Subject.GetDueDateCalcData(c.Id, e.EventId).ToArray();

                var returnItem = r.Single();
                Assert.Single(r);
                Assert.True(returnItem.Inherited);
                Assert.Equal(1, returnItem.Cycle);
                Assert.Equal(jurisdiction.Name, returnItem.Jurisdiction.Value);
                Assert.Equal(fromEventId, returnItem.FromEvent.Key);
                Assert.Equal("Description of fromEvent", returnItem.FromEvent.Value);
                Assert.Equal("operator", returnItem.Operator);
                Assert.Equal("M", returnItem.Period.Type);
                Assert.Equal(12, returnItem.Period.Value);
                Assert.Equal(1, returnItem.FromTo);
                Assert.Equal(1, returnItem.RelativeCycle);
                Assert.False(returnItem.MustExist);
                Assert.Equal("A", returnItem.AdjustBy);
                Assert.Equal(ReminderOptions.Alternate, returnItem.ReminderOption);
                Assert.Equal(2, returnItem.NonWorkDay);
                Assert.Equal(overrideLetter.Id, returnItem.Document.Key);
                Assert.Equal(overrideLetter.Name, returnItem.Document.Value);
            }

            [Fact]
            public void ReturnsGetDueDateCalcGridDataByCycle()
            {
                var c = new Criteria {UserDefinedRule = 0}.In(Db);
                var e = new ValidEvent(c.Id, 1, "b") {Description = "A"}.In(Db);
                var fromEvent = new Event(e.EventId).In(Db);
                new DueDateCalc(e, 0)
                {
                    Cycle = 2,
                    ValidEvent = e,
                    FromEvent = fromEvent
                }.In(Db);
                new DueDateCalc(e, 1)
                {
                    Cycle = 1,
                    ValidEvent = e,
                    FromEvent = fromEvent
                }.In(Db);

                var f = new WorkFlowEventControlControllerFixture(Db);
                var r = f.Subject.GetDueDateCalcData(c.Id, e.EventId).ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal(1, r.First().Cycle);
                Assert.Equal(2, r.Last().Cycle);
            }

            [Fact]
            public void ReturnsGetDueDateCalcGridDataByEvent()
            {
                var c = new Criteria {UserDefinedRule = 0}.In(Db);
                var e = new ValidEvent(c.Id, 1, "b") {Description = "A"}.In(Db);
                new Event(e.EventId).In(Db);
                new DueDateCalc(e, 0)
                {
                    FromEvent = new Event(e.EventId) {Description = "BB"}.In(Db)
                }.In(Db);
                new DueDateCalc(e, 1)
                {
                    FromEvent = new Event(e.EventId) {Description = "AA"}.In(Db)
                }.In(Db);

                var f = new WorkFlowEventControlControllerFixture(Db);
                var r = f.Subject.GetDueDateCalcData(c.Id, e.EventId).ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal("AA", r.First().FromEvent.Value);
                Assert.Equal("BB", r.Last().FromEvent.Value);
            }

            [Fact]
            public void ReturnsGetDueDateCalcGridDataOrderedByJurisdiction()
            {
                var c = new Criteria {UserDefinedRule = 0}.In(Db);
                var e = new ValidEvent(c.Id, 1, "b") {Description = "A"}.In(Db);
                var fromEvent = new Event(e.EventId).In(Db);
                var jurisdictionA = new CountryBuilder {Name = "AA"}.Build();
                var jurisdictionB = new CountryBuilder {Name = "BB"}.Build();

                new DueDateCalc(e, 0)
                {
                    Jurisdiction = jurisdictionA,
                    JurisdictionId = jurisdictionA.Id,
                    ValidEvent = e,
                    FromEvent = fromEvent
                }.In(Db);
                new DueDateCalc(e, 1)
                {
                    Jurisdiction = jurisdictionB,
                    JurisdictionId = jurisdictionB.Id,
                    ValidEvent = e,
                    FromEvent = fromEvent
                }.In(Db);

                var f = new WorkFlowEventControlControllerFixture(Db);
                var r = f.Subject.GetDueDateCalcData(c.Id, e.EventId).ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal(jurisdictionA.Name, r.First().Jurisdiction.Value);
                Assert.Equal(jurisdictionB.Name, r.Last().Jurisdiction.Value);
            }
        }

        public class GetNameTypeMapsMethod : FactBase
        {
            [Fact]
            public void ReturnsNameTypeMaps()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var c = new CriteriaBuilder().Build().In(Db);
                var e = new ValidEvent(c.Id, Fixture.Integer()).In(Db);

                var ntm1 = new NameTypeMapBuilder {Inherited = true}.For(e).Build().In(Db);
                var ntm2 = new NameTypeMapBuilder {Inherited = false}.For(e).Build().In(Db);

                // decoys
                new NameTypeMapBuilder().Build().In(Db);
                new NameTypeMapBuilder().Build().In(Db);

                var r = f.Subject.GetNameTypeMaps(c.Id, e.EventId).ToArray();

                Assert.Equal(2, r.Length);

                var r1 = r.Single(_ => _.Sequence == ntm1.Sequence);
                var r2 = r.Single(_ => _.Sequence == ntm2.Sequence);

                Assert.Equal(ntm1.ApplicableNameTypeKey, r1.NameType.Key);
                Assert.Equal(ntm1.SubstituteNameTypeKey, r1.CaseNameType.Key);
                Assert.True(r1.IsInherited);
                Assert.Equal(ntm1.Sequence, r1.Sequence);
                Assert.Equal(ntm1.MustExist, r1.MustExist);

                Assert.Equal(ntm2.ApplicableNameTypeKey, r2.NameType.Key);
                Assert.Equal(ntm2.SubstituteNameTypeKey, r2.CaseNameType.Key);
                Assert.False(r2.IsInherited);
                Assert.Equal(ntm2.Sequence, r2.Sequence);
                Assert.Equal(ntm2.MustExist, r2.MustExist);
            }
        }

        public class GetDateComparisonMethod : FactBase
        {
            [Fact]
            public void ReturnsDateComparisonsForCriteriaAndEvent()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var c = new CriteriaBuilder().Build().In(Db);
                var e = new ValidEvent(c.Id, Fixture.Integer()).In(Db);

                var fe1 = new Event(Fixture.Integer());
                var ce1 = new Event(Fixture.Integer());

                var fe2 = new Event(Fixture.Integer());
                var ce2 = new Event(Fixture.Integer());

                var dateComparison = new DueDateCalc(e, 1) {FromEventId = fe1.Id, FromEvent = fe1, CompareEventId = ce1.Id, CompareEvent = ce1, Comparison = Fixture.String(), Inherited = 0, CompareEventFlag = 1}.In(Db);
                var dateComparison1 = new DueDateCalc(e, 2) {FromEventId = fe2.Id, FromEvent = fe2, CompareEventId = ce2.Id, CompareEvent = ce2, Comparison = Fixture.String(), Inherited = 1, CompareEventFlag = 1}.In(Db);

                // decoys
                new DueDateCalc(new ValidEvent(c.Id, Fixture.Integer()), 1) {CompareEventFlag = 1}.In(Db);
                new DueDateCalc(new ValidEvent(c.Id, Fixture.Integer()), 2) {CompareEventFlag = 0}.In(Db);

                var r = f.Subject.GetDateComparisons(c.Id, e.EventId).ToArray();

                Assert.Equal(2, r.Length);

                var r1 = r.Single(_ => _.Sequence == dateComparison.Sequence);
                var r2 = r.Single(_ => _.Sequence == dateComparison1.Sequence);

                Assert.Equal(dateComparison.FromEventId, r1.EventA.Key);
                Assert.Equal(dateComparison.FromEvent.Description, r1.EventA.Value);
                Assert.Equal(dateComparison.CompareEventId, r1.EventB.Key);
                Assert.Equal(dateComparison.CompareEvent.Description, r1.EventB.Value);
                Assert.Equal(false, r1.IsInherited);
                Assert.Equal(dateComparison.Sequence, r1.Sequence);

                Assert.Equal(dateComparison1.FromEventId, r2.EventA.Key);
                Assert.Equal(dateComparison1.FromEvent.Description, r2.EventA.Value);
                Assert.Equal(dateComparison1.CompareEventId, r2.EventB.Key);
                Assert.Equal(dateComparison1.CompareEvent.Description, r2.EventB.Value);
                Assert.Equal(true, r2.IsInherited);
                Assert.Equal(dateComparison1.Sequence, r2.Sequence);
            }
        }

        public class GetDesignatedJurisdictionsMethod : FactBase
        {
            [Fact]
            public void ReturnsDesignatedJurisdictionsForCriteriaAndEvent()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var c = new CriteriaBuilder {CountryId = "ABC"}.ForEventsEntriesRule().Build().In(Db);
                var e = new ValidEvent(c.Id, Fixture.Integer()).In(Db);

                var jurisdiction = new CountryBuilder {Id = Fixture.String()}.Build().In(Db);

                var designatedDueDateCalc = new DueDateCalc(e, 0) {JurisdictionId = jurisdiction.Id, Jurisdiction = jurisdiction, IsInherited = Fixture.Boolean()}.In(Db);

                // decoys
                new DueDateCalc(e, 1) {FromEventId = Fixture.Integer()}.In(Db);
                new DueDateCalc(e, 2) {JurisdictionId = Fixture.String(), FromEventId = Fixture.Integer()}.In(Db);

                var r = f.Subject.GetDesignatedJurisdictions(c.Id, e.EventId);

                var r1 = r.Single();

                Assert.Equal(jurisdiction.Id, r1.Key);
                Assert.Equal(jurisdiction.Name, r1.Value);
                Assert.Equal(designatedDueDateCalc.IsInherited, r1.IsInherited);
            }
        }

        public class GetGetSatisfyingEventsMethod : FactBase
        {
            [Fact]
            public void ReturnsSatisfyingEventsForCriteriaAndEvent()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var c = new CriteriaBuilder().Build().In(Db);
                var e = new ValidEvent(c.Id, Fixture.Integer()).In(Db);

                var se1 = new Event(Fixture.Integer());
                var se2 = new Event(Fixture.Integer());

                var satisfyingEvent = new RelatedEventRule(e, 1) {RelatedEventId = se1.Id, RelatedEvent = se1, RelativeCycleId = Fixture.Short(), Inherited = 0, SatisfyEvent = 1}.In(Db);
                var satisfyingEvent1 = new RelatedEventRule(e, 2) {RelatedEventId = se2.Id, RelatedEvent = se2, RelativeCycleId = Fixture.Short(), Inherited = 1, SatisfyEvent = 1}.In(Db);

                // decoys
                new RelatedEventRule(new ValidEvent(c.Id, Fixture.Integer()), 1).In(Db);
                new RelatedEventRule(new ValidEvent(c.Id, Fixture.Integer()), 2).In(Db);

                var r = f.Subject.GetSatisfyingEvents(c.Id, e.EventId).ToArray();

                Assert.Equal(2, r.Length);

                var r1 = r.Single(_ => _.Sequence == satisfyingEvent.Sequence);
                var r2 = r.Single(_ => _.Sequence == satisfyingEvent1.Sequence);

                Assert.Equal(satisfyingEvent.RelatedEventId, r1.SatisfyingEvent.Key);
                Assert.Equal(satisfyingEvent.RelatedEvent.Description, r1.SatisfyingEvent.Value);
                Assert.Equal(satisfyingEvent.RelativeCycleId, r1.RelativeCycle);
                Assert.Equal(false, r1.IsInherited);
                Assert.Equal(satisfyingEvent.Sequence, r1.Sequence);

                Assert.Equal(satisfyingEvent1.RelatedEventId, r2.SatisfyingEvent.Key);
                Assert.Equal(satisfyingEvent1.RelatedEvent.Description, r2.SatisfyingEvent.Value);
                Assert.Equal(satisfyingEvent1.RelativeCycleId, r2.RelativeCycle);
                Assert.Equal(true, r2.IsInherited);
                Assert.Equal(satisfyingEvent1.Sequence, r2.Sequence);
            }
        }

        public class GetDatesLogicMethod : FactBase
        {
            [Fact]
            public void ReturnsDatesLogicForCriteriaAndEvent()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var c = new CriteriaBuilder().Build().In(Db);
                var e = new ValidEvent(c.Id, Fixture.Integer()).In(Db);

                var datesLogic = new DatesLogicBuilder().For(e).Build().In(Db);
                var expectedDisplayError = datesLogic.DisplayErrorFlag == 1 ? DatesLogicDisplayErrorOptions.Block.ToString() : DatesLogicDisplayErrorOptions.Warn.ToString();

                var r = f.Subject.GetDatesLogic(c.Id, e.EventId).ToArray();

                Assert.Single(r);

                var r1 = r.Single(_ => _.Sequence == datesLogic.Sequence);

                Assert.Equal(datesLogic.IsInherited, r1.IsInherited);
                Assert.Equal(datesLogic.DateType.ToString(), r1.AppliesTo);
                Assert.Equal(datesLogic.Operator, r1.Operator.Key);
                Assert.Equal(datesLogic.CompareEvent.Description, r1.CompareEvent.Value);
                Assert.Equal(datesLogic.CompareEvent.Id, r1.CompareEvent.Key);
                Assert.Equal(datesLogic.CompareDateType.ToString(), r1.CompareType);
                Assert.Equal(datesLogic.CaseRelationshipId, r1.CaseRelationship.Key);
                Assert.Equal(datesLogic.CaseRelationship.Description, r1.CaseRelationship.Value);

                Assert.Equal(datesLogic.RelativeCycle, r1.RelativeCycle);
                Assert.Equal(datesLogic.MustExist == 1, r1.EventMustExist);
                Assert.Equal(expectedDisplayError, r1.IfRuleFails);
                Assert.Equal(datesLogic.ErrorMessage, r1.FailureMessage);
            }
        }

        public class GetEventsToUpdateMethod : FactBase
        {
            [Fact]
            public void ReturnsEventsForCriteriaAndEvent()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var c = new CriteriaBuilder().Build().In(Db);
                var e = new ValidEvent(c.Id, Fixture.Integer()).In(Db);

                var se1 = new Event(Fixture.Integer()) {Description = "se1"};
                var se2 = new Event(Fixture.Integer()) {Description = "se1"};

                var da = new DateAdjustment {Description = "da"};

                var ue1 = new RelatedEventRule(e, 1) {RelatedEventId = se1.Id, RelatedEvent = se1, Inherited = 0, UpdateEvent = 1, DateAdjustment = da}.In(Db);
                var ue2 = new RelatedEventRule(e, 2) {RelatedEventId = se2.Id, RelatedEvent = se2, Inherited = 1, UpdateEvent = 1, DateAdjustment = da}.In(Db);

                // decoys
                new RelatedEventRule(e, 3) {RelatedEventId = se1.Id, RelatedEvent = se1, SatisfyEvent = 0}.In(Db);
                new RelatedEventRule(new ValidEvent(c.Id, Fixture.Integer()), 1) {SatisfyEvent = null}.In(Db);

                var r = f.Subject.GetEventsToUpdate(c.Id, e.EventId).ToArray();

                Assert.Equal(2, r.Length);

                var r1 = r.Single(_ => _.Sequence == ue1.Sequence);
                var r2 = r.Single(_ => _.Sequence == ue2.Sequence);

                Assert.Equal(ue1.RelatedEventId, r1.EventToUpdate.Key);
                Assert.Equal(ue1.RelatedEvent.Description, r1.EventToUpdate.Value);
                Assert.Equal(ue1.RelativeCycleId, r1.RelativeCycle);
                Assert.Equal(false, r1.IsInherited);
                Assert.Equal(ue1.Sequence, r1.Sequence);
                Assert.Equal(ue1.DateAdjustment.Id, r1.AdjustDate);

                Assert.Equal(ue2.RelatedEventId, r2.EventToUpdate.Key);
                Assert.Equal(ue2.RelatedEvent.Description, r2.EventToUpdate.Value);
                Assert.Equal(ue2.RelativeCycleId, r1.RelativeCycle);
                Assert.Equal(true, r2.IsInherited);
                Assert.Equal(ue2.Sequence, r2.Sequence);
                Assert.Equal(ue2.DateAdjustment.Id, r2.AdjustDate);
            }
        }

        public class GetRemindersMethod : FactBase
        {
            ReminderRule SetupReminderRule(ValidEvent e)
            {
                var rr = new ReminderRuleBuilder().For(e).AsReminderRule().Build().In(Db);
                DataFiller.Fill(rr);
                rr.CriteriaId = e.CriteriaId;
                rr.EventId = e.EventId;
                rr.LetterNo = null;
                rr.RemindEmployee = new NameBuilder(Db).Build();
                rr.NameRelation = new NameRelationBuilder().Build();

                return rr;
            }

            [Theory]
            [InlineData("X", null, new[] {"X"})]
            [InlineData(null, "A;B; C", new[] {"A", "B", "C"})]
            public void ReturnsNameTypes(string nameTypeCode, string extNameType, string[] result)
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var c = new CriteriaBuilder().Build().In(Db);
                var e = new ValidEvent(c.Id, Fixture.Integer()).In(Db);
                var nameTypeBuilder = new NameTypeBuilder();
                if (!string.IsNullOrEmpty(nameTypeCode))
                {
                    nameTypeBuilder.NameTypeCode = nameTypeCode;
                    nameTypeBuilder.Build().In(Db);
                }

                if (!string.IsNullOrEmpty(extNameType))
                {
                    var types = extNameType.Split(';');
                    foreach (var t in types)
                    {
                        nameTypeBuilder.NameTypeCode = t.Trim();
                        nameTypeBuilder.Build().In(Db);
                    }
                }

                var rr = new ReminderRuleBuilder().For(e).Build().In(Db);
                rr.NameTypeId = nameTypeCode;
                rr.ExtendedNameType = extNameType;

                var r = f.Subject.GetReminders(c.Id, e.EventId);
                var r1 = r.Single(_ => _.Sequence == rr.Sequence);
                var resultNameTypes = ((IEnumerable<PicklistModel<string>>) r1.NameTypes).Select(_ => _.Code).ToArray();
                foreach (var rnt in result) Assert.Contains(rnt, resultNameTypes);
            }

            [Fact]
            public void DefaultsNullFrequencyPeriodFromLeadTimePeriod()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var c = new CriteriaBuilder().Build().In(Db);
                var e = new ValidEvent(c.Id, Fixture.Integer()).In(Db);

                var rr = SetupReminderRule(e);
                rr.FreqPeriodType = null;

                var r = f.Subject.GetReminders(c.Id, e.EventId);

                var r1 = r.Single(_ => _.Sequence == rr.Sequence);

                Assert.Equal(rr.PeriodType, r1.RepeatEvery.Type);
            }

            [Fact]
            public void ReturnsNullFrequencyForNonRecurringReminders()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var c = new CriteriaBuilder().Build().In(Db);
                var e = new ValidEvent(c.Id, Fixture.Integer()).In(Db);

                var rr = SetupReminderRule(e);
                rr.Frequency = 0; // non recurring

                var r = f.Subject.GetReminders(c.Id, e.EventId);

                var r1 = r.Single(_ => _.Sequence == rr.Sequence);

                Assert.Null(r1.RepeatEvery);
            }

            [Fact]
            public void ReturnsReminderRules()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var c = new CriteriaBuilder().Build().In(Db);
                var e = new ValidEvent(c.Id, Fixture.Integer()).In(Db);

                var rr = SetupReminderRule(e);

                // Produce Letter decoy
                new ReminderRuleBuilder().For(e).AsDocumentRule().Build().In(Db);

                var r = f.Subject.GetReminders(c.Id, e.EventId).ToArray();

                Assert.Single(r);

                var r1 = r.Single(_ => _.Sequence == rr.Sequence);

                Assert.Equal(rr.Sequence, r1.Sequence);
                Assert.Equal(rr.Message1, r1.StandardMessage);
                Assert.Equal(rr.Message2, r1.AlternateMessage);
                Assert.Equal(rr.LeadTime, r1.StartBefore.Value);
                Assert.Equal(rr.PeriodType, r1.StartBefore.Type);
                Assert.Equal(rr.Frequency, r1.RepeatEvery.Value);
                Assert.Equal(rr.FreqPeriodType, r1.RepeatEvery.Type);
                Assert.Equal(rr.StopTime, r1.StopTime.Value);
                Assert.Equal(rr.StopTimePeriodType, r1.StopTime.Type);
                Assert.Equal(rr.SendElectronically == 1, r1.SendEmail);
                Assert.Equal(rr.EmailSubject, r1.EmailSubject);
                Assert.Equal(rr.EmployeeFlag == 1, r1.SendToStaff);
                Assert.Equal(rr.SignatoryFlag == 1, r1.SendToSignatory);
                Assert.Equal(rr.CriticalFlag == 1, r1.SendToCriticalList);
                Assert.Equal(rr.RemindEmployeeId, r1.Name.Key);
                Assert.Equal(rr.RelationshipId, r1.Relationship.Key);
                Assert.Equal(rr.IsInherited, r1.IsInherited);
            }
        }

        public class GetDocumentsMethod : FactBase
        {
            [Fact]
            public void ReturnsDocumentRules()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var c = new CriteriaBuilder().Build().In(Db);
                var e = new ValidEvent(c.Id, Fixture.Integer()).In(Db);

                var letter = new DocumentBuilder().Build();
                var rr = new ReminderRuleBuilder {UpdateEvent = 2}.For(e).AsDocumentRule(letter).Build().In(Db);

                rr.LetterFee = new ChargeType {Id = Fixture.Short(), Description = Fixture.String()};
                rr.LetterFeeId = rr.LetterFee.Id;
                rr.PayFeeCode = Fixture.Short(3).ToString();
                rr.EstimateFlag = Fixture.Boolean() ? 1 : 0;
                rr.DirectPayFlag = Fixture.Boolean();
                rr.CheckOverride = Fixture.Boolean() ? 1 : 0;

                // Reminder Rule decoy
                new ReminderRuleBuilder().For(e).AsReminderRule().Build().In(Db);

                var r = f.Subject.GetDocuments(c.Id, e.EventId).ToArray();

                Assert.Single(r);

                var r1 = r.Single(_ => _.Sequence == rr.Sequence);

                Assert.Equal(rr.Sequence, r1.Sequence);
                Assert.Equal(rr.LetterNo, r1.Document.Key);
                Assert.Equal(letter.Name, r1.Document.Value);
                Assert.Equal(ProduceWhenOptions.EventOccurs, r1.Produce);

                Assert.Equal(rr.LeadTime, r1.StartBefore.Value);
                Assert.Equal(rr.PeriodType, r1.StartBefore.Type);
                Assert.Equal(rr.Frequency, r1.RepeatEvery.Value);
                Assert.Equal(rr.FreqPeriodType, r1.RepeatEvery.Type);
                Assert.Equal(rr.StopTime, r1.StopTime.Value);
                Assert.Equal(rr.StopTimePeriodType, r1.StopTime.Type);
                Assert.Equal(rr.MaxLetters, r1.MaxDocuments);

                Assert.Equal(rr.LetterFeeId, r1.ChargeType.Key);
                Assert.Equal(rr.LetterFee.Description, r1.ChargeType.Value);
                Assert.Equal(rr.PayFeeCode == "1" || rr.PayFeeCode == "3", r1.IsPayFee);
                Assert.Equal(rr.PayFeeCode == "2" || rr.PayFeeCode == "3", r1.IsRaiseCharge);
                Assert.Equal(rr.EstimateFlag == 1, r1.IsEstimate);
                Assert.Equal(rr.DirectPayFlag, r1.IsDirectPay);

                Assert.Equal(rr.CheckOverride == 1, r1.IsCheckCycleForSubstitute);

                Assert.Equal(rr.IsInherited, r1.IsInherited);
            }
        }

        public class GetEventsToClearMethod : FactBase
        {
            [Theory]
            [InlineData(1, 0, false, false, 1)]
            [InlineData(1, null, false, false, 1)]
            [InlineData(0, 1, false, false, 1)]
            [InlineData(null, 1, false, false, 1)]
            [InlineData(0, 0, true, false, 1)]
            [InlineData(0, 0, false, true, 1)]
            [InlineData(0, 0, false, false, 0)]
            public void ReturnsCorrectCountOfEventsToClear(int? clearEvent, int? clearDue, bool clearEventOnDueChange, bool clearDueOnDueChange, int result)
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var c = new CriteriaBuilder().Build().In(Db);
                var e = new ValidEvent(c.Id, Fixture.Integer()).In(Db);

                var se1 = new Event(-111) {Description = "Descripiton"};
                new RelatedEventRule(e, 2).In(Db);
                new RelatedEventRule(e, 1)
                {
                    RelatedEventId = se1.Id,
                    RelatedEvent = se1,
                    RelativeCycleId = 123,
                    Inherited = 0,
                    ClearEvent = clearEvent,
                    ClearDue = clearDue,
                    ClearEventOnDueChange = clearEventOnDueChange,
                    ClearDueOnDueChange = clearDueOnDueChange
                }.In(Db);

                var r = f.Subject.GetEventsToClear(c.Id, e.EventId);

                Assert.Equal(result, r.Count());
            }

            [Fact]
            public void ReturnsGetEventsToClear()
            {
                var f = new WorkFlowEventControlControllerFixture(Db);
                var c = new CriteriaBuilder().Build().In(Db);
                var e = new ValidEvent(c.Id, Fixture.Integer()).In(Db);

                var se1 = new Event(-111) {Description = "Descripiton"};

                new RelatedEventRule(e, 2).In(Db);

                new RelatedEventRule(e, 1)
                {
                    RelatedEventId = se1.Id,
                    RelatedEvent = se1,
                    RelativeCycleId = 123,
                    Inherited = 0,
                    ClearEvent = 1,
                    ClearDue = 0,
                    ClearEventOnDueChange = true,
                    ClearDueOnDueChange = false
                }.In(Db);

                var r = f.Subject.GetEventsToClear(c.Id, e.EventId).ToArray();

                Assert.Equal(r.First().Sequence, 1);
                Assert.Equal(r.First().IsInherited, false);
                Assert.Equal(r.First().EventToClear.Key, -111);
                Assert.Equal(r.First().EventToClear.Value, "Descripiton");
                Assert.Equal(r.First().RelativeCycle, 123);
                Assert.True(r.First().ClearEventOnEventChange);
                Assert.False(r.First().ClearDueDateOnEventChange);
                Assert.True(r.First().ClearEventOnDueDateChange);
                Assert.False(r.First().ClearDueDateOnDueDateChange);
            }
        }

        class WorkFlowEventControlControllerFixture : IFixture<WorkflowEventControlController>
        {
            public WorkFlowEventControlControllerFixture(InMemoryDbContext db)
            {
                WorkflowEventControlService = Substitute.For<IWorkflowEventControlService>();
                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                WorkflowPermissionHelper = Substitute.For<IWorkflowPermissionHelper>();
                WorkflowEventInheritanceService = Substitute.For<IWorkflowEventInheritanceService>();
                DbContext = db;

                Subject = new WorkflowEventControlController(DbContext, WorkflowEventControlService, preferredCultureResolver, WorkflowPermissionHelper, WorkflowEventInheritanceService);
            }

            public IWorkflowEventControlService WorkflowEventControlService { get; }

            public IWorkflowPermissionHelper WorkflowPermissionHelper { get; }

            public IWorkflowEventInheritanceService WorkflowEventInheritanceService { get; }

            public IDbContext DbContext { get; }

            public WorkflowEventControlController Subject { get; }
        }
    }
}