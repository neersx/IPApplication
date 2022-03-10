using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Messaging;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Persistence;
using ComparisonModel = InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Integration.AutomaticDocketing
{
    public interface IDocumentMappings
    {
        IEnumerable<ComparisonScenario<ComparisonModel.Event>> Resolve(IEnumerable<ComparisonScenario<ComparisonModel.Event>> comparisonScenarios, string sourceSystem);
    }

    public class DocumentMappings : IDocumentMappings
    {
        readonly IDbContext _dbContext;
        readonly IMappingResolver _mappingResolver;
        readonly IBus _bus;

        public DocumentMappings(IDbContext dbContext, IMappingResolver mappingResolver, IBus bus)
        {
            _dbContext = dbContext;
            _mappingResolver = mappingResolver;
            _bus = bus;
        }

        public IEnumerable<ComparisonScenario<ComparisonModel.Event>> Resolve(IEnumerable<ComparisonScenario<ComparisonModel.Event>> comparisonScenarios, string sourceSystem)
        {
            if (comparisonScenarios == null) throw new ArgumentNullException(nameof(comparisonScenarios));
            if (string.IsNullOrWhiteSpace(sourceSystem)) throw new ArgumentNullException(nameof(sourceSystem));

            var scenarios = comparisonScenarios.ToArray();

            var distinctSources = scenarios
              .DistinctBy(_ => _.ComparisonSource.EventDescription)
              .Select(_ => _.ComparisonSource)
              .Select(_ => new Source
              {
                  Description = _.EventDescription,
                  TypeId = KnownMapStructures.Documents
              }).ToArray();

            var mapScenario = _dbContext.Set<MapScenario>()
                .Include(ms => ms.MapStructure.Mappings)
                .Include(ms => ms.MapStructure.Mappings.Select(_ => _.DataSource))
                .Include(ms => ms.MapStructure.EncodedValues)
                .Include(ms => ms.EncodingScheme)
                .Include(ms => ms.ExternalSystem)
                .Where(ms => ms.ExternalSystem.Code == sourceSystem)
                .Single(ms => ms.MapStructure.Id == KnownMapStructures.Documents); 
                
            var mappedValues = _mappingResolver.Resolve(sourceSystem, mapScenario, distinctSources).ToArray();
            var failedMappings = mappedValues.OfType<FailedMapping>().ToArray();
            var successfulMappings = mappedValues.Except(failedMappings);

            foreach (var failed in failedMappings)
            {
                _bus.Publish(new BackgroundDocumentMappingFailed
                             {
                                 Description = failed.Source.Description,
                                 Structure = "Documents",
                                 SystemCode = sourceSystem
                             });
            }

            return scenarios
                .Select(_ => ApplyMapping(_, successfulMappings))
                .Cast<ComparisonScenario<ComparisonModel.Event>>();
        }

        ComparisonScenario ApplyMapping(ComparisonScenario<ComparisonModel.Event> scenario, IEnumerable<MappedValue> mappedValues)
        {
            if (string.IsNullOrWhiteSpace(scenario.ComparisonSource.EventDescription))
                return scenario;

            var mapped =
                mappedValues.SingleOrDefault(_ =>
                    _.Source.TypeId == KnownMapStructures.Documents &&
                    _.Source.Description == scenario.ComparisonSource.EventDescription);

            if (string.IsNullOrWhiteSpace(mapped?.Output))
                return scenario;

            scenario.Mapped.Id = int.Parse(mapped.Output);

            return scenario;
        }
    }
}
