using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Comparison.Translations;
using InprotechKaizen.Model.Components.Cases.Events;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Persistence;
using Case = InprotechKaizen.Model.Cases.Case;
using OfficialNumber = InprotechKaizen.Model.Components.Cases.Comparison.Models.OfficialNumber;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Comparers
{
    public class NumbersComparer : ISpecificComparer
    {
        readonly string _culture;
        readonly IDbContext _dbContext;
        readonly IEventDescriptionTranslator _translator;
        readonly IValidEventResolver _validEventResolver;

        public NumbersComparer(IDbContext dbContext,
                               IValidEventResolver validEventResolver,
                               IPreferredCultureResolver preferredCultureResolver,
                               IEventDescriptionTranslator translator)
        {
            _dbContext = dbContext;
            _validEventResolver = validEventResolver;
            _translator = translator;
            _culture = preferredCultureResolver.Resolve();
        }

        public void Compare(Case @case, IEnumerable<ComparisonScenario> comparisonScenarios, ComparisonResult result)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (comparisonScenarios == null) throw new ArgumentNullException(nameof(comparisonScenarios));
            if (result == null) throw new ArgumentNullException(nameof(result));

            var allScenarios = comparisonScenarios.ToArray();
            var numberScenarios = allScenarios.OfType<ComparisonScenario<OfficialNumber>>().ToArray();
            var eventScenarios = allScenarios.OfType<ComparisonScenario<MatchingNumberEvent>>().ToArray();

            var interimResults = Build(@case, numberScenarios, eventScenarios);

            result.OfficialNumbers = _translator.Translate(interimResults);
        }

        IEnumerable<Results.OfficialNumber> Build(Case @case,
                                                  IEnumerable<ComparisonScenario<OfficialNumber>> numbers,
                                                  IEnumerable<ComparisonScenario<MatchingNumberEvent>> events)
        {
            var imported = numbers.Select(_ => _.Mapped).ToArray();
            var matchingEvents = events.Select(_ => _.Mapped).ToArray();
            var types = imported.Select(_ => _.NumberType).Distinct().ToArray();
            
            var referencedEventIds = matchingEvents.Select(_ => _.Id).Where(_ => _ != null).Cast<int>().ToArray();
            var referencedEvents = (from e in _dbContext.Set<Model.Cases.Events.Event>()
                                    where referencedEventIds.Contains(e.Id)
                                    select e)
                .ToDictionary(k => k.Id, v => v);

            var interimInPriorityDisplayOrder =
                from nt in _dbContext.Set<NumberType>()
                where types.Contains(nt.NumberTypeCode)
                orderby nt.IssuedByIpOffice, nt.DisplayPriority
                select new InterimResult
                       {
                           NumberTypeCode = nt.NumberTypeCode,
                           Description = DbFuncs.GetTranslation(nt.Name, null, nt.NameTId, _culture)
                       };

            foreach (var type in interimInPriorityDisplayOrder.ToArray())
            {
                var t = type;

                foreach (var source in imported.Where(_ => string.Equals(_.NumberType, t.NumberTypeCode, StringComparison.InvariantCultureIgnoreCase)))
                {
                    var matchingEvent = matchingEvents.SingleOrDefault(_ => _.EventCode == source.Code);

                    t.RelatedEvent = matchingEvent?.Id != null
                        ? referencedEvents[(int) matchingEvent.Id]
                        : null;

                    yield return Compare(@case, source, t);
                }
            }
        }

        Results.OfficialNumber Compare(Case @case, OfficialNumber importedNumber, InterimResult interimType)
        {
            CaseEvent @event = null;

            var eventFound = false;

            var ours = @case.OfficialNumbers
                            .Where(_ => _.NumberTypeId == importedNumber.NumberType)
                            .OrderByDescending(_ => _.IsCurrent)
                            .FirstOrDefault();

            var numberFound = ours != null;

            if (numberFound && interimType.RelatedEvent?.Id != null)
            {
                @event = @case.CaseEvents.SingleOrDefault(_ => _.EventNo == interimType.RelatedEvent.Id && _.Cycle == 1);

                eventFound = @event != null;
            }

            var re = ResolveValidEvent(@case, interimType.RelatedEvent);

            var result = new Results.OfficialNumber
                         {
                             NumberType = interimType.Description,
                             Event = re?.EventDescription,
                             Number = new Value<string>
                                      {
                                          OurValue = numberFound ? ours.Number : null,
                                          TheirValue = importedNumber.Number,
                                          Different = !numberFound || !Similar(ours.Number, importedNumber.Number)
                                      },
                             EventDate = new Value<DateTime?>
                                         {
                                             OurValue = eventFound ? @event.EventDate : null,
                                             TheirValue = importedNumber.EventDate,
                                             Different = Nullable.Compare(@event?.EventDate, importedNumber.EventDate) != 0
                                         },
                             EventNo = interimType.RelatedEvent?.Id,
                             CriteriaId = re?.EventControlId,
                             Cycle = eventFound ? 1 : (short?) null
                         };

            result.Number.Updateable = !numberFound ||
                                       ours.IsCurrent == 1 && result.Number.Different.GetValueOrDefault();

            result.EventDate.Updateable =
                result.EventDate.TheirValue.HasValue &&
                result.EventDate.Different.GetValueOrDefault();

            result.EventDate = result.EventDate.ReturnsIfApplicable();

            result.MappedNumberTypeId = importedNumber.NumberType;

            if (numberFound)
            {
                result.Id = ours.NumberId;
            }

            return result;
        }

        static bool Similar(string ourValue, string theirValue)
        {
            return Helper.StripNonNumerics(ourValue) == Helper.StripNonNumerics(theirValue);
        }

        ResolvedEvent ResolveValidEvent(Case @case, Model.Cases.Events.Event @event)
        {
            if (@event == null) return null;

            var validEvent = _validEventResolver.Resolve(@case, @event);

            return new ResolvedEvent(validEvent, @event);
        }

        class InterimResult
        {
            internal string NumberTypeCode { get; set; }

            internal string Description { get; set; }

            internal Model.Cases.Events.Event RelatedEvent { get; set; }
        }
    }
}