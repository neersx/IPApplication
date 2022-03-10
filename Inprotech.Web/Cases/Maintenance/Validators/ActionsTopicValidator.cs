using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.BatchEventUpdate.DataEntryTaskHandlers;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Components.Cases.Rules;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Cases.Maintenance.Validators
{
    public class ActionsTopicValidator : ITopicValidator<Case>
    {
        readonly IDbContext _dbContext;
        readonly IDateRuleValidator _datesRuleValidator;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public ActionsTopicValidator(IDbContext dbContext, ITaskSecurityProvider taskSecurityProvider, IDateRuleValidator datesRuleValidator)
        {
            _taskSecurityProvider = taskSecurityProvider;
            _dbContext = dbContext;
            _datesRuleValidator = datesRuleValidator;
        }

        public IEnumerable<ValidationError> Validate(JObject topicData, MaintenanceSaveModel model, Case @case)
        {
            if (!_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseEvent))
            {
                yield return ValidationErrors.TopicError(KnownCaseMaintenanceTopics.Actions, "You do not have permission to modify Event Dates.");
                yield break;
            }

            var topic = topicData.ToObject<EventTopicSaveModel>();
            var dbCaseEvents = @case.CaseEvents.ToList();
            foreach (var ev in topic.Rows)
            {
                var eventIdentifier = $"{ev.EventNo}-{ev.Cycle?.ToString() ?? string.Empty}";
                var caseEvent = dbCaseEvents.FirstOrDefault(x => x.EventNo == ev.EventNo && ev.Cycle == x.Cycle);

                if (caseEvent != null)
                {
                    var removingEventDate = caseEvent.EventDate.HasValue && !ev.EventDate.HasValue;
                    if (removingEventDate && !_taskSecurityProvider.HasAccessTo(ApplicationTask.ClearCaseEventDates))
                    {
                        yield return ValidationErrors.SetError(KnownCaseMaintenanceTopics.Actions, EventDetailInputNames.EventDate, "You do not have permission to clear Event Dates.  Please contact your System Administrator", true, eventIdentifier);
                    }

                    if (!string.IsNullOrWhiteSpace(ev.NameTypeKey) && ev.NameId.HasValue)
                    {
                        yield return ValidationErrors.SetError(KnownCaseMaintenanceTopics.Actions, EventDetailInputNames.Name, "Name type key and name can't be both populated", true, eventIdentifier);
                        yield return ValidationErrors.SetError(KnownCaseMaintenanceTopics.Actions, EventDetailInputNames.NameType, "Name type key and name can't be both populated", true, eventIdentifier);
                    }

                    foreach (var validationError1 in ValidatedDateRules(@case, ev, eventIdentifier))
                        yield return validationError1;
                }
            }
        }

        IEnumerable<ValidationError> ValidatedDateRules(Case @case, EventSaveModel ev, string eventIdentifier)
        {
            var eventDateValidationResult = ValidateDateRule(@case.Id, ev.CriteriaId, ev.EventNo,
                                                             (short)(ev.Cycle ?? 1),
                                                             EntryAttribute.EntryOptional,
                                                             ev.EventDate,
                                                             DateLogicValidationType.EventDate,
                                                             EventDetailInputNames.EventDate, eventIdentifier);

            if (eventDateValidationResult != null)
            {
                foreach (var result in eventDateValidationResult)
                {
                    yield return result;
                }
            }

            var dueDateValidationResult = ValidateDateRule(@case.Id, ev.CriteriaId, ev.EventNo,
                                                           (short)(ev.Cycle ?? 1),
                                                           EntryAttribute.EntryOptional,
                                                           ev.EventDueDate,
                                                           DateLogicValidationType.DueDate,
                                                           EventDetailInputNames.DueDate, eventIdentifier);

            if (dueDateValidationResult != null)
            {
                foreach (var result in dueDateValidationResult)
                {
                    yield return result;

                }
            }
        }

        IEnumerable<ValidationError> ValidateDateRule(
        int caseId,
        int criteriaId,
        int eventNo,
        short cycle,
        EntryAttribute attribute,
        DateTime? inputDate,
        DateLogicValidationType validationType,
        string fieldId, string eventIdentifier)
        {
            if (attribute.IsEditable() && inputDate.HasValue)
            {

                var dateRuleViolations =
                    _datesRuleValidator.Validate(
                                                 caseId,
                                                 criteriaId,
                                                 eventNo,
                                                 inputDate.Value,
                                                 cycle,
                                                 validationType).ToArray();
                if (dateRuleViolations.Any())
                {
                    return dateRuleViolations.Select(violation => ValidationErrors.SetError(KnownCaseMaintenanceTopics.Actions, fieldId, violation.Message, true, eventIdentifier, violation.IsInvalid ? Severity.Error : Severity.Warning));
                }

            }
            return null;
        }
    }
}