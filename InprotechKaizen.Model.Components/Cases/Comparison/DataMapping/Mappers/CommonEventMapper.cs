using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;
using InprotechKaizen.Model.Ede.DataMapping;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public interface ICommonEventMapper
    {
        IEnumerable<Source> ExtractSources(IEnumerable<IEvent> events);
        bool TryResolveApplicableMapping(IEvent @event, IEnumerable<MappedValue> mappedValues, out MappedValue mappedValue);
    }

    public class CommonEventMapper : ICommonEventMapper
    {
        public IEnumerable<Source> ExtractSources(IEnumerable<IEvent> events)
        {
            var sourceEvents = events.ToArray();

            var eventsWithDescription = sourceEvents.Where(_ => !string.IsNullOrWhiteSpace(_.EventDescription))
                                                    .DistinctBy(_ => _.EventDescription)
                                                    .Select(_ => new Source
                                                                 {
                                                                     TypeId = KnownMapStructures.Events,
                                                                     Description = _.EventDescription
                                                                 });

            var eventsWithCode = sourceEvents.Where(_ => !string.IsNullOrWhiteSpace(_.EventCode) && string.IsNullOrWhiteSpace(_.EventDescription))
                                             .DistinctBy(_ => _.EventCode)
                                             .Select(_ => new Source
                                                          {
                                                              TypeId = KnownMapStructures.Events,
                                                              Code = _.EventCode
                                                          });

            return eventsWithDescription.Union(eventsWithCode);
        }

        public bool TryResolveApplicableMapping(IEvent @event, IEnumerable<MappedValue> mappedValues, out MappedValue mappedValue)
        {
            mappedValue = null;

            if (string.IsNullOrWhiteSpace(@event.EventDescription) && string.IsNullOrWhiteSpace(@event.EventCode))
            {
                return false;
            }

            var searchString = !string.IsNullOrWhiteSpace(@event.EventDescription)
                ? @event.EventDescription
                : @event.EventCode;

            var mapped = mappedValues.SingleOrDefault(_ =>
                                                          _.Source.TypeId == KnownMapStructures.Events &&
                                                          (string.Equals(_.Source.Description, searchString) || string.Equals(_.Source.Code, searchString)));

            if (string.IsNullOrWhiteSpace(mapped?.Output))
            {
                return false;
            }

            mappedValue = mapped;

            return true;
        }
    }
}