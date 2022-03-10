using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.StandingInstructions;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    public class EventControlDbSetup : DbSetup
    {
        static readonly string CriteriaDescription = Fixture.Prefix("criteria");
        static readonly string EventDescription = Fixture.Prefix("event");
        static readonly string EventControlDescription = Fixture.Prefix("eventControl");
        static readonly string UpdateFromEventDescription = Fixture.Prefix("updateFromEvent");
        static readonly string DueDateEventDescription = Fixture.Prefix("dueDateEvent");
        static readonly string RelatedEventsEventDescription = Fixture.Prefix("relatedEventsEvent");
        static readonly string DetailDatesEventDescription = Fixture.Prefix("detailDatesEvent");
        static readonly string DetailControlEventDescription = Fixture.Prefix("detailControlEvent");
        static readonly string CaseRelationDescription = Fixture.Prefix("relationship");
        static readonly string DateAdjustmentDescription = Fixture.Prefix("dateAdjustment");
        static readonly string NumberTypeDescription = Fixture.Prefix("numberType");
        static readonly string InstructionTypeDescription = Fixture.Prefix("instructionType");
        static readonly string CharacteristicDescription = Fixture.Prefix("characteristic");
        static readonly string UserDefinedStatus = Fixture.Prefix("userDefinedStatus");

        public DataFixture SetUp()
        {
            var @event = InsertWithNewId(new Event
            {
                Description = EventDescription
            });

            var groupJurisdiction = InsertWithNewId(new Country {Name = Fixture.String(5), Type = "1"});

            var criteria = InsertWithNewId(new Criteria
            {
                Description = CriteriaDescription,
                PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                CountryId = groupJurisdiction.Id,
                UserDefinedRule = 0,
                RuleInUse = 1,
                LocalClientFlag = 1
            });

            var updateFromEvent = InsertWithNewId(new Event
            {
                Description = UpdateFromEventDescription
            });

            var nameType = Insert(new NameType(Fixture.String(3), Fixture.Prefix("nameType")));

            var dateAdjust = InsertWithNewId(new DateAdjustment
                                                 {
                                                     Description = DateAdjustmentDescription
                                                 });

            var caseRelation = InsertWithNewId(new CaseRelation { Description = CaseRelationDescription });

            var numberType = InsertWithNewId(new NumberType
                                                 {
                                                     Name = NumberTypeDescription
                                                 }, v => v.NumberTypeCode);

            var instructionType = Insert(new InstructionType
            {
                Code = Fixture.String(3),
                Description = InstructionTypeDescription,
                NameType = nameType
            });

            var characteristics = Insert(new Characteristic
            {
                InstructionType = instructionType,
                Description = CharacteristicDescription
            });

            var caseStatus = InsertWithNewId(new Status { Name = Fixture.Prefix("case status") });
            var renewalStatus = InsertWithNewId(new Status {Name = Fixture.Prefix("renewal status")});
            var charge = InsertWithNewId(new ChargeType { Description = Fixture.Prefix("chargeType") });
            var action = InsertWithNewId(new Action { Name = Fixture.Prefix("action") });

            var eventControl = Insert(new ValidEvent
            {
                CriteriaId = criteria.Id,
                EventId = @event.Id,
                Description = EventControlDescription,
                SyncedEventId = updateFromEvent.Id,
                SaveDueDate = 8,
                DateToUse = "E",
                RecalcEventDate = true,
                ExtendPeriod = 6,
                ExtendPeriodType = "M",
                SuppressDueDateCalculation = true,

                NumberOfCyclesAllowed = 2,
                ImportanceLevel = "8",
                Notes = "e2e - notes",
                UseReceivingCycle = true,
                SyncedEventDateAdjustment = dateAdjust,
                SyncedCaseRelationship = caseRelation,
                SyncedNumberType = numberType,
                RequiredCharacteristic = characteristics,
                DatesLogicComparisonType = DatesLogicComparisonType.All,
                ChangeStatus = caseStatus,
                ChangeRenewalStatus = renewalStatus,
                UserDefinedStatus = UserDefinedStatus,
                IsThirdPartyOn = true,
                IsThirdPartyOff = false,
                IsPayFee = true,
                IsRaiseCharge = true,
                IsEstimate = true,
                IsDirectPay = true,
                InitialFee = charge,
                IsPayFee2 = true,
                IsRaiseCharge2 = true,
                IsEstimate2 = true,
                IsDirectPay2 = true,
                InitialFee2 = charge,
                OpenAction = action,
                CloseAction = action,
                RelativeCycle = 1,
                ChangeNameType = nameType,
                CopyFromNameType = nameType,
                MoveOldNameToNameType = nameType,
                DeleteCopyFromName = true
            });

            var dueDateEvent = InsertWithNewId(new Event
            {
                Description = DueDateEventDescription
            });

            var dueDate = Insert(new DueDateCalc
            {
                CriteriaId = criteria.Id,
                EventId = @event.Id,
                Sequence = 0,
                CompareEventId = dueDateEvent.Id,
                EventDateFlag = 1,
                FromEvent = dueDateEvent
            });

            var dateComparison = Insert(new DueDateCalc
            {
                CriteriaId = criteria.Id,
                EventId = @event.Id,
                Sequence = 1,
                Comparison = "<",
                CompareEventId = dueDateEvent.Id,
                FromEventId = dueDateEvent.Id,
                EventDateFlag = 1, // event A Compare Date
                RelativeCycle = 0, // event A Rel Cycle
                CompareEventFlag = 2, // event B Compare Date
                CompareCycle = 3, // event B Compare Cycle
                MustExist = 1
            });

            var relatedEventsEvent = InsertWithNewId(new Event
            {
                Description = RelatedEventsEventDescription
            });

            var satisfyingEvent = Insert(new RelatedEventRule
            {
                CriteriaId = criteria.Id,
                EventId = @event.Id,
                Sequence = 0,
                RelatedEventId = relatedEventsEvent.Id,
                SatisfyEvent = 1,
                RelativeCycleId = 1
            });

            var memberJurisdiction = InsertWithNewId(new Country { Name = Fixture.String(5), Type = "0" });
            Insert(new CountryGroup(groupJurisdiction.Id, memberJurisdiction.Id));

            Insert(new DueDateCalc
            {
                CriteriaId = criteria.Id,
                EventId = @event.Id,
                Sequence = 2,
                JurisdictionId = memberJurisdiction.Id
            });
            
            var clearEvent = Insert(new RelatedEventRule
            {
                CriteriaId = criteria.Id,
                EventId = @event.Id,
                Sequence = 1,
                RelatedEventId = relatedEventsEvent.Id,
                ClearDue = 1,
                ClearEvent = 1,
                RelativeCycleId = 1,
                Inherited = 1,
                ClearDueOnDueChange = true,
                ClearEventOnDueChange = true
            });

            var updatEvent = Insert(new RelatedEventRule
            {
                CriteriaId = criteria.Id,
                EventId = @event.Id,
                Sequence = 2,
                UpdateEvent = 1,
                RelatedEventId = relatedEventsEvent.Id,
                DateAdjustment = dateAdjust,
                RelativeCycleId = 1,
                Inherited = 1
            });

            var detailDatesEvent = InsertWithNewId(new Event
            {
                Description = DetailDatesEventDescription
            });

            var dataEntryTask = Insert(new DataEntryTask
            {
                CriteriaId = criteria.Id,
                Id = 0
            });

            Insert(new AvailableEvent
            {
                CriteriaId = criteria.Id,
                EventId = @event.Id,
                DataEntryTaskId = dataEntryTask.Id,
                AlsoUpdateEventId = detailDatesEvent.Id
            });

            InsertWithNewId(new Event
            {
                Description = DetailControlEventDescription
            });

            Insert(new DataEntryTask
            {
                CriteriaId = criteria.Id,
                Id = 1
            });

            var dateLogic = Insert(new DatesLogic
            {
                CriteriaId = criteria.Id,
                EventId = @event.Id,
                Sequence = 1,
                DateTypeId = 0,
                Operator = "<",
                CompareEventId = @event.Id,
                CompareDateTypeId = 1,
                CaseRelationship = caseRelation
            });

            var reminder = Insert(new ReminderRule
            {
                CriteriaId = criteria.Id,
                EventId = @event.Id,
                Sequence = 0,
                LetterNo = null,
                LeadTime = 1,
                PeriodType = "D",
                Frequency = 1,
                FreqPeriodType = "M",
                StopTime = 1,
                StopTimePeriodType = "Y",
                Inherited = 1,
                Message1 = "e2e - Reminder"
            });

            var doc = InsertWithNewId(new Document(Fixture.Prefix("document"), Fixture.String(10)));

            var document = Insert(new ReminderRule
            {
                CriteriaId = criteria.Id,
                EventId = @event.Id,
                Sequence = 1,
                LetterNo = doc.Id,
                LeadTime = 1,
                PeriodType = "D",
                Frequency = 1,
                FreqPeriodType = "M",
                StopTime = 1,
                StopTimePeriodType = "Y",
                Inherited = 1,
                Message1 = "e2e - Document"
            });

            return new DataFixture
            {
                CriteriaId = criteria.Id.ToString(),
                EventNumber = @event.Id.ToString(),
                BaseDescription = @event.Description,
                EventDescription = eventControl.Description,
                MaxCycles = eventControl.NumberOfCyclesAllowed.ToString(),
                Notes = eventControl.Notes,
                ImportanceLevel = eventControl.ImportanceLevel,
                ExtendDueDatePeriod = eventControl.ExtendPeriod.ToString(),
                ExtendDueDateUnit = eventControl.ExtendPeriodType,
                UseEventId = updateFromEvent.Id,
                UseEvent = updateFromEvent.Description,
                DateAdjustment = dateAdjust.Description,
                Relationship = caseRelation.Description,
                SyncOfficialNumber = numberType.Name,
                InstructionType = instructionType.Description,
                RequiredCharacteristic = characteristics.Description,
                CaseStatus = caseStatus.Name,
                RenewalStatus = renewalStatus.Name,
                UserDefinedStatus = UserDefinedStatus,
                GenerateCharge1 = charge.Description,
                GenerateCharge2 = charge.Description,
                OpenAction = action.Name,
                CloseAction = action.Name,
                RelativeCycle = eventControl.RelativeCycle.ToString(),
                ChangeCaseName = nameType.Name,
                CopyFromName = nameType.Name,
                MoveToName = nameType.Name,
                NameType = nameType.Name,

                DueDateEventId = dueDate.FromEvent.Id.ToString(),
                DueDateEventDescription = dueDate.FromEvent.Description,
                DateComparisonEvent1Number = dateComparison.FromEvent.Id.ToString(),
                DateComparisonEvent1Description = dateComparison.FromEvent.Description,
                DateComparisonOperator = dateComparison.Comparison,
                DateComparisonEvent2Number = dateComparison.CompareEvent.Id.ToString(),
                DateComparisonEvent2Description = dateComparison.CompareEvent.Description,
                SatisfyingEventNumber = satisfyingEvent.RelatedEvent.Id.ToString(),
                SatisfyingEventName = satisfyingEvent.RelatedEvent.Description,
                DesignatedJurisdiction = memberJurisdiction.Name,
                ReminderMessage = reminder.Message1,
                DocumentName = document.Letter.Name,
                EventToClear = clearEvent.RelatedEvent.Description,
                NumberOfEventToClear = clearEvent.RelatedEvent.Id.ToString(),
                EventToUpdate = updatEvent.RelatedEvent.Description,
                NumberOfEventToUpdate = updatEvent.RelatedEvent.Id.ToString(),
                DateOfEventToUpdate = updatEvent.DateAdjustment.Description,
                DateLogicAppliesTo = dateLogic.DateType == DatesLogicDateType.Event ? "Event Date" : "Due Date",
                DateLogicOperator = dateLogic.Operator,
                DateLogicCompareTo = dateLogic.CompareEvent.Description,
                DateLogicUseRelationship = dateLogic.CaseRelationship.Description
            };
        }

        public class DataFixture
        {
            public string CriteriaId { get; set; }
            public string EventNumber { get; set; }
            public string BaseDescription { get; set; }
            public string EventDescription { get; set; }
            public string MaxCycles { get; set; }
            public string Notes { get; set; }
            public string ImportanceLevel { get; set; }
            public string NameType { get; set; }
            public int UseEventId { get; set; }
            public string UseEvent { get; set; }
            public string DateAdjustment { get; set; }
            public string Relationship { get; set; }
            public string SyncOfficialNumber { get; set; }
            public string InstructionType { get; set; }
            public string RequiredCharacteristic { get; set; }
            public string CaseStatus { get; set; }
            public string RenewalStatus { get; set; }
            public string UserDefinedStatus { get; set; }
            public string GenerateCharge1 { get; set; }
            public string GenerateCharge2 { get; set; }
            public string OpenAction { get; set; }
            public string CloseAction { get; set; }
            public string RelativeCycle { get; set; }
            public string ChangeCaseName { get; set; }
            public string CopyFromName { get; set; }
            public string MoveToName { get; set; }
            public string ExtendDueDatePeriod { get; set; }
            public string ExtendDueDateUnit { get; set; }
            public string DueDateEventId { get; set; }
            public string DueDateEventDescription { get; set; }
            public string DateComparisonEvent1Number { get; set; }
            public string DateComparisonEvent1Description { get; set; }
            public string DateComparisonEvent2Number { get; set; }
            public string DateComparisonEvent2Description { get; set; }
            public string DateComparisonOperator { get; set; }
            public string SatisfyingEventNumber { get; set; }
            public string SatisfyingEventName { get; set; }
            public string SatisfyingEventRelativeCycle { get; set; }
            public string DesignatedJurisdiction { get; set; }
            public string ReminderMessage { get; set; }
            public string DocumentName { get; set; }
            public string EventToClear { get; set; }
            public string NumberOfEventToClear { get; set; }
            public string EventToUpdate { get; set; }
            public string NumberOfEventToUpdate { get; set; }
            public string DateOfEventToUpdate { get; set; }
            public string DateLogicAppliesTo { get; set; }
            public string DateLogicOperator { get; set; }
            public string DateLogicCompareTo { get; set; }
            public string DateLogicUseRelationship { get; set; }
        }
    }
}