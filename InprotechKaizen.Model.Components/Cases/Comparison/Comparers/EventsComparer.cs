using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Comparison.Translations;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Persistence;
using Case = InprotechKaizen.Model.Cases.Case;
using Event = InprotechKaizen.Model.Components.Cases.Comparison.Results.Event;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public class EventsComparer : IEventsComparer
    {
        readonly IDatesAligner _datesAligner;
        readonly IDbContext _dbContext;
        readonly IEventDescriptionTranslator _translator;
        readonly IValidEventResolver _validEventResolver;

        public EventsComparer(IDbContext dbContext,
                              IDatesAligner datesAligner,
                              IValidEventResolver validEventResolver,
                              IEventDescriptionTranslator translator)
        {
            _dbContext = dbContext;
            _datesAligner = datesAligner;
            _validEventResolver = validEventResolver;
            _translator = translator;
        }

        public void Compare(Case @case, IEnumerable<ComparisonScenario> comparisonScenarios, ComparisonResult result)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (comparisonScenarios == null) throw new ArgumentNullException(nameof(comparisonScenarios));
            if (result == null) throw new ArgumentNullException(nameof(result));

            var all = comparisonScenarios.ToArray();

            var mapped = (from e in all.OfType<ComparisonScenario<Models.Event>>()
                          join n in all.OfType<ComparisonScenario<MatchingNumberEvent>>() on e.Mapped.EventCode equals n.Mapped.EventCode into n1
                          from n in n1.DefaultIfEmpty()
                          where n == null && e.Mapped.Id.HasValue
                          select e.Mapped)
                .ToArray();

            var uniqueIds = mapped.Where(_ => _.Id.HasValue).Select(_ => _.Id.Value).Distinct();

            var ourEvents = _dbContext.Set<Model.Cases.Events.Event>().Where(_ => uniqueIds.Contains(_.Id)).ToArray();

            result.Events = Build(@case, mapped, ourEvents);
        }

        IEnumerable<Event> Build(Case @case, Models.Event[] mapped, Model.Cases.Events.Event[] events)
        {
            var compared = _translator.Translate(Compare(@case, events, mapped)).ToArray();

            var used = new List<int?>();

            foreach (var m in mapped)
            {
                var eventId = m.Id;

                if (used.Contains(m.Id))
                {
                    continue;
                }

                used.Add(eventId);

                foreach (var r in compared.Where(_ => _.EventNo == eventId))
                {
                    r.EventDate.Different = Nullable.Compare(r.EventDate.OurValue, r.EventDate.TheirValue) != 0;
                    r.EventDate.Updateable = r.EventDate.Different.GetValueOrDefault() && r.Sequence.HasValue &&
                                             r.EventDate.TheirValue.HasValue;

                    yield return r;
                }
            }
        }

        IEnumerable<Event> Compare(Case @case, Model.Cases.Events.Event[] events, Models.Event[] workingMap)
        {
            foreach (var evt in events)
            {
                var @event = evt;
                var validEvent = _validEventResolver.Resolve(@case, @event);
                var mappedEvents = workingMap.Where(_ => _.Id == @event.Id).ToArray();
                var resolved = new ResolvedEvent(validEvent, @event);

                // assumes mapped events built from source data in same order; and occurred in descending order.
                // largest date may not be the latest occurence of the event, i.e. date amended to be brought forward.

                if (!resolved.IsCyclic)
                {
                    // discard all occurences of mapped event, 
                    // pick the first one because of the assumption above.
                    var their = mappedEvents.First();
                    var ours = @case.CaseEvents.FirstOrDefault(_ => _.EventNo == @event.Id);

                    yield return new Event
                                 {
                                     Sequence = 1,
                                     IsCyclic = false,
                                     Cycle = ours != null ? 1 : (short?) null,
                                     CorrelationRef = their.CorrelationRef,
                                     CriteriaId = resolved.EventControlId,
                                     EventNo = resolved.Id,
                                     EventType = resolved.EventDescription, /* non-translated */
                                     EventDate = new Value<DateTime?>
                                                 {
                                                     TheirValue = their.EventDate,
                                                     TheirDescription = their.EventText,
                                                     OurValue = ours?.EventDate
                                                 }
                                 };
                    continue;
                }

                // mapped events comes in order of the latest events first.
                // Reversing the order so cycles can be chornologically allocated easily.
                var oldestFirst = mappedEvents.Reverse().ToArray();

                foreach (var cyclicEvent in AlignCyclicEventsByDates(@case, resolved, oldestFirst).Reverse())
                    yield return cyclicEvent;
            }
        }

        IEnumerable<Event> AlignCyclicEventsByDates(Case @case, ResolvedEvent resolved, Models.Event[] theirs)
        {
            var ourEvents = @case.CaseEvents
                                 .Where(_ => _.EventNo == resolved.Id)
                                 .OrderBy(_ => _.Cycle);

            var ourDates = ourEvents
                .Select(_ => new Date<short>
                             {
                                 DateTime = _.EventDate,
                                 Ref = _.Cycle
                             })
                .ToArray();

            var theirDates = theirs.Where(_ => _.EventDate.HasValue)
                                   .Select(_ => new Date<PtoDateInfo>
                                                {
                                                    DateTime = _.EventDate,
                                                    Ref = new PtoDateInfo
                                                          {
                                                              Ref = _.CorrelationRef,
                                                              Description = _.EventText
                                                          }
                                                })
                                   .ToArray();

            // The dates are aligned in order to allocate the right cycles.
            foreach (var datesPair in _datesAligner.Align(theirDates, ourDates))
            {
                var d = datesPair;

                yield return new Event
                             {
                                 Sequence = d.RefRhs,
                                 EventNo = resolved.Id,
                                 EventType = resolved.EventDescription, /* non-translated */
                                 CorrelationRef = d.RefLhs?.Ref,
                                 IsCyclic = resolved.IsCyclic,
                                 CriteriaId = resolved.EventControlId,
                                 Cycle = d.DateTimeRhs.HasValue ? d.RefRhs : null,
                                 EventDate = new Value<DateTime?>
                                             {
                                                 TheirValue = d.DateTimeLhs,
                                                 TheirDescription = d.RefLhs?.Description,
                                                 OurValue = d.DateTimeRhs
                                             }
                             };
            }
        }
    }
}