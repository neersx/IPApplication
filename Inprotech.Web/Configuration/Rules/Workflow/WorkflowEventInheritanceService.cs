using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
#pragma warning disable 618

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    public interface IWorkflowEventInheritanceService
    {
        IEnumerable<ValidEvent> InheritNewEventRules(Criteria criteria, IEnumerable<ValidEvent> newParentCriteriaEvents, bool replaceCommonRules); // virtual for unit test partial substitute

        void SetInheritedFieldsToUpdate(ValidEvent childEvent, ValidEvent parentEvent, EventControlFieldsToUpdate eventControlFieldsToUpdate, WorkflowEventControlSaveModel allNewValues);
        
        Delta<int> GetInheritDelta(Func<Delta<int>> getRecordsToUpdate, Func<bool, IEnumerable<int>> getChildHashList);

        Delta<T> GetDelta<T>(Delta<T> newValues, Delta<int> shouldUpdate, Func<T, int> getHashKey, Func<T, int> getOriginalHashKey);

        EventControlFieldsToUpdate GenerateEventControlFieldsToUpdate(WorkflowEventControlSaveModel newValues);

        void BreakEventsInheritance(int criteriaId, int? eventId = null);
    }

    public class WorkflowEventInheritanceService : IWorkflowEventInheritanceService
    {
        readonly IDbContext _dbContext;

        public WorkflowEventInheritanceService(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public virtual IEnumerable<ValidEvent> InheritNewEventRules(Criteria criteria, IEnumerable<ValidEvent> newParentCriteriaEvents, bool replaceCommonRules) // virtual for unit test partial substitute
        {
            var parentCriteriaEvents = newParentCriteriaEvents as ValidEvent[] ?? newParentCriteriaEvents.ToArray();

            var nonCommonEvents = parentCriteriaEvents.Where(_ => criteria.ValidEvents.All(c => c.EventId != _.EventId)).OrderBy(_ => _.DisplaySequence);
            var lastSequenceNo = !criteria.ValidEvents.Any() ? (short?)0 : criteria.ValidEvents.Max(_ => _.DisplaySequence.GetValueOrDefault());
            var inheritedEvents = nonCommonEvents.Select(_ => InheritValidEventRule(criteria, _, ++lastSequenceNo)).ToList();

            if (replaceCommonRules)
            {
                var commonEventsFromParent = GetCommonEventsFromParent(criteria, parentCriteriaEvents);

                if (commonEventsFromParent.Any())
                {
                    DeleteCommonEventsFromChild(criteria, commonEventsFromParent.Select(_ => _.ParentEvent.EventId));
                    inheritedEvents.AddRange(commonEventsFromParent.Select(_ => InheritValidEventRule(criteria, _.ParentEvent, _.ChildEvent.DisplaySequence)));
                }
            }

            _dbContext.AddRange(inheritedEvents);
            _dbContext.SaveChanges();

            return inheritedEvents;
        }

        public void SetInheritedFieldsToUpdate(ValidEvent childEvent, ValidEvent parentEvent, EventControlFieldsToUpdate eventControlFieldsToUpdate, WorkflowEventControlSaveModel allNewValues)
        {
            SetInheritedFieldsToUpdate(childEvent, parentEvent, eventControlFieldsToUpdate);
            SetInheritedDatesLogicComparison(childEvent, eventControlFieldsToUpdate);
        }

        internal void SetInheritedFieldsToUpdate(ValidEvent childEvent, ValidEvent parentEvent, EventControlFieldsToUpdate eventControlFieldsToUpdate)
        {
            foreach (var propToUpdate in typeof(EventControlFieldsToUpdate).GetProperties().Where(_ => _.PropertyType == typeof(bool)))
            {
                if (!(bool)propToUpdate.GetValue(eventControlFieldsToUpdate)) continue;

                var validEventProp = typeof(ValidEvent).GetProperty(propToUpdate.Name);

                // if event1 and event2 property are not equal, set propToUpdate false for that property
                if ((dynamic)validEventProp.GetValue(childEvent) != (dynamic)validEventProp.GetValue(parentEvent))
                    propToUpdate.SetValue(eventControlFieldsToUpdate, false);
            }
        }

        internal void SetInheritedDatesLogicComparison(ValidEvent childEvent, EventControlFieldsToUpdate eventControlFieldsToUpdate)
        {
            if (eventControlFieldsToUpdate.DatesLogicComparison)
            {
                var allInherited = childEvent.DueDateCalcs.Where(_ => _.IsDateComparison).All(_ => _.IsInherited);
                if (!allInherited)
                    eventControlFieldsToUpdate.DatesLogicComparison = false;
            }
        }

        public Delta<int> GetInheritDelta(Func<Delta<int>> getRecordsToUpdate, Func<bool, IEnumerable<int>> getChildHashList)
        {
            var delta = getRecordsToUpdate();
            return new Delta<int>
            {
                Added = delta.Added?.Except(getChildHashList(false)).ToArray(),
                Updated = delta.Updated?.Intersect(getChildHashList(true)).ToArray(),
                Deleted = delta.Deleted?.Intersect(getChildHashList(true)).ToArray()
            };
        }

        public Delta<T> GetDelta<T>(Delta<T> newValues, Delta<int> shouldUpdate, Func<T, int> getHashKey, Func<T, int> getOriginalHashKey)
        {
            return new Delta<T>
            {
                Added = newValues.Added.Where(_ => shouldUpdate.Added.Contains(getHashKey(_))).ToArray(),
                Updated = newValues.Updated.Where(_ => shouldUpdate.Updated.Contains(getOriginalHashKey(_))).ToArray(),
                Deleted = newValues.Deleted.Where(_ => shouldUpdate.Deleted.Contains(getOriginalHashKey(_))).ToArray()
            };
        }

        public EventControlFieldsToUpdate GenerateEventControlFieldsToUpdate(WorkflowEventControlSaveModel newValues)
        {
            return new EventControlFieldsToUpdate
            {
                DueDateCalcsDelta = GetEventsToUpdateDelta(newValues.DueDateCalcDelta),
                NameTypeMapsDelta = GetEventsToUpdateDelta(newValues.NameTypeMapDelta),
                RequiredEventRulesDelta = new Delta<int>
                {
                    Added = newValues.RequiredEventRulesDelta.Added,
                    Deleted = newValues.RequiredEventRulesDelta.Deleted
                },
                DateComparisonDelta = GetEventsToUpdateDelta(newValues.DateComparisonDelta),
                SatisfyingEventsDelta = GetEventsToUpdateDelta(newValues.SatisfyingEventsDelta),
                EventsToClearDelta = GetEventsToUpdateDelta(newValues.EventsToClearDelta),
                EventsToUpdateDelta = GetEventsToUpdateDelta(newValues.EventsToUpdateDelta),
                ReminderRulesDelta = GetEventsToUpdateDelta(newValues.ReminderRuleDelta),
                DocumentsDelta = GetEventsToUpdateDelta(newValues.DocumentDelta),
                DesignatedJurisdictionsDelta = new Delta<string>
                {
                    Added = newValues.DesignatedJurisdictionsDelta?.Added,
                    Deleted = newValues.DesignatedJurisdictionsDelta?.Deleted
                },
                DatesLogicDelta = GetEventsToUpdateDelta(newValues.DatesLogicDelta)
            };
        }

        static Delta<int> GetEventsToUpdateDelta<T>(Delta<T> rawValues) where T : IEventControlSaveModel
        {
            return new Delta<int>
            {
                Added = rawValues.Added.Select(_ => _.HashKey()).Distinct().ToArray(),
                Updated = rawValues.Updated.Select(_ => _.OriginalHashKey).ToArray(),
                Deleted = rawValues.Deleted.Select(_ => _.OriginalHashKey).ToArray()
            };
        }

        static List<CommonEvent> GetCommonEventsFromParent(Criteria criteria, ValidEvent[] parentCriteriaEvents)
        {
            var commonEvents = (from e in criteria.ValidEvents
                                join p in parentCriteriaEvents
                                    on e.EventId equals p.EventId
                                select new CommonEvent
                                {
                                    ChildEvent = e,
                                    ParentEvent = p
                                }).ToList();

            return commonEvents;
        }

        internal void DeleteCommonEventsFromChild(Criteria criteria, IEnumerable<int> commonEventIds)
        {
            _dbContext.Delete<DatesLogic>(_ => _.CriteriaId == criteria.Id && commonEventIds.Contains(_.EventId));
            _dbContext.Delete<ValidEvent>(_ => _.CriteriaId == criteria.Id && commonEventIds.Contains(_.EventId));
        }

        internal ValidEvent InheritValidEventRule(Criteria criteria, ValidEvent parentEventRule, short? displaySequence)
        {
            var newEventRule = new ValidEvent(criteria.Id, parentEventRule.EventId, parentEventRule.Description) { DisplaySequence = displaySequence };
            newEventRule.InheritRulesFrom(parentEventRule);

            short ruleSeq = 0;
            newEventRule.DueDateCalcs = parentEventRule.DueDateCalcs.Any() ? parentEventRule.DueDateCalcs.Select(_ => new DueDateCalc(newEventRule, ruleSeq++).InheritRuleFrom(_)).ToList() : new List<DueDateCalc>();

            ruleSeq = 0;
            newEventRule.DatesLogic = parentEventRule.DatesLogic.Any() ? parentEventRule.DatesLogic.Select(_ => new DatesLogic(newEventRule, ruleSeq++).InheritRuleFrom(_)).ToList() : new List<DatesLogic>();

            ruleSeq = 0;
            newEventRule.RelatedEvents = parentEventRule.RelatedEvents.Any() ? parentEventRule.RelatedEvents.Select(_ => new RelatedEventRule(newEventRule, ruleSeq++).InheritRuleFrom(_)).ToList() : new List<RelatedEventRule>();

            ruleSeq = 0;
            newEventRule.Reminders = parentEventRule.Reminders.Any() ? parentEventRule.Reminders.Select(_ => new ReminderRule(newEventRule, ruleSeq++).InheritRuleFrom(_)).ToList() : new List<ReminderRule>();

            ruleSeq = 0;
            newEventRule.NameTypeMaps = parentEventRule.NameTypeMaps.Any() ? parentEventRule.NameTypeMaps.Select(_ => new NameTypeMap(newEventRule, _.ApplicableNameTypeKey, _.SubstituteNameTypeKey, ruleSeq++).InheritRuleFrom(_)).ToList() : new List<NameTypeMap>();

            newEventRule.RequiredEvents = parentEventRule.RequiredEvents.Any() ? parentEventRule.RequiredEvents.Select(_ => new RequiredEventRule(newEventRule).InheritRuleFrom(_)).ToList() : new List<RequiredEventRule>();

            return newEventRule;
        }

        public void BreakEventsInheritance(int criteriaId, int? eventId = null)
        {
            _dbContext.Update(_dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == criteriaId && (eventId == null || _.EventId == eventId)),
                              _ => new ValidEvent { ParentCriteriaNo = null, ParentEventNo = null, Inherited = 0 });

            _dbContext.Update(_dbContext.Set<DueDateCalc>().Where(_ => _.CriteriaId == criteriaId && (eventId == null || _.EventId == eventId)),
                              _ => new DueDateCalc { Inherited = 0 });

            _dbContext.Update(_dbContext.Set<RelatedEventRule>().Where(_ => _.CriteriaId == criteriaId && (eventId == null || _.EventId == eventId)),
                              _ => new RelatedEventRule { Inherited = 0 });

            _dbContext.Update(_dbContext.Set<ReminderRule>().Where(_ => _.CriteriaId == criteriaId && (eventId == null || _.EventId == eventId)),
                              _ => new ReminderRule { Inherited = 0 });

            _dbContext.Update(_dbContext.Set<DatesLogic>().Where(_ => _.CriteriaId == criteriaId && (eventId == null || _.EventId == eventId)),
                              _ => new DatesLogic { Inherited = 0 });

            _dbContext.Update(_dbContext.Set<NameTypeMap>().Where(_ => _.CriteriaId == criteriaId && (eventId == null || _.EventId == eventId)),
                              _ => new NameTypeMap { Inherited = false });

            _dbContext.Update(_dbContext.Set<RequiredEventRule>().Where(_ => _.CriteriaId == criteriaId && (eventId == null || _.EventId == eventId)),
                              _ => new RequiredEventRule { Inherited = false });
        }

        class CommonEvent
        {
            public ValidEvent ChildEvent { get; set; }
            public ValidEvent ParentEvent { get; set; }
        }
    }
}