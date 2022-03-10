using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.BatchEventUpdate.DataEntryTaskHandlers;
using Inprotech.Web.BatchEventUpdate.Miscellaneous;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Cases.Rules;
using InprotechKaizen.Model.Components.Cases.Validation;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.BatchEventUpdate.Validators
{
    public interface IEventDetailUpdateValidator
    {
        IEnumerable<ValidationResult> Validate(
            Case @case,
            DataEntryTask dataEntryTask,
            string officialNumber,
            int? fileLocationId,
            AvailableEventModel[] availableEvents);

        void EnsureInputIsValid(
            Case @case,
            DataEntryTask dataEntryTask,
            string officialNumber,
            int? fileLocationId,
            AvailableEventModel[] availableEvents);
    }

    public class EventDetailUpdateValidator : IEventDetailUpdateValidator
    {
        readonly IDateRuleValidator _datesRuleValidator;
        readonly IDbContext _dbContext;
        readonly IExternalOfficialNumberValidator _officialNumberValidator;
        readonly Func<DateTime> _systemClock;

        public EventDetailUpdateValidator(
            IDbContext dbContext,
            IExternalOfficialNumberValidator officialNumberValidator,
            IDateRuleValidator datesRuleValidator,
            Func<DateTime> systemClock)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (officialNumberValidator == null) throw new ArgumentNullException("officialNumberValidator");
            if (datesRuleValidator == null) throw new ArgumentNullException("datesRuleValidator");
            if (systemClock == null) throw new ArgumentNullException("systemClock");

            _dbContext = dbContext;
            _officialNumberValidator = officialNumberValidator;
            _datesRuleValidator = datesRuleValidator;
            _systemClock = systemClock;
        }

        public IEnumerable<ValidationResult> Validate(
            Case @case,
            DataEntryTask dataEntryTask,
            string officialNumber,
            int? fileLocationId,
            AvailableEventModel[] availableEvents)
        {
            if (@case == null) throw new ArgumentNullException("case");
            if (dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");

            var vresults = Enumerable.Empty<ValidationResult>();

            if (dataEntryTask.OfficialNumberType != null)
                vresults = vresults.Concat(ValidateOfficialNumber(@case, dataEntryTask, officialNumber));

            if (dataEntryTask.AvailableEvents.Any())
                vresults = vresults.Concat(ValidateAvailableEvents(@case, dataEntryTask, availableEvents));

            return vresults.Concat(ValidateCaseLocationRecordal(@case, fileLocationId));
        }

        public void EnsureInputIsValid(
            Case @case,
            DataEntryTask dataEntryTask,
            string officialNumber,
            int? fileLocationId,
            AvailableEventModel[] availableEvents)
        {
            if (@case == null) throw new ArgumentNullException("case");
            if (dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");

            EnsureAvailableEventsAreCorrect(dataEntryTask, availableEvents);
            EnsureCaseLocationIsValid(fileLocationId);
        }

        IEnumerable<ValidationResult> ValidateOfficialNumber(
            Case @case,
            DataEntryTask dataEntryTask,
            string number)
        {
            if (string.IsNullOrWhiteSpace(number))
            {
                var numerType = dataEntryTask.OfficialNumberType.Name;
                var message = string.Format("\"{0}\" is required", numerType);
                yield return new ValidationResult(message)
                    .ForInput(EventDetailInputNames.OfficialNumber);

                yield break;
            }

            var officialNumberValidationResult = _officialNumberValidator
                .ValidateOfficialNumber(@case.Id, dataEntryTask.OfficialNumberType.NumberTypeCode, number);

            if (officialNumberValidationResult.ErrorCode == 0)
                yield break;

            yield return
                new ValidationResult(
                    officialNumberValidationResult.ErrorMessage,
                    officialNumberValidationResult.WarningFlag == 1 ? Severity.Warning : Severity.Error)
                    .ForInput(EventDetailInputNames.OfficialNumber);
        }

        static void EnsureAvailableEventsAreCorrect(DataEntryTask dataEntryTask, AvailableEventModel[] entryData)
        {
            if (entryData == null) throw new ArgumentNullException("entryData");

            var availableEventIds = dataEntryTask.AvailableEvents.Select(ae => ae.Event.Id);
            var hashedAvailableEventIds = new HashSet<int>(availableEventIds);

            if (!entryData.Select(ae => ae.EventId).All(hashedAvailableEventIds.Contains))
                throw new InvalidOperationException("One or more available events specified are not valid for this data entry task.");
        }

        IEnumerable<ValidationResult> ValidateAvailableEvents(
            Case @case,
            DataEntryTask dataEntryTask,
            AvailableEventModel[] availableEvents)
        {
            var isAtleastOneDateRuleViolated = dataEntryTask.AtLeastOneEventMustBeEntered &&
                                                !availableEvents.Any(
                                                                     ed => ed.DueDate.HasValue || ed.EventDate.HasValue);

            var validEventsMap = dataEntryTask.Criteria.ValidEvents.ToDictionary(ec => ec.EventId, ec => ec);
            var validEvents = isAtleastOneDateRuleViolated
                ? dataEntryTask.AvailableEvents.Select(
                                                       ae => validEventsMap.ContainsKey(ae.Event.Id)
                                                           ? validEventsMap[ae.Event.Id].Description
                                                           : ae.Event.Description).ToArray()
                : new string[0];

            foreach (var inputEvent in availableEvents)
            {
                var availableEvent = dataEntryTask.AvailableEvents.Single(ae => ae.Event.Id == inputEvent.EventId);
                var caseEvent =
                    @case.CaseEvents
                         .FirstOrDefault(ce => ce.EventNo == inputEvent.EventId && ce.Cycle == inputEvent.Cycle) ??
                    new CaseEvent(@case.Id, inputEvent.EventId, inputEvent.Cycle);

                var eventDateValidationResult = ValidateDateRule(
                                                                 @case.Id,
                                                                 dataEntryTask.Criteria.Id,
                                                                 availableEvent.Event,
                                                                 inputEvent.Cycle,
                                                                 availableEvent.EventAttribute.AsEntryAttribute(),
                                                                 inputEvent.EventDate,
                                                                 caseEvent.EventDate,
                                                                 DateLogicValidationType.EventDate,
                                                                 EventDetailInputNames.EventDate);

                if (eventDateValidationResult != null)
                    yield return eventDateValidationResult;

                var dueDateValidationResult = ValidateDateRule(
                                                               @case.Id,
                                                               dataEntryTask.Criteria.Id,
                                                               availableEvent.Event,
                                                               inputEvent.Cycle,
                                                               availableEvent.DueAttribute.AsEntryAttribute(),
                                                               inputEvent.DueDate,
                                                               caseEvent.EventDueDate,
                                                               DateLogicValidationType.DueDate,
                                                               EventDetailInputNames.DueDate);

                if (dueDateValidationResult != null)
                    yield return dueDateValidationResult;

                foreach (var validEvent in EnsureValidAccordingToDataEntryTaskAttribute(
                                                                                        dataEntryTask,
                                                                                        inputEvent,
                                                                                        validEvents,
                                                                                        isAtleastOneDateRuleViolated))
                {
                    yield return validEvent;
                }
            }
        }

        ValidationResult ValidateDateRule(
            int caseId,
            int criteriaId,
            Event @event,
            short cycle,
            EntryAttribute attribute,
            DateTime? inputDate,
            DateTime? currentDate,
            DateLogicValidationType validationType,
            string fieldId)
        {
            if (attribute.IsEditable() && inputDate.HasValue)
            {
                if (Nullable.Compare(inputDate, currentDate) != 0)
                {
                    var dateRuleViolations =
                        _datesRuleValidator.Validate(
                                                     caseId,
                                                     criteriaId,
                                                     @event.Id,
                                                     inputDate.Value,
                                                     cycle,
                                                     validationType).ToArray();
                    if (dateRuleViolations.Any())
                    {
                        return new ValidationResult("One or more date rules are violated.")
                            .WithMessageId("entryDateLogicRuleViolated")
                            .ForInput(fieldId)
                            .CorrelateWithEntity(@event)
                            .WithDetails(new
                                         {
                                             DateRuleViolations = dateRuleViolations
                                         });
                    }
                }
            }
            return null;
        }

        IEnumerable<ValidationResult> EnsureValidAccordingToDataEntryTaskAttribute(
            DataEntryTask dataEntryTask,
            AvailableEventModel entryData,
            string[] validEvents,
            bool isAtleastOneDateRuleViolated)
        {
            var availableEvent = dataEntryTask.AvailableEvents.Single(ae => ae.Event.Id == entryData.EventId);
            var eventDateEntryAttribute = availableEvent.EventAttribute.AsEntryAttribute();
            var dueDateEntryAttribute = availableEvent.DueAttribute.AsEntryAttribute();

            if (isAtleastOneDateRuleViolated)
            {
                yield return new ValidationResult("At least one date must be entered.")
                    .WithMessageId("entryAtleastOneDateRequired")
                    .CorrelateWithEntity(availableEvent.Event)
                    .WithDetails(new {Events = validEvents});
            }

            if (eventDateEntryAttribute.IsMandatory() && !entryData.EventDate.HasValue)
            {
                yield return new ValidationResult("Event Date is required")
                    .WithMessageId("entryEventDateRequired")
                    .ForInput(EventDetailInputNames.EventDate)
                    .CorrelateWithEntity(availableEvent.Event);
            }

            if (eventDateEntryAttribute.IsEditable() && entryData.EventDate.HasValue &&
                entryData.EventDate.Value > _systemClock().Date)
            {
                yield return new ValidationResult("Event Date entered is a future date", Severity.Warning)
                    .WithMessageId("entryEventDateInFuture")
                    .ForInput(EventDetailInputNames.EventDate)
                    .CorrelateWithEntity(availableEvent.Event);
            }

            if (dueDateEntryAttribute.IsMandatory() && !entryData.DueDate.HasValue)
            {
                yield return new ValidationResult("Due Date is required")
                    .WithMessageId("entryDueDateRequired")
                    .ForInput(EventDetailInputNames.DueDate)
                    .CorrelateWithEntity(availableEvent.Event);
            }

            if (dueDateEntryAttribute.IsEditable() && entryData.DueDate.HasValue &&
                entryData.DueDate.Value < _systemClock().Date)
            {
                yield return new ValidationResult("Due Date entered is not a future date", Severity.Warning)
                    .WithMessageId("entryDueDateInFuture")
                    .ForInput(EventDetailInputNames.DueDate)
                    .CorrelateWithEntity(availableEvent.Event);
            }

            if (string.IsNullOrEmpty(entryData.EventText)) yield break;

            if (!entryData.DueDate.HasValue && !entryData.EventDate.HasValue)
            {
                yield return new ValidationResult("Event text can only be entered with either an event date or a due date.")
                    .WithMessageId("entryEventTextRequiresAccompanyingDate")
                    .ForInput(EventDetailInputNames.EventText).CorrelateWithEntity(availableEvent.Event);
            }
        }

        static IEnumerable<ValidationResult> ValidateCaseLocationRecordal(Case @case, int? fileLocationId)
        {
            if (@case.CaseLocations.Any() && !fileLocationId.HasValue)
            {
                yield return new ValidationResult("File location is required")
                    .WithMessageId("entryFileLocationRequired")
                    .ForInput(EventDetailInputNames.FileLocation);
            }
        }

        void EnsureCaseLocationIsValid(int? fileLocationId)
        {
            if (fileLocationId.HasValue && !_dbContext.Set<TableCode>().Any(tc => tc.Id == fileLocationId.Value))
                throw new InvalidOperationException("File Location entered is not valid.");
        }
    }
}