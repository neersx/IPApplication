using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance
{
    public class ReminderAndDocument : IEventSectionMaintenance
    {
        readonly IWorkflowEventInheritanceService _workflowEventInheritanceService;

        public ReminderAndDocument(IWorkflowEventInheritanceService workflowEventInheritanceService)
        {
            _workflowEventInheritanceService = workflowEventInheritanceService;
        }

        public IEnumerable<ValidationError> Validate(WorkflowEventControlSaveModel newValues)
        {
            var reminderError = ValidateReminders(newValues.ReminderRuleDelta);
            if (reminderError != null)
                yield return reminderError;

            var documentError = ValidateDocuments(newValues.DocumentDelta);
            if (documentError != null)
                yield return documentError;
        }

        ValidationError ValidateReminders(Delta<ReminderRuleSaveModel> reminderRuleDelta)
        {
            if (reminderRuleDelta == null) throw new ArgumentNullException(nameof(reminderRuleDelta));
            if (reminderRuleDelta.Added.Union(reminderRuleDelta.Updated)
                                 .Any(_ => string.IsNullOrWhiteSpace(_.Message1) ||
                                           (_.SendEmail && string.IsNullOrWhiteSpace(_.EmailSubject)) ||
                                           _.LeadTime == null || string.IsNullOrWhiteSpace(_.PeriodType) || _.Frequency == null || string.IsNullOrWhiteSpace(_.FreqPeriodType) ||
                                           (_.EmployeeFlag.GetValueOrDefault() == 0 && _.SignatoryFlag.GetValueOrDefault() == 0 && _.CriticalFlag.GetValueOrDefault() == 0 && _.RemindEmployeeId == null && string.IsNullOrWhiteSpace(_.NameTypeId) && string.IsNullOrWhiteSpace(_.ExtendedNameType))
                                     ))
            {
                return ValidationErrors.TopicError("reminders", "Mandatory field was empty.");
            }

            return null;
        }

        ValidationError ValidateDocuments(Delta<ReminderRuleSaveModel> d)
        {
            if (d == null) throw new ArgumentNullException(nameof(d));
            if (d.Added.Union(d.Updated)
                 .Any(_ =>
                          _.LetterNo == null ||
                          (_.UpdateEvent == null && (_.LeadTime == null || string.IsNullOrEmpty(_.PeriodType))) ||
                          (_.LetterFeeId != null && (string.IsNullOrEmpty(_.PayFeeCode) ? "0" : _.PayFeeCode) == "0" && _.EstimateFlag.GetValueOrDefault() == 0 && !_.DirectPayFlag.GetValueOrDefault())
                     ))
            {
                return ValidationErrors.TopicError("documents", "Mandatory field was empty.");
            }

            return null;
        }

        public void SetChildInheritanceDelta(ValidEvent childEvent, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            fieldsToUpdate.ReminderRulesDelta = _workflowEventInheritanceService.GetInheritDelta(() => fieldsToUpdate.ReminderRulesDelta, childEvent.ReminderRuleHashList);
            fieldsToUpdate.DocumentsDelta = _workflowEventInheritanceService.GetInheritDelta(() => fieldsToUpdate.DocumentsDelta, childEvent.DocumentsHashList);
        }

        public void ApplyChanges(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var reminderRulesDelta = _workflowEventInheritanceService.GetDelta(newValues.ReminderRuleDelta, fieldsToUpdate.ReminderRulesDelta, _ => _.HashKey(), _ => _.OriginalHashKey);
            var documentRulesDelta = _workflowEventInheritanceService.GetDelta(newValues.DocumentDelta, fieldsToUpdate.DocumentsDelta, _ => _.HashKey(), _ => _.OriginalHashKey);

            ApplyReminderRuleChanges(newValues.OriginatingCriteriaId, @event, reminderRulesDelta, newValues.ResetInheritance);
            ApplyReminderRuleChanges(newValues.OriginatingCriteriaId, @event, documentRulesDelta, newValues.ResetInheritance);

            if (reminderRulesDelta.AllDeltas().WhereReminder().Any())
                ApplyReminderRuleReordering(@event);
        }

        void ApplyReminderRuleReordering(ValidEvent eventControl)
        {
            var newOrder = eventControl.Reminders.WhereReminder().OrderByDescending(_ => _.LeadTimeToDays())
                                       .Select(_ => new ReminderRule(eventControl, _.Sequence).CopyFrom(_, _.IsInherited)).ToList();

            var index = 0;
            foreach (var r in eventControl.Reminders.WhereReminder().OrderBy(_ => _.Sequence))
            {
                r.CopyFrom(newOrder[index], newOrder[index].IsInherited);
                index++;
            }
        }

        // Apply Reminder or Document Changes
        void ApplyReminderRuleChanges(int originatingCriteriaId, ValidEvent eventControl, Delta<ReminderRuleSaveModel> delta, bool forceInheritance)
        {
            var isParentCriteria = eventControl.CriteriaId == originatingCriteriaId;
            var isInherited = !isParentCriteria || forceInheritance;
            if (delta?.Added?.Any() == true)
            {
                if (eventControl.ReminderRuleHashList().Intersect(delta.Added.Select(_ => _.HashKey())).Any())
                    throw new InvalidOperationException($"Error attempting to add duplicate reminder rule on criteria {eventControl.CriteriaId}.");

                if (eventControl.DocumentsHashList().Intersect(delta.Added.Select(_ => _.HashKey())).Any())
                    throw new InvalidOperationException($"Error attempting to add duplicate document on criteria {eventControl.CriteriaId}.");

                var seq = eventControl.Reminders?.Any() == true ? (short)(eventControl.Reminders.Max(_ => _.Sequence) + 1) : (short)0;
                var addedItems = delta.Added;

                foreach (var addedItem in addedItems)
                {
                    var newReminderRule = new ReminderRule(eventControl, seq);
                    newReminderRule.CopyFrom(addedItem, isInherited);
                    eventControl.Reminders?.Add(newReminderRule);
                    seq++;
                }
            }

            if (delta?.Updated?.Any() == true)
            {
                foreach (var updatedItem in delta.Updated)
                {
                    var reminderRule = eventControl.Reminders?.SingleOrDefault(_ => (isParentCriteria || _.IsInherited) && _.HashKey() == updatedItem.OriginalHashKey);
                    reminderRule?.CopyFrom(updatedItem, isInherited);
                }
            }

            if (delta?.Deleted?.Any() == true)
            {
                foreach (var deletedItem in delta.Deleted)
                {
                    var reminderRule = eventControl.Reminders?.SingleOrDefault(_ => (isParentCriteria || _.IsInherited) && _.HashKey() == deletedItem.OriginalHashKey);

                    if (reminderRule != null)
                        eventControl.Reminders.Remove(reminderRule);
                }
            }
        }

        public void RemoveInheritance(ValidEvent @event, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var reminderRulesToBreak = fieldsToUpdate.ReminderRulesDelta.AllUpdatedAndDeletedDeltas().Union(fieldsToUpdate.DocumentsDelta.AllUpdatedAndDeletedDeltas());
            foreach (var s in @event.Reminders.Where(_ => _.IsInherited && reminderRulesToBreak.Contains(_.HashKey())))
            {
                s.IsInherited = false;
            }
        }

        public void Reset(WorkflowEventControlSaveModel newValues, ValidEvent parentValidEvent, ValidEvent validEvent)
        {
            // added or updated
            foreach (var d in parentValidEvent.Reminders)
            {
                var saveModel = new ReminderRuleSaveModel();
                saveModel.InheritRuleFrom(d);
                var matched = validEvent.Reminders.SingleOrDefault(_ => _.HashKey() == d.HashKey());
                if (matched != null)
                {
                    saveModel.OriginalHashKey = matched.HashKey();
                    if (saveModel.IsReminderRule())
                        newValues.ReminderRuleDelta.Updated.Add(saveModel);
                    else
                        newValues.DocumentDelta.Updated.Add(saveModel);
                }
                else
                {
                    if (saveModel.IsReminderRule())
                        newValues.ReminderRuleDelta.Added.Add(saveModel);
                    else
                        newValues.DocumentDelta.Added.Add(saveModel);
                }
            }

            // delete the rest
            var keepHashKeys = newValues.ReminderRuleDelta.Updated
                                    .Union(newValues.DocumentDelta.Updated).Select(_ => _.HashKey());
            var deletes = validEvent.Reminders.Where(_ => !keepHashKeys.Contains(_.HashKey()));

            foreach (var d in deletes)
            {
                var delete = new ReminderRuleSaveModel {OriginalHashKey = d.HashKey()};
                delete.CopyFrom(d);
                if (d.IsReminderRule())
                    newValues.ReminderRuleDelta.Deleted.Add(delete);
                else
                    newValues.DocumentDelta.Deleted.Add(delete);
            }
        }
    }
}
