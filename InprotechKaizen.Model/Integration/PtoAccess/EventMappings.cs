using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Integration.PtoAccess
{
    public interface IEventMappingsResolver
    {
        Dictionary<string, IQueryable<CaseEvent>> Resolve(string[] events, string systemCode);
    }

    public class EventMappingsResolver : IEventMappingsResolver
    {
        readonly IDbContext _dbContext;

        public EventMappingsResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public Dictionary<string, IQueryable<CaseEvent>> Resolve(string[] events, string systemCode)
        {
            var inputDescriptions = string.Join(",", events);
            var mappedEvents = _dbContext
                               .ResolveEventMappings(inputDescriptions, systemCode)
                               .ToDictionary(_ => _.Code, _ => _);

            var eventMaps = new Dictionary<string, IQueryable<CaseEvent>>();

            foreach (var @event in events)
            {
                eventMaps.Add(@event, GetMapped(mappedEvents, @event));
            }

            return eventMaps;
        }

        IQueryable<CaseEvent> GetMapped(Dictionary<string, SourceMappedEvents> mappedEvents, string requiredCode)
        {
            var eventId = mappedEvents.Get(requiredCode)?.MappedEventId;
            return _dbContext.Set<CaseEvent>().Where(_ => _.Cycle == 1 && _.EventNo == eventId);
        }
    }
}
