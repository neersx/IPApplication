using System.Collections.Generic;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Web.Builders.Model.Rules
{
    public class ValidEventBuilder : IBuilder<ValidEvent>
    {
        public Criteria Criteria { get; set; }
        public Event Event { get; set; }
        public Importance Importance { get; set; }
        public string Description { get; set; }
        public short? NumberOfCyclesAllowed { get; set; }
        public short? DisplaySequence { get; set; }
        public bool Inherited { get; set; }
        public decimal? InheritedDecimal => Inherited ? 1 : 0;
        public int? ParentCriteriaNo { get; set; }
        public short? ParentEventNo { get; set; }
        public string ImportanceLevel { get; set; }
        public short? MaxCycles { get; set; }
        public string Notes { get; set; }
        public int? DueDateRespNameId { get; set; }
        public string DueDateRespNameTypeCode { get; set; }
        public string DateToUse { get; set; }
        public short? ExtendPeriod { get; set; }
        public string ExtendPeriodType { get; set; }
        public bool? RecalcDueDate { get; set; }
        public bool? SuppressDueDateCalculation { get; set; }
        public short? SaveDueDate { get; set; }
        public decimal? SyncedFromCase { get; set; }
        public bool? UseReceivingCycle { get; set; }
        public int? SyncedEventId { get; set; }
        public string SyncedCaseRelationshipId { get; set; }
        public string SyncedNumberTypeId { get; set; }
        public string SyncedEventDateAdjustmentId { get; set; }
        public string InstructionType { get; set; }
        public short? FlagNumber { get; set; }
        public bool? IsThirdPartyOn { get; set; }
        public bool? IsThirdPartyOff { get; set; }
        public string OpenActionId { get; set; }
        public string CloseActionId { get; set; }
        public short? RelativeCycle { get; set; }

        public ValidEvent Build()
        {
            var @event = Event ?? new EventBuilder().Build();
            var validEvent = new ValidEvent(
                                            Criteria ?? new CriteriaBuilder().Build(),
                                            @event,
                                            Description)
            {
                NumberOfCyclesAllowed = NumberOfCyclesAllowed ?? Fixture.Short(),
                DisplaySequence = DisplaySequence ?? Fixture.Short(),
                Importance = Importance ?? new ImportanceBuilder().Build(),
                Inherited = Inherited ? 1 : 0,
                SaveDueDate = SaveDueDate,
                DateToUse = DateToUse,
                RecalcEventDate = RecalcDueDate,
                ExtendPeriod = ExtendPeriod,
                ExtendPeriodType = ExtendPeriodType,
                SuppressDueDateCalculation = SuppressDueDateCalculation,

                SyncedFromCase = SyncedFromCase,
                UseReceivingCycle = UseReceivingCycle,
                SyncedEventId = SyncedEventId,
                SyncedCaseRelationshipId = SyncedCaseRelationshipId,
                SyncedNumberTypeId = SyncedNumberTypeId,
                SyncedEventDateAdjustmentId = SyncedEventDateAdjustmentId,
                OpenActionId = OpenActionId,
                CloseActionId = CloseActionId,
                RelativeCycle = RelativeCycle
            };
            validEvent.Event = @event;
            validEvent.EventId = @event.Id;
            validEvent.ImportanceLevel = ImportanceLevel ?? validEvent.Importance.Level;
            validEvent.ParentCriteriaNo = ParentCriteriaNo;
            validEvent.ParentEventNo = ParentEventNo;
            validEvent.NumberOfCyclesAllowed = MaxCycles;
            validEvent.Notes = Notes;
            validEvent.DueDateRespNameId = DueDateRespNameId;
            validEvent.DueDateRespNameTypeCode = DueDateRespNameTypeCode;
            validEvent.InstructionType = InstructionType;
            validEvent.FlagNumber = FlagNumber;
            validEvent.IsThirdPartyOn = IsThirdPartyOn;
            validEvent.IsThirdPartyOff = IsThirdPartyOff;

            validEvent.DueDateCalcs = new List<DueDateCalc>();
            validEvent.RelatedEvents = new List<RelatedEventRule>();
            validEvent.DatesLogic = new List<DatesLogic>();
            validEvent.Reminders = new List<ReminderRule>();
            validEvent.NameTypeMaps = new List<NameTypeMap>();
            validEvent.RequiredEvents = new List<RequiredEventRule>();

            return validEvent;
        }

        public static ValidEventBuilder ForCyclicEvent(Criteria criteria, Event @event)
        {
            return new ValidEventBuilder
            {
                Criteria = criteria,
                Event = @event,
                NumberOfCyclesAllowed = 2
            };
        }

        public static ValidEventBuilder ForNonCyclicEvent(Criteria criteria, Event @event)
        {
            return new ValidEventBuilder
            {
                Criteria = criteria,
                Event = @event,
                NumberOfCyclesAllowed = 1
            };
        }
    }

    public static class ValidEventBuilderEx
    {
        public static ValidEventBuilder AsNonCyclic(this ValidEventBuilder builder)
        {
            builder.NumberOfCyclesAllowed = 1;
            return builder;
        }

        public static ValidEventBuilder For(this ValidEventBuilder builder, Criteria criteria, Event @event)
        {
            builder.Criteria = criteria;
            builder.Event = @event;
            return builder;
        }

        public static ValidEventBuilder WithParentInheritance(this ValidEventBuilder builder, short? parentEvent = null)
        {
            builder.ParentCriteriaNo = builder.Criteria.ParentCriteriaId ?? Fixture.Integer();
            builder.ParentEventNo = parentEvent ?? Fixture.Short();
            builder.Inherited = true;
            return builder;
        }

        public static ValidEvent BuildWithDueDateCalcs(this ValidEventBuilder builder, InMemoryDbContext db, int numberToGenerate)
        {
            var validEvent = builder.Build().In(db);
            for (var i = 0; i < numberToGenerate; i++) validEvent.DueDateCalcs.Add(new DueDateCalcBuilder {Inherited = builder.InheritedDecimal}.For(validEvent).Build().In(db));
            return validEvent;
        }

        public static ValidEvent BuildWithRelatedEvents(this ValidEventBuilder builder, InMemoryDbContext db, int numberToGenerate)
        {
            var validEvent = builder.Build().In(db);
            for (var i = 0; i < numberToGenerate; i++) validEvent.RelatedEvents.Add(new RelatedEventRuleBuilder {Inherited = builder.InheritedDecimal}.For(validEvent).Build().In(db));
            return validEvent;
        }

        public static ValidEvent BuildWithDatesLogic(this ValidEventBuilder builder, InMemoryDbContext db, int numberToGenerate)
        {
            var validEvent = builder.Build().In(db);
            for (var i = 0; i < numberToGenerate; i++) validEvent.DatesLogic.Add(new DatesLogicBuilder {Inherited = builder.InheritedDecimal}.For(validEvent).Build().In(db));
            return validEvent;
        }

        public static ValidEvent BuildWithReminders(this ValidEventBuilder builder, InMemoryDbContext db, int numberToGenerate)
        {
            var validEvent = builder.Build().In(db);
            for (var i = 0; i < numberToGenerate; i++) validEvent.Reminders.Add(new ReminderRuleBuilder {Inherited = builder.InheritedDecimal}.For(validEvent).AsReminderRule().Build().In(db));
            return validEvent;
        }

        public static ValidEvent BuildWithNameTypeMaps(this ValidEventBuilder builder, InMemoryDbContext db, int numberToGenerate)
        {
            var validEvent = builder.Build().In(db);
            for (var i = 0; i < numberToGenerate; i++) validEvent.NameTypeMaps.Add(new NameTypeMapBuilder {Inherited = builder.Inherited}.For(validEvent).Build().In(db));
            return validEvent;
        }

        public static ValidEvent BuildWithRequiredEvents(this ValidEventBuilder builder, InMemoryDbContext Db, int numberToGenerate)
        {
            var validEvent = builder.Build().In(Db);
            for (var i = 0; i < numberToGenerate; i++) validEvent.RequiredEvents.Add(new RequiredEventRuleBuilder {Inherited = builder.Inherited}.For(validEvent).Build().In(Db));
            return validEvent;
        }
    }
}