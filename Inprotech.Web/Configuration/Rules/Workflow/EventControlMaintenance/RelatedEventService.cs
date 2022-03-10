using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance
{
    public interface IRelatedEventService
    {
        Delta<int> GetInheritRelatedEventsDelta(Delta<int> fieldsToUpdateDelta, IEnumerable<RelatedEventRule> existingRules, Delta<RelatedEventRuleSaveModel> newValues);
        void ApplyRelatedEventChanges(int originatingCriteriaId, ValidEvent eventControl, Delta<RelatedEventRuleSaveModel> relatedEventDelta, bool forceInheritance);
    }

    public class RelatedEventService : IRelatedEventService
    {
        public Delta<int> GetInheritRelatedEventsDelta(Delta<int> fieldsToUpdateDelta, IEnumerable<RelatedEventRule> existingRules, Delta<RelatedEventRuleSaveModel> newValues)
        {
            var conflictingEventRules = new RelatedEventRuleSaveModel[0];

            var applicableAdditions = newValues.Added.Where(_ => fieldsToUpdateDelta.Added.Contains(_.HashKey()));
            var applicableUpdates = newValues.Updated.Where(_ => fieldsToUpdateDelta.Updated.Contains(_.OriginalHashKey));

            var rulesWithNewKey = applicableAdditions.Union(applicableUpdates.Where(_ => _.HasEventChanged)).ToArray();
            var relatedEventRules = existingRules as RelatedEventRule[] ?? existingRules.ToArray();

            if (rulesWithNewKey.Any())
            {
                var conflictableRuleIds = relatedEventRules.Select(_ => new {_.RelatedEventId.Value, _.RelativeCycleId}).ToArray();

                // don't add/update the related event to one that already exist in the child
                if (rulesWithNewKey.AreSatisfyingEvents())
                {
                    conflictingEventRules = (from r in rulesWithNewKey
                                             join c in conflictableRuleIds on new {r.RelatedEventId.Value, RelativeCycleId = (short?) r.RelativeCycleId.Value} equals c
                                             select r).ToArray();

                    foreach (var c in relatedEventRules.Where(_ => conflictingEventRules.Select(c => new {RelativeEventId = c.OriginalRelatedEventId, RelativeCycle = c.OriginalRelatedCycleId}).Contains(new {RelativeEventId = _.RelatedEventId.Value, RelativeCycle = _.RelativeCycleId})))
                    {
                        c.IsInherited = false;
                    }
                }
                else
                {
                    conflictingEventRules = (from r in rulesWithNewKey
                                             join c in conflictableRuleIds on r.RelatedEventId.Value equals c.Value
                                             select r).ToArray();

                    foreach (var c in relatedEventRules.Where(_ => conflictingEventRules.Select(c => c.OriginalRelatedEventId).Contains(_.RelatedEventId.Value)))
                    {
                        c.IsInherited = false;
                    }
                }
            }

            return new Delta<int>
            {
                Added = fieldsToUpdateDelta.Added.Except(conflictingEventRules.Select(_ => _.HashKey())).ToArray(),
                Updated = fieldsToUpdateDelta.Updated.Except(conflictingEventRules.Select(_ => _.OriginalHashKey)).Intersect(relatedEventRules.HashList(true)).ToArray(),
                Deleted = fieldsToUpdateDelta.Deleted.Intersect(relatedEventRules.HashList(true)).ToArray()
            };
        }

        public void ApplyRelatedEventChanges(int originatingCriteriaId, ValidEvent eventControl, Delta<RelatedEventRuleSaveModel> relatedEventDelta, bool forceInheritance)
        {
            var isParentCriteria = eventControl.CriteriaId == originatingCriteriaId;
            var isInherited = !isParentCriteria || forceInheritance;

            if (relatedEventDelta?.Added?.Any() == true)
            {
                var seq = eventControl.RelatedEvents != null && eventControl.RelatedEvents.Any() ? (short) (eventControl.RelatedEvents.Max(_ => _.Sequence) + 1) : (short) 0;

                if (eventControl.SatisfyingEventIds().Intersect(relatedEventDelta.Added.WhereIsSatisfyingEvent().Select(_ => new {RelatedEventId = _.RelatedEventId.Value, RelativeCycle = _.RelativeCycleId})).Any())
                    throw new InvalidOperationException($"Error attempting to add duplicate satisfying event on criteria {eventControl.CriteriaId}.");

                if (eventControl.EventToClearIds().Intersect(relatedEventDelta.Added.WhereEventsToClear().Select(_ => _.RelatedEventId.Value)).Any())
                    throw new InvalidOperationException($"Error attempting to add duplicate clear event on criteria {eventControl.CriteriaId}.");

                if (eventControl.EventToUpdateIds().Intersect(relatedEventDelta.Added.WhereEventsToUpdate().Select(_ => _.RelatedEventId.Value)).Any())
                    throw new InvalidOperationException($"Error attempting to add duplicate update event on criteria {eventControl.CriteriaId}.");

                foreach (var addedItem in relatedEventDelta.Added)
                {
                    AddRelatedEvent(eventControl, seq, isInherited, addedItem);
                    seq++;
                }
            }

            if (relatedEventDelta?.Updated?.Any() == true)
            {
                foreach (var updatedItem in relatedEventDelta.Updated)
                {
                    if (eventControl.RelatedEvents.IsDuplicateRelatedRule(updatedItem))
                    {
                        throw new InvalidOperationException($"Error attempting to add duplicate update event on criteria {eventControl.CriteriaId}.");
                    }

                    var relatedEvents = GetRelatedEvents(eventControl, updatedItem);
                    var relatedEvent = relatedEvents?.SingleOrDefault(_ => (isParentCriteria || _.IsInherited) && _.HashKey() == updatedItem.OriginalHashKey);

                    UpdateRelatedEventRule(relatedEvent, isInherited, updatedItem);
                }
            }

            if (relatedEventDelta?.Deleted?.Any() == true)
            {
                foreach (var deletedItem in relatedEventDelta.Deleted)
                {
                    var relatedEvents = GetRelatedEvents(eventControl, deletedItem);
                    var relatedEvent = relatedEvents?.FirstOrDefault(_ => (isParentCriteria || _.IsInherited) && _.HashKey() == deletedItem.OriginalHashKey);

                    DeleteRelatedEventRule(relatedEvent, deletedItem);
                }
            }
        }

        static IEnumerable<RelatedEventRule> GetRelatedEvents(ValidEvent eventControl, RelatedEventRuleSaveModel updatedItem)
        {
            IEnumerable<RelatedEventRule> relatedEvents = null;

            if (updatedItem.IsSatisfyingEvent)
                relatedEvents = eventControl.RelatedEvents?.WhereIsSatisfyingEvent();
            else if (updatedItem.IsClearEventRule)
                relatedEvents = eventControl.RelatedEvents?.WhereEventsToClear();
            else if (updatedItem.IsUpdateEvent)
                relatedEvents = eventControl.RelatedEvents?.WhereEventsToUpdate();

            return relatedEvents;
        }

        static void UpdateRelatedEventRule(RelatedEventRule existingRule, bool isInherited, RelatedEventRuleSaveModel updatedItem)
        {
            if (existingRule == null) return;
            if (existingRule.IsMultiuse())
            {
                // row also has a clear / update event rule. Split satisfying event to a new row.
                RemovePartialRelatedEventRule(existingRule, updatedItem);
                AddRelatedEvent(existingRule.ValidEvent, (short) (existingRule.ValidEvent.RelatedEvents.Max(_ => _.Sequence) + 1), isInherited, updatedItem);
            }
            else
            {
                CopyRelatedEvent(existingRule, updatedItem, isInherited);
            }
        }

        static void DeleteRelatedEventRule(RelatedEventRule existingRule, RelatedEventRuleSaveModel deletedRule)
        {
            if (existingRule == null) return;
            if (existingRule.IsMultiuse())
                RemovePartialRelatedEventRule(existingRule, deletedRule);
            else
                existingRule.ValidEvent.RelatedEvents.Remove(existingRule);
        }

        static void RemovePartialRelatedEventRule(RelatedEventRule existingRule, RelatedEventRuleSaveModel removeRule)
        {
            if (removeRule.IsSatisfyingEvent)
            {
                existingRule.IsSatisfyingEvent = false;
            }
            else if (removeRule.IsClearEventRule)
            {
                existingRule.ClearDue = 0;
                existingRule.ClearEvent = 0;
                existingRule.ClearDueOnDueChange = false;
                existingRule.ClearEventOnDueChange = false;
            }
            else if (removeRule.IsUpdateEvent)
            {
                existingRule.IsUpdateEvent = false;
                existingRule.DateAdjustmentId = null;
            }
        }

        static void AddRelatedEvent(ValidEvent eventControl, short seq, bool isInherited, RelatedEventRuleSaveModel addedItem)
        {
            if (eventControl.RelatedEvents.IsDuplicateRelatedRule(addedItem))
            {
                throw new InvalidOperationException($"Error attempting to add duplicate update event on criteria {eventControl.CriteriaId}.");
            }

            var rule = new RelatedEventRule(eventControl, seq);
            CopyRelatedEvent(rule, addedItem, isInherited);
            eventControl.RelatedEvents?.Add(rule);
        }

        static void CopyRelatedEvent(RelatedEventRule existingRule, RelatedEventRuleSaveModel updatedRule, bool isInherited)
        {
            if (updatedRule.IsSatisfyingEvent)
                existingRule.CopySatisfyingEvent(updatedRule, isInherited);
            else if (updatedRule.IsClearEventRule)
                existingRule.CopyEventToClear(updatedRule, isInherited);
            else if (updatedRule.IsUpdateEvent)
                existingRule.CopyEventToUpdate(updatedRule, isInherited);
        }
    }
}