using System.Collections.Generic;
using System.Linq;
using Autofac.Features.Metadata;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers
{
    public interface IMapperSelector
    {
        IComparisonScenarioMapper this[ComparisonType comparisonType] { get; }
    }

    public class MapperSelector : IMapperSelector
    {
        readonly IEnumerable<Meta<IComparisonScenarioMapper>> _metaComparisonScenarioMappers;

        public MapperSelector(IEnumerable<Meta<IComparisonScenarioMapper>> metaComparisonScenarioMappers)
        {
            _metaComparisonScenarioMappers = metaComparisonScenarioMappers;
        }

        public IComparisonScenarioMapper this[ComparisonType comparisonType]
        {
            get
            {
                var mapper = _metaComparisonScenarioMappers
                    .SingleOrDefault(_ => (ComparisonType)_.Metadata["ComparisonType"] == comparisonType);
                
                return mapper == null ? new DefaultMapper() : mapper.Value;
            }
        }
    }
}
