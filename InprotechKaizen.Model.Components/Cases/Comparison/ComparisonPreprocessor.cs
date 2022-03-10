using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping.Mappers;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.Comparison
{
    public interface IComparisonPreprocessor
    {
        IEnumerable<ComparisonScenario> MapCodes(IEnumerable<ComparisonScenario> comparisonScenarios,
            string sourceSystem);
    }

    public class ComparisonPreprocessor : IComparisonPreprocessor
    {
        readonly IDbContext _dbContext;
        readonly IMapperSelector _mapper;
        readonly IMappingResolver _mappingResolver;

        public ComparisonPreprocessor(
            IDbContext dbContext,
            IMapperSelector mapper,
            IMappingResolver mappingResolver)
        {
            _dbContext = dbContext;
            _mapper = mapper;
            _mappingResolver = mappingResolver;
        }

        public IEnumerable<ComparisonScenario> MapCodes(IEnumerable<ComparisonScenario> comparisonScenarios, string sourceSystem)
        {
            if (comparisonScenarios == null) throw new ArgumentNullException(nameof(comparisonScenarios));
            if (string.IsNullOrWhiteSpace(sourceSystem)) throw new ArgumentNullException(nameof(sourceSystem));

            var scenarios = comparisonScenarios.ToArray();

            var allSourcesToMap = FindAllSourcesToMap(scenarios);

            var mappedValues = ResolveMappedValues(sourceSystem, allSourcesToMap).ToArray();

            return from comparisonScenario in scenarios
                let mapper = _mapper[comparisonScenario.ComparisonType]
                select mapper.ApplyMapping(comparisonScenario, mappedValues);
        }

        IEnumerable<MappedValue> ResolveMappedValues(string sourceSystem, IEnumerable<Source> allSourcesToMap)
        {
            var mapScenarios = _dbContext.Set<MapScenario>()
                .Include(ms => ms.MapStructure.Mappings)
                .Include(ms => ms.MapStructure.Mappings.Select(_ => _.DataSource))
                .Include(ms => ms.MapStructure.EncodedValues)
                .Include(ms => ms.EncodingScheme)
                .Include(ms => ms.ExternalSystem)
                .Where(ms => ms.ExternalSystem.Code == sourceSystem)
                .ToArray();

            var mappedValues = new List<MappedValue>();

            foreach (var sourceToMapGroup in allSourcesToMap.GroupBy(_ => _.TypeId))
            {
                var mapStructureMap = sourceToMapGroup.Key;
                foreach (var mapScenario in mapScenarios.Where(_ => _.MapStructure.Id == mapStructureMap))
                {
                    mappedValues.AddRange(_mappingResolver.Resolve(sourceSystem, mapScenario, sourceToMapGroup));
                }
            }

            var failedMappings = mappedValues.OfType<FailedMapping>().ToArray();

            if (failedMappings.Any())
                throw new FailedMappingException(failedMappings.Select(_ => (FailedSource)_.Source));

            return mappedValues;
        }

        IEnumerable<Source> FindAllSourcesToMap(IEnumerable<ComparisonScenario> comparisonScenarios)
        {
            var allSourcesToMap = new List<Source>();

            foreach (var comparisonScenarioGroup in comparisonScenarios.GroupBy(_ => _.ComparisonType))
            {
                var mapper = _mapper[comparisonScenarioGroup.Key];
                allSourcesToMap.AddRange(mapper.ExtractSources(comparisonScenarioGroup));
            }

            return allSourcesToMap.DistinctBy(_ => _.TypeId.ToString() + (!string.IsNullOrEmpty(_.Code) ? _.Code : _.Description));
        }
    }
}