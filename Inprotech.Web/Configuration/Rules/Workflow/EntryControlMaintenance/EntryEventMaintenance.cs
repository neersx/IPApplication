using System.Collections.Generic;
using System.Linq;
using AutoMapper;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Validations;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance
{
    public class EntryEventMaintenance : ISectionMaintenance, IReorderableSection
    {
        readonly IChangeTracker _changeTracker;
        readonly IMapper _mapper;

        public EntryEventMaintenance(IMapper mapper, IChangeTracker changeTracker)
        {
            _mapper = mapper;
            _changeTracker = changeTracker;
        }

        public void UpdateDisplayOrder(DataEntryTask entry, EntryControlRecordMovements movements)
        {
            if (!movements.EntryEventsMoved.Any())
                return;

            ApplyNewDisplayOrder(entry, movements);
            SetNextEvents(entry, movements.EntryEventsMoved);
        }

        public bool PropagateDisplayOrder(EntryReorderSouce source, DataEntryTask target, EntryControlRecordMovements movements)
        {
            if (!movements.EntryEventsMoved.Any()) return false;

            if (!target.AvailableEvents.Any()) return false;

            var sourceEvents = source.EventsInDisplayOrder().Select(_ => _.EventId).ToArray();

            var targetEvents = target.EventsInDisplayOrder().Select(_ => _.EventId).ToArray();

            var common = sourceEvents.Intersect(targetEvents).ToArray();

            if (!common.Any()) return false;

            var orderedSourceCommon = sourceEvents.Where(common.Contains).ToArray();

            var orderedTargetCommon = targetEvents.Where(common.Contains).ToArray();

            if (!orderedSourceCommon.SequenceEqual(orderedTargetCommon)) return false;

            return ApplyNewDisplayOrder(target, movements);
        }

        public IEnumerable<ValidationError> Validate(DataEntryTask entry, WorkflowEntryControlSaveModel newValues)
        {
            var duplicateEvents = DuplicateEventsinAddedEvents(entry, newValues.EntryEventDelta.Added).Union(DuplicateEventsDueToUpdatedEvents(entry, newValues.EntryEventDelta.Updated)).ToArray();
            if (!duplicateEvents.Any())
                yield break;

            foreach (var duplicateEvent in duplicateEvents)
            {
                yield return ValidationErrors.NotUnique("details", "entryEvents", duplicateEvent);
            }
        }
        
        public void SetDeltaForUpdate(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var currentEventIds = entry.AvailableEvents.Select(_ => _.EventId).ToArray();
            var currentInheritedEventIds = entry.AvailableEvents.Where(_ => _.IsInherited).Select(_ => _.EventId).ToArray();

            fieldsToUpdate.EntryEventsDelta.Added = fieldsToUpdate.EntryEventsDelta.Added.Except(currentEventIds).ToArray();
            fieldsToUpdate.EntryEventsDelta.Deleted = fieldsToUpdate.EntryEventsDelta.Deleted.Intersect(currentInheritedEventIds).ToArray();

            var updatedEventsAlreadyPresent = newValues.EntryEventDelta.Updated
                                                       .Where(_ => _.PreviousEventId.HasValue && isEventModified(_))
                                                       .Where(_ => currentEventIds.Contains(_.EventId))
                                                       .Select(_ => _.PreviousEventId)
                                                       .Cast<int>()
                                                       .ToArray();

            var updatesApplicable = fieldsToUpdate.EntryEventsDelta.Updated
                                                  .Intersect(currentInheritedEventIds)
                                                  .Except(updatedEventsAlreadyPresent)
                                                  .ToArray();

            fieldsToUpdate.EntryEventRemoveInheritanceFor = fieldsToUpdate.EntryEventsDelta.Updated.Except(updatesApplicable).ToArray();
            fieldsToUpdate.EntryEventsDelta.Updated = updatesApplicable;
        }

        public void ApplyChanges(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            ApplyDelete(entry, newValues, fieldsToUpdate);

            ApplyUpdates(entry, newValues, fieldsToUpdate);

            ApplyAdditions(entry, newValues, fieldsToUpdate);
        }

        public void RemoveInheritance(DataEntryTask entry, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            foreach (var removeInheritanceFor in fieldsToUpdate.EntryEventsDelta.Updated.Union(fieldsToUpdate.EntryEventsDelta.Deleted))
            {
                var eventToUpdate = entry.AvailableEvents.Where(_ => removeInheritanceFor == _.EventId).SingleOrDefault(_ => _.IsInherited);
                if (eventToUpdate == null)
                    continue;

                eventToUpdate.IsInherited = false;
            }
        }

        public void Reset(DataEntryTask entryToReset, DataEntryTask parentEntry, WorkflowEntryControlSaveModel newValues)
        {
            foreach (var a in parentEntry.AvailableEvents)
            {
                var saveModel = new EntryEventDelta
                {
                    EventId = a.EventId,
                    EventAttribute = a.EventAttribute,
                    DueAttribute = a.DueAttribute,
                    PolicingAttribute = a.PolicingAttribute,
                    DueDateResponsibleNameAttribute = a.DueDateResponsibleNameAttribute,
                    OverrideDueAttribute = a.OverrideDueAttribute,
                    OverrideEventAttribute = a.OverrideEventAttribute,
                    PeriodAttribute = a.PeriodAttribute,
                    AlsoUpdateEventId = a.AlsoUpdateEventId,
                    OverrideDisplaySequence = a.DisplaySequence
                };

                if (entryToReset.AvailableEvents.Any(_ => _.EventId == a.EventId))
                {
                    saveModel.PreviousEventId = a.EventId;
                    newValues.EntryEventDelta.Updated.Add(saveModel);
                }
                else
                {
                    newValues.EntryEventDelta.Added.Add(saveModel);
                }
            }

            var keep = newValues.EntryEventDelta.Updated.Select(_ => _.EventId);
            var deletes = entryToReset.AvailableEvents.Where(_ => !keep.Contains(_.EventId))
                                      .Select(_ => new EntryEventDelta { EventId = _.EventId });
            newValues.EntryEventDelta.Deleted.AddRange(deletes);
        }

        void ApplyAdditions(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var isUpdatingChildCriteria = Helper.IsUpdateForChildCriteria(entry, newValues);

            foreach (var newEvent in newValues.EntryEventDelta.Added.Where(_ => fieldsToUpdate.EntryEventsDelta.Added.Contains(_.EventId)))
            {
                if (entry.AvailableEvents.Any(_ => newEvent.EventId == _.EventId))
                    continue;

                var displaySeq = newEvent.OverrideDisplaySequence ?? (entry.AvailableEvents.Any() ? entry.AvailableEvents.Max(_ => _.DisplaySequence) + 1 : 1);
                if (newEvent.RelativeEventId.HasValue)
                {
                    var relatedEvent = entry.AvailableEvents.SingleOrDefault(_ => _.EventId == newEvent.RelativeEventId.Value);
                    if (relatedEvent != null)
                    {
                        displaySeq = relatedEvent.DisplaySequence + 1;
                        PushEventsDown(entry, displaySeq);
                    }
                }

                var newEntryEvent = _mapper.Map<AvailableEvent>(newEvent);
                newEntryEvent.DisplaySequence = (short?) displaySeq;
                newEntryEvent.IsInherited = isUpdatingChildCriteria || newValues.ResetInheritance;
                entry.AvailableEvents.Add(newEntryEvent);
            }
        }

        void ApplyUpdates(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var isUpdatingChildCriteria = Helper.IsUpdateForChildCriteria(entry, newValues);
            var eventsToBeAdded = new List<AvailableEvent>();

            foreach (var updatedEvent in newValues.EntryEventDelta.Updated.Where(_ => fieldsToUpdate.EntryEventsDelta.Updated.Contains(_.PreviousEventId.Value)))
            {
                var eventToUpdateQuery = entry.AvailableEvents.Where(_ => updatedEvent.PreviousEventId == _.EventId);

                var eventToUpdate = (isUpdatingChildCriteria ? eventToUpdateQuery.Where(_ => _.IsInherited) : eventToUpdateQuery).SingleOrDefault();

                if (eventToUpdate == null)
                    continue;

                //New entity created, since its primary key change and EF does not like updating primary key directly
                var modifiedEntity = isEventModified(updatedEvent) ? GetNewEntity(entry, eventToUpdate) : eventToUpdate;

                _mapper.Map(updatedEvent, modifiedEntity);

                if (isEventModified(updatedEvent))
                {
                    eventsToBeAdded.Add(modifiedEntity);
                }
                
                if (!isUpdatingChildCriteria)
                    modifiedEntity.IsInherited = newValues.ResetInheritance;

                if (updatedEvent.OverrideDisplaySequence.HasValue)
                    eventToUpdate.DisplaySequence = updatedEvent.OverrideDisplaySequence.Value;
            }

            if (eventsToBeAdded.Count > 0)
            {
                //Add all new entities in one shot
                //if user has swapped event numbers for two records it will give error, if updates are applied while in loop
                entry.AvailableEvents.AddRange(eventsToBeAdded.ToArray());
            }

            foreach (var eventId in fieldsToUpdate.EntryEventRemoveInheritanceFor)
            {
                var eventToUpdate = entry.AvailableEvents.SingleOrDefault(_ => _.EventId == eventId && _.IsInherited);
                if (eventToUpdate != null)
                    eventToUpdate.IsInherited = false;
            }
        }

        bool isEventModified(EntryEventDelta updatedEntryEvent)
        {
            return updatedEntryEvent.EventId != updatedEntryEvent.PreviousEventId;
        }

        AvailableEvent GetNewEntity(DataEntryTask entry, AvailableEvent eventToUpdate)
        {
            entry.AvailableEvents.Remove(eventToUpdate);
            return eventToUpdate.CreateCopy();
        }

        void PushEventsDown(DataEntryTask entry, int? from)
        {
            foreach (var entryAvailableEvent in entry.AvailableEvents.Where(_ => _.DisplaySequence >= from))
            {
                entryAvailableEvent.DisplaySequence++;
            }
        }

        static IEnumerable<int> DuplicateEventsinAddedEvents(DataEntryTask entryToUpdate, IEnumerable<EntryEventDelta> addedEvents)
        {
            var entryEventDeltas = addedEvents as EntryEventDelta[] ?? addedEvents.ToArray();
            foreach (var newEvent in entryEventDeltas)
            {
                if (entryToUpdate.AvailableEvents.Any(_ => _.EventId == newEvent.EventId))
                    yield return newEvent.EventId;
            }
        }

        IEnumerable<int> DuplicateEventsDueToUpdatedEvents(DataEntryTask entryToUpdate, IEnumerable<EntryEventDelta> updatedEvents)
        {
            var entryEventDeltas = updatedEvents as EntryEventDelta[] ?? updatedEvents.ToArray();
            foreach (var updatedEvent in entryEventDeltas)
            {
                if (!updatedEvent.PreviousEventId.HasValue || !isEventModified(updatedEvent))
                    continue;

                if (entryEventDeltas.Count(_ => _.EventId == updatedEvent.EventId) > 1)
                    yield return updatedEvent.PreviousEventId.Value;

                if (entryToUpdate.AvailableEvents.Any(_ => _.EventId == updatedEvent.EventId))
                    yield return updatedEvent.EventId;
            }
        }

        void ApplyDelete(DataEntryTask entry, WorkflowEntryControlSaveModel newValues, EntryControlFieldsToUpdate fieldsToUpdate)
        {
            var allDeletedEvents = newValues.EntryEventDelta.Deleted.Where(_ => fieldsToUpdate.EntryEventsDelta.Deleted.Contains(_.EventId));
            foreach (var deleted in allDeletedEvents)
            {
                var @event = entry.AvailableEvents.FirstOrDefault(_ => _.EventId == deleted.EventId);
                if (@event == null) continue;

                entry.AvailableEvents.Remove(@event);
            }
        }

        bool ApplyNewDisplayOrder(DataEntryTask entry, EntryControlRecordMovements movements)
        {
            var entryEvents = entry.AvailableEvents.ToDictionary(_ => _.EventId, _ => _);

            var min = entry.EventsInDisplayOrder().DefaultIfEmpty().Min(_ => _.DisplaySequence ?? 0);

            var hasChanged = false;

            foreach (var m in movements.EntryEventsMoved)
            {
                AvailableEvent target;
                if (!entryEvents.TryGetValue(m.EventId, out target))
                    continue;

                if (!m.PrevEventId.HasValue)
                {
                    if (target.DisplaySequence != min)
                        PushEventsDown(entry, min);

                    target.DisplaySequence = min;
                }
                else
                {
                    int displaySequence = 0;
                    AvailableEvent prev,next;
                    if (!entryEvents.TryGetValue(m.PrevEventId.Value, out prev))
                    {
                        if (!m.NextEventId.HasValue || !entryEvents.TryGetValue(m.NextEventId.Value, out next))
                            continue;
                        displaySequence = next.DisplaySequence.GetValueOrDefault();
                    }
                    else
                    {
                        displaySequence = prev.DisplaySequence.GetValueOrDefault() + 1;
                    }

                    PushEventsDown(entry, (short)displaySequence);
                    target.DisplaySequence = (short)displaySequence;
                }

                if (!hasChanged)
                {
                    hasChanged = _changeTracker.HasChanged(target);
                }

                entry.ResequenceEvents();
            }

            return hasChanged;
        }
        void SetNextEvents(DataEntryTask entry, IEnumerable<EntryEventMovements> entryEventsMoved)
        {
            var eventIds = entry.EventsInDisplayOrder().Select(_ => _.EventId).ToList();
            foreach (var @event in entryEventsMoved)
            {
                if (@event.NextEventId.HasValue) continue;
                var targetIndex = eventIds.IndexOf(@event.EventId);
                @event.NextEventId = targetIndex < eventIds.Count - 1 ? eventIds[targetIndex + 1] : (int?)null;
            }
        }
    }
}