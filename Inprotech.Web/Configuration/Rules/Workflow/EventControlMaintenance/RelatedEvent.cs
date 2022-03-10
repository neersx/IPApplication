using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance
{
    // Satisfying Event, Events To Update, and Events To Clear
    public class RelatedEvent : IEventSectionMaintenance
    {
        readonly IWorkflowEventInheritanceService _workflowEventInheritanceService;
        readonly IRelatedEventService _relatedEventService;

        public RelatedEvent(IWorkflowEventInheritanceService workflowEventInheritanceService, IRelatedEventService relatedEventService)
        {
            _workflowEventInheritanceService = workflowEventInheritanceService;
            _relatedEventService = relatedEventService;
        }

        public IEnumerable<ValidationError> Validate(WorkflowEventControlSaveModel newValues)
        {
            var seErrors = ValidateRelatedEvents(newValues.SatisfyingEventsDelta, "satisfyingEvent");
            if (seErrors != null) yield return seErrors;

            var etuErrors = ValidateRelatedEvents(newValues.EventsToUpdateDelta, "eventToUpdate");
            if (etuErrors != null) yield return etuErrors;

            var etcErrors = ValidateEventsToClear(newValues.EventsToClearDelta);
            if (etcErrors != null) yield return etcErrors;
        }

        public void SetChildInheritanceDelta(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            fieldsToUpdate.SatisfyingEventsDelta = _relatedEventService.GetInheritRelatedEventsDelta(fieldsToUpdate.SatisfyingEventsDelta, @event.RelatedEvents.WhereIsSatisfyingEvent(), newValues.SatisfyingEventsDelta);
            fieldsToUpdate.EventsToClearDelta = _relatedEventService.GetInheritRelatedEventsDelta(fieldsToUpdate.EventsToClearDelta, @event.RelatedEvents.WhereEventsToClear(), newValues.EventsToClearDelta);
            fieldsToUpdate.EventsToUpdateDelta = _relatedEventService.GetInheritRelatedEventsDelta(fieldsToUpdate.EventsToUpdateDelta, @event.RelatedEvents.WhereEventsToUpdate(), newValues.EventsToUpdateDelta);
        }

        public void ApplyChanges(ValidEvent @event, WorkflowEventControlSaveModel newValues, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var satisfyingEventDelta = _workflowEventInheritanceService.GetDelta(newValues.SatisfyingEventsDelta, fieldsToUpdate.SatisfyingEventsDelta, _ => _.HashKey(), _ => _.OriginalHashKey);
            var eventsToClearDelta = _workflowEventInheritanceService.GetDelta(newValues.EventsToClearDelta, fieldsToUpdate.EventsToClearDelta, _ => _.HashKey(), _ => _.OriginalHashKey);
            var eventsToUpdateDelta = _workflowEventInheritanceService.GetDelta(newValues.EventsToUpdateDelta, fieldsToUpdate.EventsToUpdateDelta, _ => _.HashKey(), _ => _.OriginalHashKey);

            _relatedEventService.ApplyRelatedEventChanges(newValues.OriginatingCriteriaId, @event, satisfyingEventDelta, newValues.ResetInheritance);
            _relatedEventService.ApplyRelatedEventChanges(newValues.OriginatingCriteriaId, @event, eventsToClearDelta, newValues.ResetInheritance);
            _relatedEventService.ApplyRelatedEventChanges(newValues.OriginatingCriteriaId, @event, eventsToUpdateDelta, newValues.ResetInheritance);
        }

        public void RemoveInheritance(ValidEvent @event, EventControlFieldsToUpdate fieldsToUpdate)
        {
            var satisfyingEventHashesToBreak = fieldsToUpdate.SatisfyingEventsDelta.Updated.Union(fieldsToUpdate.SatisfyingEventsDelta.Deleted);
            foreach (var s in @event.RelatedEvents.WhereIsSatisfyingEvent(true).Where(_ => satisfyingEventHashesToBreak.Contains(_.HashKey())))
            {
                s.IsInherited = false;
            }

            var eventsToClearHashesToBreak = fieldsToUpdate.EventsToClearDelta.Updated.Union(fieldsToUpdate.EventsToClearDelta.Deleted);
            foreach (var etc in @event.RelatedEvents.WhereEventsToClear(true).Where(_ => eventsToClearHashesToBreak.Contains(_.HashKey())))
            {
                etc.IsInherited = false;
            }

            var eventsToUpdateHashesToBreak = fieldsToUpdate.EventsToUpdateDelta.Updated.Union(fieldsToUpdate.EventsToUpdateDelta.Deleted);
            foreach (var etu in @event.RelatedEvents.WhereEventsToUpdate(true).Where(_ => eventsToUpdateHashesToBreak.Contains(_.HashKey())))
            {
                etu.IsInherited = false;
            }
        }
        
        public void Reset(WorkflowEventControlSaveModel newValues, ValidEvent parentValidEvent, ValidEvent validEvent)
        {
            // add or update
            foreach (var d in parentValidEvent.RelatedEvents)
            {
                // process Satisfying/Clear/Update event separately matching on RelatedEventId because some rows might be used for multiple sections.
                if (d.IsSatisfyingEvent)
                {
                    var satisfyingEventSaveModel = new RelatedEventRuleSaveModel();
                    satisfyingEventSaveModel.CopySatisfyingEvent(d);
                    
                    var matchedSatisfyingEvent = validEvent.RelatedEvents.WhereIsSatisfyingEvent().SingleOrDefault(_ => _.RelatedEventId == d.RelatedEventId && _.RelativeCycleId == d.RelativeCycleId);
                    if (matchedSatisfyingEvent != null)
                    {
                        satisfyingEventSaveModel.OriginalHashKey = matchedSatisfyingEvent.HashKey();
                        satisfyingEventSaveModel.OriginalRelatedEventId = matchedSatisfyingEvent.RelatedEventId.Value;
                        satisfyingEventSaveModel.OriginalRelatedCycleId = matchedSatisfyingEvent.RelativeCycleId.Value;
                        newValues.SatisfyingEventsDelta.Updated.Add(satisfyingEventSaveModel);
                    }
                    else
                    {
                        newValues.SatisfyingEventsDelta.Added.Add(satisfyingEventSaveModel);
                    }
                }

                if (d.IsClearEventRule)
                {
                    var clearEventSaveModel = new RelatedEventRuleSaveModel();
                    clearEventSaveModel.CopyEventToClear(d);

                    var matchedClearEvent = validEvent.RelatedEvents.WhereEventsToClear().SingleOrDefault(_ => _.RelatedEventId == d.RelatedEventId);
                    if (matchedClearEvent != null)
                    {
                        clearEventSaveModel.OriginalHashKey = matchedClearEvent.HashKey();
                        clearEventSaveModel.OriginalRelatedEventId = matchedClearEvent.RelatedEventId.Value;
                        newValues.EventsToClearDelta.Updated.Add(clearEventSaveModel);
                    }
                    else
                    {
                        newValues.EventsToClearDelta.Added.Add(clearEventSaveModel);
                    }
                }

                if (d.IsUpdateEvent)
                {
                    var updateEventSaveModel = new RelatedEventRuleSaveModel();
                    updateEventSaveModel.CopyEventToUpdate(d);

                    var matchedUpdateEvent = validEvent.RelatedEvents.WhereEventsToUpdate().SingleOrDefault(_ => _.RelatedEventId == d.RelatedEventId);
                    if (matchedUpdateEvent != null)
                    {
                        updateEventSaveModel.OriginalHashKey = matchedUpdateEvent.HashKey();
                        updateEventSaveModel.OriginalRelatedEventId = matchedUpdateEvent.RelatedEventId.Value;
                        newValues.EventsToUpdateDelta.Updated.Add(updateEventSaveModel);
                    }
                    else
                    {
                        newValues.EventsToUpdateDelta.Added.Add(updateEventSaveModel);
                    }
                }
            }

            // delete the rest
            var keepSatisfyingEvents = newValues.SatisfyingEventsDelta.Updated.Select(_ => _.RelatedEventId);
            var keepEventsToUpdate = newValues.EventsToUpdateDelta.Updated.Select(_ => _.RelatedEventId);
            var keepEventsToClear = newValues.EventsToClearDelta.Updated.Select(_ => _.RelatedEventId);

            var deleteSatisfyingEvents = validEvent.RelatedEvents.WhereIsSatisfyingEvent().Where(_ => !keepSatisfyingEvents.Contains(_.RelatedEventId))
                .Select(_ => new RelatedEventRuleSaveModel{ OriginalHashKey = _.HashKey(), IsSatisfyingEvent = true });
            var deleteEventsToUpdate = validEvent.RelatedEvents.WhereEventsToUpdate().Where(_ => !keepEventsToUpdate.Contains(_.RelatedEventId))
                .Select(_ => new RelatedEventRuleSaveModel { OriginalHashKey = _.HashKey(), IsUpdateEvent = true });
            var deleteEventsToClear = validEvent.RelatedEvents.WhereEventsToClear().Where(_ => !keepEventsToClear.Contains(_.RelatedEventId))
                .Select(_ => new RelatedEventRuleSaveModel { OriginalHashKey = _.HashKey(), IsClearEvent = true }); // set at least one clear flag on so delete will pick it up

            newValues.SatisfyingEventsDelta.Deleted.AddRange(deleteSatisfyingEvents);
            newValues.EventsToUpdateDelta.Deleted.AddRange(deleteEventsToUpdate);
            newValues.EventsToClearDelta.Deleted.AddRange(deleteEventsToClear);
        }

        static ValidationError ValidateRelatedEvents(Delta<RelatedEventRuleSaveModel> delta, string type)
        {
            if (delta == null) throw new ArgumentNullException(nameof(delta));
            if (delta.Added.Union(delta.Updated).Any(_ => _.RelatedEventId == null || _.RelativeCycleId == null))
            {
                return ValidationErrors.TopicError(type, "Mandatory field was empty.");
            }

            return null;
        }

        static ValidationError ValidateEventsToClear(Delta<RelatedEventRuleSaveModel> eventsToClearDelta)
        {
            if (eventsToClearDelta == null) throw new ArgumentNullException(nameof(eventsToClearDelta));
            if (eventsToClearDelta.Added.Union(eventsToClearDelta.Updated).Any(_ => _.RelatedEventId == null || _.RelativeCycleId == null || !(_.ClearDueDateOnDueDateChange || _.ClearDueDateOnEventChange || _.ClearEventOnDueDateChange || _.ClearEventOnEventChange)))
                return ValidationErrors.TopicError("eventsToClear", "Mandatory field was empty.");

            return null;
        }
    }
}