using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public class MatchingNumberEventMapper : IComparisonScenarioMapper
    {
        readonly ICommonEventMapper _commonEventMapper;

        public MatchingNumberEventMapper(ICommonEventMapper commonEventMapper)
        {
            _commonEventMapper = commonEventMapper;
        }

        public IEnumerable<Source> ExtractSources(IEnumerable<ComparisonScenario> source)
        {
            var events = source.OfType<ComparisonScenario<MatchingNumberEvent>>()
                               .Select(_ => _.ComparisonSource as IEvent);

            return _commonEventMapper.ExtractSources(events);
        }

        public ComparisonScenario ApplyMapping(ComparisonScenario scenario, IEnumerable<MappedValue> mappedValues)
        {
            var @event = (ComparisonScenario<MatchingNumberEvent>) scenario;
            var source = @event.ComparisonSource as IEvent;
            if (!_commonEventMapper.TryResolveApplicableMapping(source, mappedValues, out MappedValue mapped))
            {
                return scenario;
            }

            @event.Mapped.Id = int.Parse(mapped.Output);
            return scenario;
        }
    }
}