using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Lists
{
    [Authorize]
    public class EventsController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IEventMatcher _eventMatcher;

        public EventsController(IDbContext dbContext, IEventMatcher eventMatcher)
        {
            _dbContext = dbContext;
            _eventMatcher = eventMatcher;
        }

        [Route("api/lists/events")]
        public IEnumerable<EventResult> Get(string q)
        {
            var events = _dbContext.Set<InprotechKaizen.Model.Cases.Events.Event>();
            
            return (from m in _eventMatcher.MatchingItems(q)
                    join e in events on m.Key equals e.Id into e1
                    from e in e1
                    select new EventResult
                           {
                               Key = m.Key,
                               Code = m.Code,
                               Value = m.Value,
                               Cycles = m.MaxCycles,
                               ImportanceDesc = m.Importance,
                               ImportanceLevel = m.ImportanceLevel,
                               Category = e.Category != null ? e.Category.Name : null,
                               Definition = e.Notes,
                               InUse = m.ValidEventDescription.Any()
                           })
                .Take(SearchConstants.PageSize)
                .ToArray();
        }

        public class EventResult
        {
            public int Key { get; set; }

            public string Code { get; set; }

            public string Value { get; set; }

            public string Category { get; set; }

            public string Definition { get; set; }

            public short? Cycles { get; set; }

            public string ImportanceDesc { get; set; }

            public string ImportanceLevel { get; set; }

            public bool InUse { get; set; }
        }
    }
}