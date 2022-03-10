using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Rules;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.StandingInstructions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class WorkflowEventControlServiceGetEventControlFacts
    {
        public class CrossCutting : FactBase
        {
            [Theory]
            [InlineData(1, 1, true, true)]
            [InlineData(0, 1, false, true)]
            [InlineData(1, 0, true, false)]
            [InlineData(0, 0, false, false)]
            public async Task ReturnsIfHasInheritedParentOrHasInheritedChild(int inheritedFromParent, int inheritedChild, bool expectedHasParent, bool expectedHasChild)
            {
                var c = new CriteriaBuilder {UserDefinedRule = 0, Country = new CountryBuilder {Type = "1"}.Build()}.ForEventsEntriesRule().Build().In(Db);

                var @event = new EventBuilder().Build();
                var e = new ValidEvent(c.Id, @event.Id, "b")
                {
                    NumberOfCyclesAllowed = 1,
                    ImportanceLevel = "9",
                    Inherited = inheritedFromParent,
                    Event = @event
                }.In(Db);

                if (inheritedFromParent == 1)
                {
                    var pc = new CriteriaBuilder {UserDefinedRule = 0, Country = new CountryBuilder {Type = "1"}.Build()}.ForEventsEntriesRule().Build().In(Db);
                    var i = new Inherits(c.Id, pc.Id).In(Db);
                    i.Criteria = c;
                    i.FromCriteria = pc;

                    var ve = new ValidEvent(pc.Id, @event.Id, "b")
                    {
                        NumberOfCyclesAllowed = 1,
                        ImportanceLevel = "9",
                        Inherited = 0,
                        Event = @event
                    }.In(Db);

                    pc.ValidEvents.Add(ve);
                }

                var childInherit = new Inherits(Fixture.Integer(), c.Id).In(Db);
                childInherit.Criteria = new CriteriaBuilder {Id = childInherit.CriteriaNo, UserDefinedRule = 0, Country = new CountryBuilder {Type = "1"}.Build()}.ForEventsEntriesRule().Build();
                childInherit.Criteria.ValidEvents.Add(new ValidEvent(childInherit.CriteriaNo, e.EventId, "b") {Inherited = inheritedChild});

                var f = new WorkflowEventControlServiceFixture(Db);

                var r = await f.Subject.GetEventControl(c.Id, e.EventId);

                Assert.Equal(expectedHasParent, r.IsInherited);
                Assert.Equal(expectedHasChild, r.HasChildren);

                if (inheritedFromParent == 1)
                {
                    Assert.NotNull(r.Parent);
                }
                else
                {
                    Assert.Null(r.Parent);
                }
            }

            [Theory]
            [InlineData(true, true, true)]
            [InlineData(false, true, false)]
            [InlineData(true, false, false)]
            [InlineData(false, false, false)]
            public async Task ReturnsIfCanResetInheritance(bool inheritedFromParent, bool canEdit, bool expectedResult)
            {
                var @event = new EventBuilder().Build();
                var c = new CriteriaBuilder {UserDefinedRule = 0, Country = new CountryBuilder {Type = "1"}.Build()}.ForEventsEntriesRule().Build().In(Db);
                var e = new ValidEvent(c.Id, @event.Id, "b")
                {
                    NumberOfCyclesAllowed = 1,
                    ImportanceLevel = "9",
                    Event = @event
                }.In(Db);

                if (inheritedFromParent)
                {
                    var inherits = new Inherits(c.Id, Fixture.Integer()).In(Db);
                    inherits.FromCriteria = new CriteriaBuilder().Build();
                    inherits.FromCriteria.ValidEvents = new[] {new ValidEventBuilder {Event = @event}.Build()};
                }

                var f = new WorkflowEventControlServiceFixture(Db);

                f.PermissionHelper.CanEditEvent(c, e.EventId, out _, out _).ReturnsForAnyArgs(canEdit);

                var r = await f.Subject.GetEventControl(c.Id, e.EventId);

                Assert.Equal(expectedResult, r.CanResetInheritance);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ReturnsIfJurisdictionIsEditableInDueDateCalc(bool withCountry)
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var subject = Substitute.ForPartsOf<WorkflowEventControlService>(f.DbContext, f.PreferredCultureResolver, f.PermissionHelper, f.Inheritance, f.WorkflowEventInheritanceService, f.InprotechVersionChecker, f.Sections, f.TaskSecurity, f.CharacteristicsServiceIndex);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var @event = new EventBuilder().Build().In(Db);
                new ValidEventBuilder().For(criteria, @event).Build().In(Db);

                if (withCountry)
                {
                    criteria.Country = new CountryBuilder {Type = "1"}.Build();
                }

                var r = await subject.GetEventControl(criteria.Id, @event.Id);

                Assert.Equal(!withCountry, r.AllowDueDateCalcJurisdiction);
            }

            [Theory]
            [InlineData(true, false)]
            [InlineData(false, true)]
            public async Task ReturnsPermissionRestrictionInformation(bool blockedByDescendants, bool nonConfigurableEvent)
            {
                var c = new CriteriaBuilder {UserDefinedRule = 0, Country = new CountryBuilder {Type = "1"}.Build()}.ForEventsEntriesRule().Build().In(Db);
                var e = new ValidEventBuilder().For(c, null).Build().In(Db);

                var f = new WorkflowEventControlServiceFixture(Db);

                f.Inheritance.GetInheritanceLevel(c.Id, e.EventId).Returns(InheritanceLevel.Full);

                f.PermissionHelper.CanEditEvent(c, e.EventId, out _, out _)
                 .ReturnsForAnyArgs(_ =>
                 {
                     _[2] = blockedByDescendants;
                     _[3] = nonConfigurableEvent;
                     return false;
                 });
                f.PermissionHelper.CanEdit(Arg.Any<Criteria>()).ReturnsForAnyArgs(false);
                var r = await f.Subject.GetEventControl(c.Id, e.EventId);

                Assert.False(r.CanEdit);
                Assert.False(r.CanDelete, "CanDelete should be False when no edit Permission");
                Assert.Equal(blockedByDescendants, r.EditBlockedByDescendants);
                Assert.Equal(nonConfigurableEvent, r.IsNonConfigurableEvent);
            }
        }

        public class EventControlOverviewFacts : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ReturnsIfOfficesExist(bool hasOffices)
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var @event = new EventBuilder().Build().In(Db);
                new ValidEventBuilder().For(criteria, @event).Build().In(Db);

                if (hasOffices)
                {
                    new OfficeBuilder().Build().In(Db);
                }

                var r = await f.Subject.GetEventControl(criteria.Id, @event.Id);

                Assert.Equal(hasOffices, r.HasOffices);
            }

            [Fact]
            public async Task ReturnsDueDateRespName()
            {
                var n = new Name(1)
                {
                    NameCode = Fixture.String(),
                    LastName = Fixture.String()
                }.In(Db);
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var e = new ValidEvent(c.Id, 1, "b")
                {
                    Name = n,
                    DueDateRespNameId = n.Id,
                    Event = new Event()
                }.In(Db);
                var f = new WorkflowEventControlServiceFixture(Db);

                var ve = await f.Subject.GetEventControl(c.Id, e.EventId);
                var r = ve.Overview;

                Assert.Equal(n.NameCode, r.Data.Name.Code);
                Assert.Equal(n.LastName, r.Data.Name.DisplayName);
                Assert.Equal(DueDateRespTypes.Name, r.Data.DueDateRespType);
            }

            [Fact]
            public async Task ReturnsDueDateRespNameType()
            {
                var nt = new NameType(Fixture.String(), Fixture.String()).In(Db);
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var e = new ValidEvent(c.Id, 1)
                {
                    DueDateRespNameType = nt,
                    DueDateRespNameTypeCode = nt.NameTypeCode,
                    Event = new Event()
                }.In(Db);
                var f = new WorkflowEventControlServiceFixture(Db);

                var ve = await f.Subject.GetEventControl(c.Id, e.EventId);
                var r = ve.Overview;

                Assert.Equal(nt.NameTypeCode, r.Data.NameType.Code);
                Assert.Equal(nt.Name, r.Data.NameType.Value);
                Assert.Equal(DueDateRespTypes.NameType, r.Data.DueDateRespType);
            }

            [Fact]
            public async Task ReturnsEventControlOverview()
            {
                var c = new CriteriaBuilder {UserDefinedRule = 0}.ForEventsEntriesRule().Build().In(Db);
                var e = new ValidEvent(c.Id, 1, "b")
                {
                    Notes = "notes",
                    NumberOfCyclesAllowed = 1,
                    ImportanceLevel = "9",
                    Event = new Event
                    {
                        Description = "a"
                    }
                }.In(Db);
                var f = new WorkflowEventControlServiceFixture(Db);

                var ve = await f.Subject.GetEventControl(c.Id, e.EventId);
                var r = ve.Overview;
                f.PreferredCultureResolver.Received(1).Resolve();

                Assert.Equal(e.Description, r.Data.Description);
                Assert.Equal(e.Event.Description, r.BaseDescription);
                Assert.Equal(e.NumberOfCyclesAllowed, r.Data.MaxCycles);
                Assert.Equal(e.Notes, r.Data.Notes);
                Assert.Equal(e.ImportanceLevel, r.Data.ImportanceLevel);
                Assert.Equal(DueDateRespTypes.NotApplicable, r.Data.DueDateRespType);
            }

            [Fact]
            public async Task ReturnsImportanceLevelsOrderedByLevel()
            {
                var i = new[] {new Importance {Level = "2", Description = "a"}, new Importance {Level = "1", Description = "b"}}.In(Db);

                var f = new WorkflowEventControlServiceFixture(Db);
                var r = await f.Subject.GetImportanceLevels(string.Empty);

                var options = r.ToArray();
                Assert.Equal(i[0].Level, options[1].Key);
                Assert.Equal(i[0].Description, options[1].Value);
                Assert.Equal(i[1].Level, options[0].Key);
                Assert.Equal(i[1].Description, options[0].Value);
            }
        }

        public class DueDateCalcSettings : FactBase
        {
            [Fact]
            public async Task ReturnHasDueDateOnCaseFlag2()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var subject = Substitute.ForPartsOf<WorkflowEventControlService>(f.DbContext, f.PreferredCultureResolver, f.PermissionHelper, f.Inheritance, f.WorkflowEventInheritanceService, f.InprotechVersionChecker, f.Sections, f.TaskSecurity, f.CharacteristicsServiceIndex);
                var criteria = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var @event = new EventBuilder().Build().In(Db);
                new ValidEventBuilder().For(criteria, @event).Build().In(Db);

                subject.GetDueDatesForEventControl(criteria.Id, @event.Id).Returns(new[] {new CaseEventBuilder().Build()}.AsQueryable());
                var r = await subject.GetEventControl(criteria.Id, @event.Id);

                subject.Received(1).GetDueDatesForEventControl(criteria.Id, @event.Id);
                Assert.True(r.HasDueDateOnCase);
            }

            [Fact]
            public async Task ReturnsDueDateCalcSettings()
            {
                var nt = new NameType("D", "Debtor").In(Db);
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var n = new Name(1)
                {
                    NameCode = "ACME",
                    LastName = "Acme Products Inc"
                }.In(Db);
                var e = new ValidEvent(c.Id, -222, "b")
                {
                    DateToUse = "E",
                    RecalcEventDate = true,
                    ExtendPeriod = 1,
                    ExtendPeriodType = "M",
                    SuppressDueDateCalculation = true,
                    Name = n,
                    DueDateRespNameTypeCode = nt.NameTypeCode,
                    DueDateRespNameType = nt,
                    Event = new Event(-222).In(Db)
                }.In(Db);

                new DateAdjustment {Id = "~0"}.In(Db); // in
                new DateAdjustment {Id = "A"}.In(Db); // in
                new DateAdjustment {Id = "~1"}.In(Db); // out

                var f = new WorkflowEventControlServiceFixture(Db);
                var r = (await f.Subject.GetEventControl(c.Id, e.EventId)).DueDateCalcSettings;

                Assert.Equal("E", r.DateToUse);
                Assert.True(r.RecalcEventDate.GetValueOrDefault());
                Assert.Equal(r.ExtendDueDateOptions.Value, (short) 1);
                Assert.Equal("M", r.ExtendDueDateOptions.Type);
                Assert.True(r.DoNotCalculateDueDate.GetValueOrDefault());
                Assert.Equal(2, r.DateAdjustmentOptions.Count());
                Assert.DoesNotContain(r.DateAdjustmentOptions, _ => _.Key == "~1");
            }
        }

        public class RequiredEventFacts : FactBase
        {
            [Fact]
            public async Task ReturnsDateOccursRule()
            {
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var e = new ValidEvent(c.Id, -222, "b")
                {
                    Event = new Event(-222).In(Db),
                    SaveDueDate = 2
                }.In(Db);

                var f = new WorkflowEventControlServiceFixture(Db);

                var r = (await f.Subject.GetEventControl(c.Id, e.EventId)).EventOccurrence;
                Assert.Equal("Immediate", r.DueDateOccurs);

                e.SaveDueDate = 4;
                r = (await f.Subject.GetEventControl(c.Id, e.EventId)).EventOccurrence;
                Assert.Equal("OnDueDate", r.DueDateOccurs);

                e.SaveDueDate = 0;
                r = (await f.Subject.GetEventControl(c.Id, e.EventId)).EventOccurrence;
                Assert.Equal("NotApplicable", r.DueDateOccurs);
            }

            [Fact]
            public async Task ReturnsMatchCharacteristics()
            {
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var e = new ValidEvent(c.Id, -222, "b")
                {
                    Event = new Event(-222).In(Db),
                    OfficeIsThisCase = Fixture.Boolean(),
                    CountryCodeIsThisCase = Fixture.Boolean(),
                    PropertyTypeIsThisCase = Fixture.Boolean(),
                    CaseCategoryIsThisCase = Fixture.Boolean(),
                    SubTypeIsThisCase = Fixture.Boolean(),
                    BasisIsThisCase = Fixture.Boolean()
                }.In(Db);

                var f = new WorkflowEventControlServiceFixture(Db);
                var validatedCharacteristics = new ValidatedCharacteristics();
                f.CharacteristicsService.GetValidCharacteristics(Arg.Any<WorkflowCharacteristics>())
                 .ReturnsForAnyArgs(validatedCharacteristics);

                var r = (await f.Subject.GetEventControl(c.Id, e.EventId)).EventOccurrence;
                Assert.Equal(validatedCharacteristics, r.Characteristics);
                f.CharacteristicsService.Received(1).GetValidCharacteristics(Arg.Any<WorkflowCharacteristics>());
                Assert.Equal(e.OfficeIsThisCase, r.MatchOffice);
                Assert.Equal(e.CountryCodeIsThisCase, r.MatchJurisdiction);
                Assert.Equal(e.PropertyTypeIsThisCase, r.MatchPropertyType);
                Assert.Equal(e.CaseCategoryIsThisCase, r.MatchCaseCategory);
                Assert.Equal(e.SubTypeIsThisCase, r.MatchSubType);
                Assert.Equal(e.BasisIsThisCase, r.MatchBasis);
            }

            [Fact]
            public async Task ReturnsRequiredEventRules()
            {
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);

                var e = new ValidEvent(c.Id, -222, "b")
                {
                    Event = new Event(-222).In(Db)
                }.In(Db);

                var e1 = new RequiredEventRuleBuilder().For(e).Build().In(Db);
                var e2 = new RequiredEventRuleBuilder().For(e).Build().In(Db);

                var f = new WorkflowEventControlServiceFixture(Db);
                var r = (await f.Subject.GetEventControl(c.Id, e.EventId)).EventOccurrence;
                var keys = r.EventsExist.Select(_ => _.Key).ToArray();
                Assert.Equal(2, r.EventsExist.Count());
                Assert.Contains(e1.RequiredEventId, keys);
                Assert.Contains(e2.RequiredEventId, keys);
            }
        }

        public class StandingInstructionFacts : FactBase
        {
            [Fact]
            public void PicklistInstructionTypeReturnsNullIfNoInstructiontype()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var r = f.Subject.PicklistInstructionType(null);

                Assert.Null(r);
            }

            [Fact]
            public async Task ReturnsCharacteristicOptions()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var characteristics = new[]
                {
                    new Characteristic {Id = 1, Description = "abc", InstructionTypeCode = "A"},
                    new Characteristic {Id = 2, Description = "def", InstructionTypeCode = "A"},
                    new Characteristic {Id = 3, Description = "ghi", InstructionTypeCode = "B"}
                }.In(Db);

                var r = (await f.Subject.GetCharacteristicOptions("A", string.Empty)).ToArray();

                Assert.Equal(2, r.Length);
                Assert.Equal(characteristics[0].Id, r[0].Key);
                Assert.Equal(characteristics[0].Description, r[0].Value);
                Assert.Equal(characteristics[1].Id, r[1].Key);
                Assert.Equal(characteristics[1].Description, r[1].Value);
            }

            [Fact]
            public void ReturnsPicklistInstructionType()
            {
                var instructionType = new InstructionType {Id = 1, Code = "A", Description = "abc"}.In(Db);
                var f = new WorkflowEventControlServiceFixture(Db);

                var r = f.Subject.PicklistInstructionType(instructionType);

                Assert.Equal(1, r.Key);
                Assert.Equal("A", r.Code);
                Assert.Equal("abc", r.Value);
            }

            [Fact]
            public async Task ReturnsStandingInstruction()
            {
                var c = new CriteriaBuilder {UserDefinedRule = 0}.ForEventsEntriesRule().Build().In(Db);
                var f = new WorkflowEventControlServiceFixture(Db);

                var instructionType = new InstructionType {Id = 1, Code = "A", Description = "Type"}.In(Db);
                var instruction = new Instruction {InstructionType = instructionType, Description = "instruction 1"}.In(Db);
                var characteristic = new Characteristic {Id = 1, Description = "abc", InstructionTypeCode = "A", InstructionType = instructionType}.In(Db);

                new SelectedCharacteristic {CharacteristicId = 1, Instruction = instruction}.In(Db);
                var e = new ValidEvent(c.Id, 1, "b")
                {
                    Event = new Event {Description = "a"},
                    InstructionType = "A",
                    FlagNumber = 1,
                    RequiredCharacteristic = characteristic
                }.In(Db);

                var ve = await f.Subject.GetEventControl(c.Id, e.EventId);
                var r = ve.StandingInstruction;

                Assert.Equal(instructionType.Id, r.InstructionType.Key);
                Assert.Equal("A", r.InstructionType.Code);
                Assert.Equal("Type", r.InstructionType.Value);
                Assert.Equal(instruction.Description, r.Instructions.Single());
                Assert.Equal(e.FlagNumber, r.RequiredCharacteristic);

                var options = r.CharacteristicsOptions.ToArray();
                Assert.Equal(characteristic.Id, options[0].Key);
                Assert.Equal(characteristic.Description, options[0].Value);
            }

            [Fact]
            public async Task ReturnsUsedInInstructions()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var instructions = new[]
                {
                    new Instruction {Description = "instruction 1"},
                    new Instruction {Description = "instruction 2"},
                    new Instruction {Description = "instruction 3"}
                }.In(Db);
                new SelectedCharacteristic {CharacteristicId = 1, Instruction = instructions[0]}.In(Db);
                new SelectedCharacteristic {CharacteristicId = 1, Instruction = instructions[1]}.In(Db);

                var r = (await f.Subject.GetUsedInInstructions(1)).ToArray();

                Assert.Contains(instructions[0].Description, r);
                Assert.Contains(instructions[1].Description, r);
                Assert.DoesNotContain(instructions[2].Description, r);
            }
        }

        public class DesignatedJurisdictionsFacts : FactBase
        {
            [Fact]
            public async Task ReturnsAllAvailableCountryFlagsForCriteriaCountryGroup()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var c = new Criteria();
                var e = new ValidEvent(c.Id, 1, "a") {CheckCountryFlag = 1};

                c.Country = new Country {Type = "1"};

                new CountryFlag
                {
                    CountryId = c.Country.Id,
                    FlagNumber = 1,
                    Name = "a"
                }.In(Db);

                var r = (await f.Subject.GetDesignatedJurisdictions(c, e, string.Empty)).CountryFlags.Single();

                Assert.Equal(1, r.Key);
                Assert.Equal("a", r.Value);
            }

            [Fact]
            public async Task ReturnsNullIfCountryIsNotGroup()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var c = new Criteria();
                var e = new ValidEvent(c.Id, 1, "a");

                c.Country = new Country {Type = "0"};

                var r = await f.Subject.GetDesignatedJurisdictions(c, e, string.Empty);

                Assert.Null(r);
            }

            [Fact]
            public async Task ReturnsSelectedCountryFlag()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var c = new Criteria();
                var e = new ValidEvent(c.Id, 1, "a") {CheckCountryFlag = 1};

                c.Country = new Country {Type = "1"};

                var r = await f.Subject.GetDesignatedJurisdictions(c, e, string.Empty);

                Assert.Equal(e.CheckCountryFlag, r.CountryFlagForStopReminders);
            }
        }

        public class SyncedEventSettingsFacts : FactBase
        {
            [Fact]
            public async Task ReturnsSyncEventSettingsFromEventControl()
            {
                var f = new WorkflowEventControlServiceFixture(Db);

                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var numberType = new NumberTypeBuilder().Build();
                var caseRelationship = new CaseRelationBuilder().Build();
                var e = new ValidEvent(c.Id, 1, "a")
                {
                    Event = new EventBuilder().Build(),
                    SyncedFromCaseOption = SyncedFromCaseOption.RelatedCase,
                    UseReceivingCycle = true,
                    SyncedEvent = new EventBuilder().Build(),
                    SyncedCaseRelationshipId = caseRelationship.Relationship,
                    SyncedCaseRelationship = caseRelationship,
                    SyncedNumberType = numberType,
                    SyncedNumberTypeId = numberType.NumberTypeCode,
                    SyncedEventDateAdjustmentId = "A"
                }.In(Db);
                new DateAdjustment {Id = "A"}.In(Db); // in
                new DateAdjustment {Id = "~0"}.In(Db); // out

                var r = (await f.Subject.GetEventControl(c.Id, e.EventId)).SyncedEventSettings;

                Assert.Equal(SyncedFromCaseOption.RelatedCase.ToString(), r.CaseOption);
                Assert.Equal("CaseRelationship", r.UseCycle);
                Assert.Equal(e.SyncedEvent.Id, r.FromEvent.Key);
                Assert.Equal(e.SyncedEvent.Description, r.FromEvent.Value);
                Assert.Equal(e.SyncedCaseRelationshipId, r.FromRelationship.Key);
                Assert.Equal(e.SyncedCaseRelationship.Description, r.FromRelationship.Value);
                Assert.Equal(e.SyncedNumberTypeId, r.LoadNumberType.Key);
                Assert.Equal(e.SyncedNumberType.Name, r.LoadNumberType.Value);
                Assert.Equal(e.SyncedEventDateAdjustmentId, r.DateAdjustment);
                Assert.Single(r.DateAdjustmentOptions);
                Assert.Contains(r.DateAdjustmentOptions, _ => _.Key == "A");
            }
        }

        public class ChargesFacts : FactBase
        {
            [Fact]
            public async Task ReturnChargesFromEventControl()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var initialFeeId = 111;
                var initialFeeId2 = 222;
                var initialFee = new ChargeType {Id = initialFeeId, Description = "initial fee 1 description"}.In(Db);
                var initialFee2 = new ChargeType {Id = initialFeeId2, Description = "initial fee 2 description"}.In(Db);
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var e = new ValidEvent(c.Id, 1, "a")
                {
                    Event = new EventBuilder().Build(),
                    InitialFeeId = initialFeeId,
                    InitialFee2Id = initialFeeId2,
                    InitialFee = initialFee,
                    InitialFee2 = initialFee2,
                    PayFeeCode = "1",
                    IsDirectPay = true,
                    EstimateFlag = 0,
                    PayFeeCode2 = "2",
                    IsDirectPay2 = false,
                    EstimateFlag2 = 1
                }.In(Db);

                var r = (await f.Subject.GetEventControl(c.Id, e.EventId)).Charges;

                Assert.False(r.ChargeOne.IsPayFee);
                Assert.True(r.ChargeOne.IsRaiseCharge);
                Assert.False(r.ChargeOne.IsEstimate);
                Assert.Equal(r.ChargeOne.ChargeType.Key, initialFeeId);
                Assert.Equal(r.ChargeOne.ChargeType.Value, "initial fee 1 description");
                Assert.True(r.ChargeTwo.IsPayFee);
                Assert.False(r.ChargeTwo.IsRaiseCharge);
                Assert.True(r.ChargeTwo.IsEstimate);
                Assert.Equal(r.ChargeTwo.ChargeType.Key, initialFeeId2);
                Assert.Equal(r.ChargeTwo.ChargeType.Value, "initial fee 2 description");
            }
        }

        public class UpdateActionSettingFacts : FactBase
        {
            [Fact]
            public async Task ReturnsUpdatActionSetting()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var closeAction = new ActionBuilder().Build().In(Db);
                var openAction = new ActionBuilder().Build().In(Db);
                var e = new ValidEvent(c.Id, 1, "a")
                {
                    Event = new EventBuilder().Build(),
                    CloseActionId = closeAction.Code,
                    CloseAction = closeAction,
                    OpenActionId = openAction.Code,
                    OpenAction = openAction,
                    RelativeCycle = 1
                }.In(Db);

                var r = (await f.Subject.GetEventControl(c.Id, e.EventId)).ChangeAction;

                Assert.Equal(1, r.RelativeCycle);
                Assert.Equal(openAction.Code, r.OpenAction.Key);
                Assert.Equal(closeAction.Code, r.CloseAction.Key);
            }
        }

        public class GetUpdateStatusSettingFacts : FactBase
        {
            [Fact]
            public async Task ReturnsBasicInfo()
            {
                var country = new CountryBuilder {Type = "1"}.Build().In(Db);
                var caseType = new CaseTypeBuilder().Build().In(Db);
                var propertyType = new PropertyTypeBuilder().Build().In(Db);

                var c = new CriteriaBuilder
                    {
                        UserDefinedRule = 0,
                        Country = country,
                        CaseType = caseType,
                        PropertyType = propertyType
                    }.ForEventsEntriesRule()
                     .Build()
                     .In(Db);

                var e = new ValidEvent(c.Id, 1, "b")
                {
                    Notes = "notes",
                    NumberOfCyclesAllowed = 1,
                    ImportanceLevel = "9",
                    Event = new Event
                    {
                        Description = "a"
                    }
                }.In(Db);
                var f = new WorkflowEventControlServiceFixture(Db);

                f.Inheritance.GetInheritanceLevel(c.Id, e.EventId).Returns(InheritanceLevel.Full);

                f.PermissionHelper.CanEditEvent(Arg.Any<Criteria>(), e.EventId, out _, out _).ReturnsForAnyArgs(true);
                f.PermissionHelper.CanEdit(Arg.Any<Criteria>()).ReturnsForAnyArgs(true);

                var r = await f.Subject.GetEventControl(c.Id, e.EventId);

                Assert.Equal(c.Id, r.CriteriaId);
                Assert.Equal(e.EventId, r.EventId);
                Assert.True(r.IsProtected);
                Assert.Equal("Full", r.InheritanceLevel);
                Assert.True(r.CanEdit);
                Assert.True(r.CanDelete);
                Assert.False(r.IsInherited);
                Assert.False(r.HasChildren);
                Assert.Equal(country.Id, r.Characteristics.Jurisdiction.Key);
                Assert.Equal(country.Name, r.Characteristics.Jurisdiction.Value);
                Assert.Equal(propertyType.Code, r.Characteristics.PropertyType.Key);
                Assert.Equal(propertyType.Name, r.Characteristics.PropertyType.Value);
                Assert.Equal(caseType.Code, r.Characteristics.CaseType.Key);
                Assert.Equal(caseType.Name, r.Characteristics.CaseType.Value);
            }

            [Fact]
            public async Task ReturnsCaseStatusThatIsARenewalStatusAsRenewalStatus()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var renStatus = new StatusBuilder().ForRenewal().Build().In(Db);
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var e = new ValidEvent(c.Id, 1, "a")
                {
                    Event = new EventBuilder().Build(),
                    ChangeStatusId = renStatus.Id,
                    ChangeStatus = renStatus
                }.In(Db);

                var r = await f.Subject.GetEventControl(c.Id, e.EventId);

                Assert.Null(r.ChangeStatus);
                Assert.Equal(renStatus.Id, r.ChangeRenewalStatus.Key);
                Assert.Equal(renStatus.Name, r.ChangeRenewalStatus.Value);
            }

            [Fact]
            public async Task ReturnsIfRenewalStatusSupported()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var e = new ValidEvent(c.Id, 1, "a")
                {
                    Event = new EventBuilder().Build()
                }.In(Db);

                var versionCheckResult = Fixture.Boolean();
                f.InprotechVersionChecker.CheckMinimumVersion(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(versionCheckResult);

                var r = await f.Subject.GetEventControl(c.Id, e.EventId);

                Assert.Equal(r.IsRenewalStatusSupported, versionCheckResult);
            }

            [Fact]
            public async Task ReturnsUpdateStatusSettings()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var status = new StatusBuilder().Build().In(Db);
                var renStatus = new StatusBuilder().ForRenewal().Build().In(Db);
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var e = new ValidEvent(c.Id, 1, "a")
                {
                    Event = new EventBuilder().Build(),
                    ChangeStatusId = status.Id,
                    ChangeStatus = status,
                    ChangeRenewalStatusId = renStatus.Id,
                    ChangeRenewalStatus = renStatus
                }.In(Db);

                var r = await f.Subject.GetEventControl(c.Id, e.EventId);

                Assert.Equal(status.Id, r.ChangeStatus.Key);
                Assert.Equal(status.Name, r.ChangeStatus.Value);
                Assert.Equal(renStatus.Id, r.ChangeRenewalStatus.Key);
                Assert.Equal(renStatus.Name, r.ChangeRenewalStatus.Value);
            }

            [Fact]
            public async Task ReturnsUserDefinedStatus()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var e = new ValidEvent(c.Id, 1, "a")
                {
                    Event = new EventBuilder().Build(),
                    UserDefinedStatus = Fixture.String()
                }.In(Db);

                var r = await f.Subject.GetEventControl(c.Id, e.EventId);

                Assert.Equal(e.UserDefinedStatus, r.UserDefinedStatus);
            }
        }

        public class NameChangeSettingsFacts : FactBase
        {
            [Fact]
            public async Task ReturnsNameChangeSettings()
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var changeNameType = new NameTypeBuilder().Build().In(Db);
                var copyFromNameType = new NameTypeBuilder().Build().In(Db);
                var moveToNameType = new NameTypeBuilder().Build().In(Db);
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var e = new ValidEvent(c.Id, 1, "a")
                {
                    Event = new EventBuilder().Build(),
                    ChangeNameTypeCode = changeNameType.NameTypeCode,
                    ChangeNameType = changeNameType,
                    CopyFromNameTypeCode = copyFromNameType.NameTypeCode,
                    CopyFromNameType = copyFromNameType,
                    MoveOldNameToNameTypeCode = moveToNameType.NameTypeCode,
                    MoveOldNameToNameType = moveToNameType,
                    DeleteCopyFromName = true
                }.In(Db);

                var r = (await f.Subject.GetEventControl(c.Id, e.EventId)).NameChangeSettings;

                Assert.Equal(changeNameType.NameTypeCode, r.ChangeNameType.Code);
                Assert.Equal(changeNameType.Id, r.ChangeNameType.Key);
                Assert.Equal(changeNameType.Name, r.ChangeNameType.Value);

                Assert.Equal(copyFromNameType.NameTypeCode, r.CopyFromNameType.Code);
                Assert.Equal(copyFromNameType.Id, r.CopyFromNameType.Key);
                Assert.Equal(copyFromNameType.Name, r.CopyFromNameType.Value);

                Assert.Equal(moveToNameType.NameTypeCode, r.MoveOldNameToNameType.Code);
                Assert.Equal(moveToNameType.Id, r.MoveOldNameToNameType.Key);
                Assert.Equal(moveToNameType.Name, r.MoveOldNameToNameType.Value);

                Assert.True(r.DeleteCopyFromName);
            }
        }

        public class ReportSettingFacts : FactBase
        {
            [Theory]
            [InlineData(false, false, "NoChange")]
            [InlineData(true, false, "On")]
            [InlineData(false, true, "Off")]
            public async Task ReturnsCorrespondingSetting(bool on, bool off, string mode)
            {
                var enumValue = (ReportMode) Enum.Parse(typeof(ReportMode), mode);

                var f = new WorkflowEventControlServiceFixture(Db);
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var e = new ValidEvent(c.Id, 1, "a")
                {
                    Event = new EventBuilder().Build(),
                    IsThirdPartyOn = on,
                    IsThirdPartyOff = off
                }.In(Db);

                var r = (await f.Subject.GetEventControl(c.Id, e.EventId)).Report;

                Assert.Equal(enumValue, r);
            }
        }

        public class PtaDelayFacts : FactBase
        {
            [Theory]
            [InlineData(1)]
            [InlineData(2)]
            [InlineData(null)]
            public async Task ReturnsCorrespondingSetting(int? ptaDelay)
            {
                var f = new WorkflowEventControlServiceFixture(Db);
                var c = new CriteriaBuilder().ForEventsEntriesRule().Build().In(Db);
                var e = new ValidEvent(c.Id, 1, "a")
                {
                    Event = new EventBuilder().Build(),
                    PtaDelay = (short?)ptaDelay
                }.In(Db);

                var r = (await f.Subject.GetEventControl(c.Id, e.EventId)).PtaDelay;

                var expectedPtaDelay = ptaDelay == null ? PtaDelayMode.NotApplicable : (PtaDelayMode) ptaDelay;
                Assert.Equal(expectedPtaDelay, r);
            }
        }
    }
}