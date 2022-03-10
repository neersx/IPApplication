using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
#pragma warning disable 618

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    public interface IValidEventService
    {
        void DeleteEvents(int criteriaId, int[] eventIds, bool appliesToDescendants);
        ValidEvent AddEvent(int criteriaId, int eventId, int? insertAfterEventId, bool applyToChildren);
        IEnumerable<ValidEvent> GetEventsUsedByCases(int criteriaId, int[] eventIds);
        void ReorderDescendantEvents(int criteriaId, int sourceEventId, int targetEventId, int? prevTargetEventId, int? nextTargetEventId, bool insertBefore);
        void ReorderEvents(int criteriaId, int sourceEventId, int targetEventId, bool insertBefore);
        void GetAdjacentEvents(int criteriaId, int eventId, out int? prevId, out int? nextId);
    }

    class ValidEventService : IValidEventService
    {
        readonly IDbContext _dbContext;
        readonly IInheritance _inheritance;

        public ValidEventService(IDbContext dbContext, IInheritance inheritance)
        {
            _dbContext = dbContext;
            _inheritance = inheritance;
        }

        public void DeleteEvents(int criteriaId, int[] eventIds, bool appliesToDescendants)
        {
            using (var trans = _dbContext.BeginTransaction())
            {
                if (appliesToDescendants)
                {
                    foreach (var eventId in eventIds)
                    {
                        var eid = eventId;
                        var descendantIds = _inheritance.GetDescendantsWithInheritedEvent(criteriaId, eventId).ToArray();

                        if (descendantIds.Any())
                            _dbContext.Delete(_dbContext.Set<ValidEvent>().Where(_ => _.EventId == eid && descendantIds.Contains(_.CriteriaId)));
                    }
                }
                else
                {
                    foreach (var eventId in eventIds)
                    {
                        var eid = eventId;
                        var childCriteriaIds = _dbContext.Set<Inherits>().Where(_ => _.FromCriteriaNo == criteriaId).Select(_ => _.CriteriaNo);

                        _dbContext.Update(_dbContext.Set<ValidEvent>().Where(_ => _.EventId == eid && childCriteriaIds.Contains(_.CriteriaId)), _ => new ValidEvent {Inherited = 0});
                    }
                }

                if (eventIds.Any())
                    _dbContext.Delete(_dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == criteriaId && eventIds.Contains(_.EventId)));

                trans.Complete();
            }
        }

        public ValidEvent AddEvent(int criteriaId, int eventId, int? insertAfterEventId, bool applyToChildren)
        {
            var criteria = _dbContext.Set<Criteria>()
                                     .Include("ValidEvents").WhereWorkflowCriteria().Single(_ => _.Id == criteriaId);

            if (criteria.ValidEvents.Any(e => e.EventId == eventId))
                throw new Exception($"EventControl {eventId} already exists in this Workflow Criteria.");

            var @event = _dbContext.Set<Event>().Single(e => e.Id == eventId);

            var insertAfterEvent = criteria.ValidEvents.SingleOrDefault(ve => ve.EventId == insertAfterEventId);
            short seq;
            if (insertAfterEvent != null)
            {
                seq = insertAfterEvent.DisplaySequence.GetValueOrDefault();
                IncrementSequencesAfter(criteria, seq);
            }
            else
            {
                seq = MaxValidEventSequence(criteria.ValidEvents);
            }
            
            var newEvent = CreateValidEvent(criteria, @event, (short)(seq + 1));
            _dbContext.Set<ValidEvent>().Add(newEvent);

            if (applyToChildren)
            {
                var descendentModels = new List<ValidEvent>();
                var descendents = _inheritance.GetDescendantsWithoutEvent(criteriaId, @event.Id).ToArray();

                if (insertAfterEventId != null)
                {
                    foreach (var d in descendents)
                    {
                        var validEvent = d.ValidEvents.SingleOrDefault(ve => ve.EventId == insertAfterEventId);
                        if (validEvent != null)
                        {
                            var newSequence = (short) (validEvent.DisplaySequence.GetValueOrDefault() + 1);
                            IncrementSequencesAfter(d, validEvent.DisplaySequence.GetValueOrDefault());
                            descendentModels.Add(CreateInheritedValidEvent(d, @event, newSequence, criteriaId));
                        }
                        else
                        {
                            descendentModels.Add(CreateInheritedValidEvent(d, @event, (short) (MaxValidEventSequence(d.ValidEvents) + 1), criteriaId));
                        }
                    }
                }
                else
                {
                    descendentModels = descendents.Select(d => CreateInheritedValidEvent(d, @event, (short) (MaxValidEventSequence(d.ValidEvents) + 1), criteriaId)).ToList();
                }
                _dbContext.AddRange(descendentModels);
            }

            _dbContext.SaveChanges();

            return newEvent;
        }

        short MaxValidEventSequence(IEnumerable<ValidEvent> events)
        {
            var validEvents = events.ToArray();
            return (short) (validEvents.Any() ? validEvents.Max(e => e.DisplaySequence.GetValueOrDefault(0)) : 0);
        }

        ValidEvent CreateValidEvent(Criteria criteria, Event @event, short seq)
        {
            // use Create method to ensure EF attaches new model to db context, otherwise lazy loading nav properties returns null
            var newEvent = _dbContext.Set<ValidEvent>().Create();
            newEvent.CriteriaId = criteria.Id;
            newEvent.EventId = @event.Id;
            newEvent.Description = @event.Description;
            newEvent.ImportanceLevel = @event.ImportanceLevel;
            newEvent.Importance = @event.InternalImportance;
            newEvent.DisplaySequence = seq;
            newEvent.NumberOfCyclesAllowed = @event.NumberOfCyclesAllowed;
            newEvent.RecalcEventDate = @event.RecalcEventDate;
            newEvent.SuppressDueDateCalculation = @event.SuppressCalculation;
            return newEvent;
        }

        ValidEvent CreateInheritedValidEvent(Criteria c, Event e, short sequence, int parentCriteriaId)
        {
            var newEvent = CreateValidEvent(c, e, sequence);
            newEvent.ParentCriteriaNo = parentCriteriaId;
            newEvent.ParentEventNo = e.Id;
            newEvent.IsInherited = true;
            return newEvent;
        }

        public IEnumerable<ValidEvent> GetEventsUsedByCases(int criteriaId, int[] eventIds)
        {
            var events = from ve in _dbContext.Set<ValidEvent>().Where(ve => ve.CriteriaId == criteriaId && eventIds.Contains(ve.EventId))
                         join ce in _dbContext.Set<CaseEvent>() on ve.EventId equals ce.EventNo
                         join oa in _dbContext.Set<OpenAction>().Where(_ => _.CriteriaId == criteriaId) on ce.CaseId equals oa.CaseId
                         select ve;
            return events.OrderBy(ve => ve.DisplaySequence).ToArray();
        }

        public void ReorderDescendantEvents(int criteriaId, int sourceEventId, int targetEventId, int? prevTargetEventId, int? nextTargetEventId, bool insertBefore)
        {
            var descendantIds = _inheritance.GetDescendantsWithEvent(criteriaId, sourceEventId).ToArray();
            if (!descendantIds.Any())
                return;

            foreach (var descendantId in descendantIds)
            {
                ReorderChildCriteriaEvents(descendantId, sourceEventId, targetEventId, prevTargetEventId, nextTargetEventId, insertBefore);
            }
        }

        public void ReorderEvents(int criteriaId, int sourceEventId, int targetEventId, bool insertBefore)
        {
            if (!_dbContext.Set<ValidEvent>().Any(_ => _.CriteriaId == criteriaId && _.EventId == sourceEventId))
                throw new KeyNotFoundException("sourceEventId");

            if (!_dbContext.Set<ValidEvent>().Any(_ => _.CriteriaId == criteriaId && _.EventId == targetEventId))
                throw new KeyNotFoundException("targetEventId");

            if (sourceEventId == targetEventId)
                return;

            var targetSeq = _dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == criteriaId && _.EventId == targetEventId).Select(_ => _.DisplaySequence).SingleOrDefault();

            if (insertBefore)
            {
                _dbContext.Update(_dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == criteriaId && _.DisplaySequence >= targetSeq), _ =>
                                                                                                                                             new ValidEvent
                                                                                                                                             {
                                                                                                                                                 DisplaySequence = (short) (_.DisplaySequence.Value + 1)
                                                                                                                                             });

                _dbContext.Update(_dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == criteriaId && _.EventId == sourceEventId), _ =>
                                                                                                                                         new ValidEvent
                                                                                                                                         {
                                                                                                                                             DisplaySequence = targetSeq
                                                                                                                                         });
            }
            else
            {
                _dbContext.Update(_dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == criteriaId && _.DisplaySequence > targetSeq), _ =>
                                                                                                                                            new ValidEvent
                                                                                                                                            {
                                                                                                                                                DisplaySequence = (short) (_.DisplaySequence.Value + 1)
                                                                                                                                            });

                _dbContext.Update(_dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == criteriaId && _.EventId == sourceEventId), _ =>
                                                                                                                                         new ValidEvent
                                                                                                                                         {
                                                                                                                                             DisplaySequence = (short) (targetSeq + 1)
                                                                                                                                         });
            }
        }

        void IncrementSequencesAfter(Criteria criteria, int sequence)
        {
            _dbContext.Update(_dbContext.Set<ValidEvent>()
                                        .Where(ve => ve.CriteriaId == criteria.Id && ve.DisplaySequence > sequence), ve => new ValidEvent {DisplaySequence = (short) (ve.DisplaySequence + 1 ?? 0)});
        }

        public void GetAdjacentEvents(int criteriaId, int eventId, out int? prevId, out int? nextId)
        {
            var eventIds = _dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == criteriaId).OrderBy(_ => _.DisplaySequence).Select(_ => _.EventId).ToList();
            var targetIndex = eventIds.IndexOf(eventId);

            prevId = targetIndex > 0 ? eventIds[targetIndex - 1] : (int?) null;
            nextId = targetIndex < eventIds.Count - 1 ? eventIds[targetIndex + 1] : (int?) null;
        }

        internal void ReorderChildCriteriaEvents(int criteriaId, int sourceEventId, int targetEventId, int? prevTargetEventId, int? nextTargetEventId, bool insertBefore)
        {
            if (!_dbContext.Set<ValidEvent>().Any(_ => _.CriteriaId == criteriaId && _.EventId == sourceEventId))
                return;

            var targetExists = _dbContext.Set<ValidEvent>().Any(_ => _.CriteriaId == criteriaId && _.EventId == targetEventId);

            if (!targetExists)
            {
                if (insertBefore && prevTargetEventId.HasValue && _dbContext.Set<ValidEvent>().Any(_ => _.CriteriaId == criteriaId && _.EventId == prevTargetEventId))
                {
                    ReorderEvents(criteriaId, sourceEventId, prevTargetEventId.Value, false);
                }
                else if (!insertBefore && nextTargetEventId.HasValue && _dbContext.Set<ValidEvent>().Any(_ => _.CriteriaId == criteriaId && _.EventId == nextTargetEventId))
                {
                    ReorderEvents(criteriaId, sourceEventId, nextTargetEventId.Value, true);
                }
            }
            else
            {
                ReorderEvents(criteriaId, sourceEventId, targetEventId, insertBefore);
            }
        }
    }
}