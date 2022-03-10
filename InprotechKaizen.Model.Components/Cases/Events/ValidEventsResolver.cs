using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Events
{
    public interface IValidEventsResolver
    {
        IEnumerable<ResolvedEvent> Resolve(int caseId, IEnumerable<int> eventIdsToResolve);
    }

    public class ValidEventsResolver : IValidEventsResolver
    {
        readonly IDbContext _dbContext;
        readonly IValidEventResolver _validEventResolver;

        public ValidEventsResolver(IDbContext dbContext, IValidEventResolver validEventResolver)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (validEventResolver == null) throw new ArgumentNullException("validEventResolver");

            _dbContext = dbContext;
            _validEventResolver = validEventResolver;
        }

        public IEnumerable<ResolvedEvent> Resolve(int caseId, IEnumerable<int> eventIdsToResolve)
        {
            if (eventIdsToResolve == null) throw new ArgumentNullException("eventIdsToResolve");

            var @case = _dbContext.Set<Case>()
                .Include(c => c.CaseEvents)
                .Include(c => c.OpenActions.Select(_ => _.Criteria))
                .Single(c => c.Id == caseId);

            var @events = _dbContext.Set<Event>()
                .Where(_ => eventIdsToResolve.Contains(_.Id))
                .ToArray()
                .ToDictionary(k => k, v => new ResolvedEvent(v.Id, v.Description, v.IsCyclic));

            foreach (var e in @events)
            {
                var @event = e.Key;
                var @eventMetadata = @events[@event];
                var ve = _validEventResolver.Resolve(@case, @event);
                if (ve == null) continue;

                @eventMetadata.Description = ve.Description;
                @eventMetadata.IsCyclic = ve.IsCyclic;
            }

            return @events.Values;
        }
    }

    public class ResolvedEvent
    {
        public int EventId { get; set; }

        public string Description { get; set; }

        public bool IsCyclic { get; set; }

        public ResolvedEvent(int eventId, string description, bool isCyclic)
        {
            EventId = eventId;
            Description = description;
            IsCyclic = isCyclic;
        }
    }
}