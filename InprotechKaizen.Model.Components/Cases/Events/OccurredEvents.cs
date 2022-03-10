using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.Events
{
    public interface IOccurredEvents
    {
        IEnumerable<OccurredEvent> For(Case @case);
    }

    public class OccurredEvents : IOccurredEvents
    {
        readonly IDbContext _dbContext;

        public OccurredEvents(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public IEnumerable<OccurredEvent> For(Case @case)
        {
            if (@case == null) throw new ArgumentNullException("case");

            var occurredEventIds = @case.CaseEvents
                .Where(ce => ce.IsOccurredFlag >= 1 && ce.IsOccurredFlag <= 8)
                .GroupBy(ce => ce.EventNo).Select(g => g.Key).ToArray();

            var oa = @case.CurrentOpenActions().ToArray();

            var events = _dbContext.Set<Event>().Where(e => occurredEventIds.Contains(e.Id)).ToArray();

            var relevantCriteriaIds = oa.Where(o => o.Criteria != null)
                .Select(_ => _.Criteria.Id)
                .Union(
                    @case.CaseEvents.Where(ce => ce.CreatedByCriteriaKey != null)
                        .Select(ce => ce.CreatedByCriteriaKey)
                        .Cast<int>())
                .Distinct();

            var validEvents = _dbContext.Set<ValidEvent>()
                .Where(
                    ve =>
                        occurredEventIds.Contains(ve.EventId) &&
                        relevantCriteriaIds.Contains(ve.CriteriaId))
                .ToArray();

            return PopulateOccurredEvents(@case, occurredEventIds, events, validEvents, oa)
                .OrderBy(oe => oe.Description)
                .ThenBy(oe => oe.Code);
        }

        static IEnumerable<OccurredEvent> PopulateOccurredEvents(
            Case @case,
            IEnumerable<int> occurredEventIds,
            IEnumerable<Event> events,
            ValidEvent[] validEvents,
            IEnumerable<OpenAction> oa)
        {
            foreach (var oe in occurredEventIds)
            {
                var e = oe;

                var latest = @case.CaseEvents.OrderByDescending(ce => ce.Cycle).First(ce => ce.EventNo == e);

                var ev = events.First(e1 => e1.Id == e);

                var fromOpenAction =
                    validEvents.FirstOrDefault(ve => ve.EventId == e && oa.Any(_ => _.Criteria != null && _.Criteria.Id == ve.CriteriaId));

                var fromCreatedByCriteria =
                    validEvents.FirstOrDefault(ve => ve.EventId == e && ve.CriteriaId == latest.CreatedByCriteriaKey);

                yield return new OccurredEvent
                {
                    CaseId = @case.Id,
                    EventId = e,
                    Cycle = latest.Cycle,
                    Description = EventDescription(fromOpenAction, fromCreatedByCriteria, ev)
                };
            }
        }

        static string EventDescription(ValidEvent v1, ValidEvent v2, Event e)
        {
            if (v1 != null) return v1.Description;
            if (v2 != null) return v2.Description;
            return e.Description;
        }
    }

    public class OccurredEvent
    {
        public int CaseId { get; set; }

        public int EventId { get; set; }

        public string Code { get; set; }

        public string Description { get; set; }

        public short Cycle { get; set; }
    }
}