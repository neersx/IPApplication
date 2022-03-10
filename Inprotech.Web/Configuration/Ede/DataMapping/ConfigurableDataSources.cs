using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.Ede.DataMapping
{
    public interface IConfigurableDataSources
    {
        Dictionary<DataSourceType, IEnumerable<short>> Retrieve();
    }

    public class ConfigurableDataSources : IConfigurableDataSources
    {
        readonly IDbContext _dbContext;

        readonly int[] _supportedStructures = {KnownMapStructures.Events, KnownMapStructures.Documents};

        public ConfigurableDataSources(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public Dictionary<DataSourceType, IEnumerable<short>> Retrieve()
        {
            var systemIds = Enum.GetValues(typeof(DataSourceType))
                                .Cast<DataSourceType>()
                                .Select(ExternalSystems.Id);

            var interim = (from scenario in _dbContext.Set<MapScenario>()
                           join structure in _dbContext.Set<MapStructure>() on scenario.StructureId equals structure.Id into s1
                           from structure in s1.DefaultIfEmpty()
                           where structure != null && _supportedStructures.Contains(structure.Id) && systemIds.Contains(scenario.SystemId)
                           group scenario by scenario.ExternalSystem.Code
                           into g1
                           select new
                                  {
                                      g1.Key,
                                      Structures = g1.Select(_ => _.StructureId)
                                  })
                .ToArray();

            return interim.ToDictionary(_ => ExternalSystems.DataSource(_.Key), _ => _.Structures);
        }
    }
}