using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Persistence;
using Event = InprotechKaizen.Model.Components.Cases.Comparison.Results.Event;
using ValueExt = InprotechKaizen.Model.Components.Cases.Comparison.Results.ValueExt;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Updaters
{
    public interface IEventUpdater
    {
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        PoliceCaseEvent AddOrUpdateEvent(Case @case, int eventNo, DateTime? eventDate, short? cycle);

        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        IEnumerable<PoliceCaseEvent> AddOrUpdateEvents(Case @case, IEnumerable<Event> events);
        PoliceCaseEvent RemoveCaseEventDate(CaseEvent caseEvent, bool dueDateFlag);
        PoliceCaseEvent AddOrUpdateDueDateEvent(Case @case, int eventNo, DateTime? dueDate, short? cycle);
    }

    public class EventUpdater : IEventUpdater
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly IValidEventResolver _validEventResolver;

        public EventUpdater(IDbContext dbContext, IValidEventResolver validEventResolver, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _validEventResolver = validEventResolver;
            _now = now;
        }

        public PoliceCaseEvent AddOrUpdateEvent(Case @case, int eventNo, DateTime? eventDate, short? cycle = 1)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));

            var existingEvent = @case.CaseEvents.FirstOrDefault(e => e.EventNo == eventNo && e.Cycle == cycle);
            if (existingEvent != null)
            {
                return UpdateEvent(existingEvent, eventDate ?? _now().Date);
            }

            short nextCycle = 1;
            if (IsCyclic(@case, eventNo))
            {
                if (@case.CaseEvents.Any(e => e.EventNo == eventNo))
                {
                    nextCycle = (short) (@case.CaseEvents.Where(e => e.EventNo == eventNo).Max(e => e.Cycle) + 1);
                }
            }
            else
            {
                existingEvent = @case.CaseEvents.FirstOrDefault(e => e.EventNo == eventNo && e.Cycle == 1);

                if (existingEvent != null)
                {
                    return UpdateEvent(existingEvent, eventDate ?? _now().Date);
                }
            }

            var newEvent = new CaseEvent(@case.Id, eventNo, nextCycle)
                           {
                               EventDate = eventDate,
                               IsOccurredFlag = 1
                           };

            @case.CaseEvents.Add(newEvent);

            return new PoliceCaseEvent(newEvent);
        }

        public IEnumerable<PoliceCaseEvent> AddOrUpdateEvents(Case @case, IEnumerable<Event> events)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (events == null) throw new ArgumentNullException(nameof(events));

            var eventsUpdateOrder = events
                .OrderBy(_ => _.EventNo)
                .ThenBy(_ => _.Sequence);

            foreach (var e in eventsUpdateOrder)
            {
                if (e.EventNo != null && ValueExt.UpdatedOrDefault(e.EventDate, null) != null && e.EventDate.TheirValue != null)
                {
                    yield return AddOrUpdateEvent(@case, e.EventNo.Value, e.EventDate.TheirValue.Value, e.Cycle);
                }
            }
        }

        public PoliceCaseEvent RemoveCaseEventDate(CaseEvent caseEvent, bool dueDateFlag)
        {
            if (dueDateFlag)
                caseEvent.EventDueDate = null;
            else
                caseEvent.EventDate = null;
            return new PoliceCaseEvent(caseEvent);
        }

        static PoliceCaseEvent UpdateEvent(CaseEvent caseEvent, DateTime date)
        {
            caseEvent.EventDate = date;
            return new PoliceCaseEvent(caseEvent);
        }

        bool IsCyclic(Case @case, int eventId)
        {
            var validEvent = _validEventResolver.Resolve(@case, eventId);
            return validEvent?.IsCyclic ?? _dbContext.Set<Model.Cases.Events.Event>().Single(e => e.Id == eventId).IsCyclic;
        }

        public PoliceCaseEvent AddOrUpdateDueDateEvent(Case @case, int eventNo, DateTime? dueDate, short? cycle = 1)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));

            var existingEvent = @case.CaseEvents.FirstOrDefault(e => e.EventNo == eventNo && e.Cycle == cycle);
            if (existingEvent != null)
            {
                return UpdateDueDateEvent(existingEvent, dueDate ?? _now().Date);
            }

            short nextCycle = 1;
            if (IsCyclic(@case, eventNo))
            {
                if (@case.CaseEvents.Any(e => e.EventNo == eventNo))
                {
                    nextCycle = (short) (@case.CaseEvents.Where(e => e.EventNo == eventNo).Max(e => e.Cycle) + 1);
                }
            }
            else
            {
                existingEvent = @case.CaseEvents.FirstOrDefault(e => e.EventNo == eventNo && e.Cycle == 1);

                if (existingEvent != null)
                {
                    return UpdateDueDateEvent(existingEvent, dueDate ?? _now().Date);
                }
            }

            var newEvent = new CaseEvent(@case.Id, eventNo, nextCycle)
            {
                EventDueDate = dueDate,
                IsDateDueSaved = 1,
                IsOccurredFlag = 0
            };

            @case.CaseEvents.Add(newEvent);

            return new PoliceCaseEvent(newEvent);
        }

        static PoliceCaseEvent UpdateDueDateEvent(CaseEvent caseEvent, DateTime date)
        {
            caseEvent.EventDueDate = date;
            caseEvent.IsDateDueSaved = 1;
            caseEvent.IsOccurredFlag = 0;
            return new PoliceCaseEvent(caseEvent);
        }
    }
}