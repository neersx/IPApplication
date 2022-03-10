using System;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Updaters
{
    public interface ICaseComparisonEvent
    {
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        PoliceCaseEvent Apply(Case @case);
    }

    public class CaseComparisonEvent : ICaseComparisonEvent
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly ISiteControlReader _siteControlReader;

        public CaseComparisonEvent(IDbContext dbContext, ISiteControlReader siteControlReader, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
            _now = now;
        }

        public PoliceCaseEvent Apply(Case @case)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (!TryResolve(_siteControlReader, out var eventId))
            {
                return null;
            }

            var @event = _dbContext.Set<Event>().SingleOrDefault(_ => _.Id == eventId);
            var isCyclical = @event?.IsCyclic ?? false;
            var maxCycle = @event?.NumberOfCyclesAllowed ?? 9999;
            
            var comparisonEvents = @case.CaseEvents.Where(e => e.EventNo == eventId).OrderByDescending(_ => _.Cycle).ToArray();

            var cycle = isCyclical
                ? (short) Math.Min((comparisonEvents.FirstOrDefault()?.Cycle ?? 0) + 1, maxCycle)
                : (comparisonEvents.FirstOrDefault()?.Cycle ?? 1);

            var comparisonEvent = comparisonEvents.SingleOrDefault(_ => _.Cycle == cycle);
            if (comparisonEvent == null)
            {
                comparisonEvent = new CaseEvent(@case.Id, eventId, cycle);
                @case.CaseEvents.Add(comparisonEvent);
            }

            comparisonEvent.EventDate = _now().Date;
            comparisonEvent.IsOccurredFlag = 1;

            return new PoliceCaseEvent(comparisonEvent);
        }

        static bool TryResolve(ISiteControlReader siteControlReader, out int @event)
        {
            var comparisonEvent = siteControlReader.Read<int?>(SiteControls.CaseComparisonEvent);

            if (comparisonEvent != null)
            {
                @event = comparisonEvent.Value;
                return true;
            }

            @event = int.MinValue;
            return false;
        }
    }
}