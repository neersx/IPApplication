using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Persistence;
using Entity = InprotechKaizen.Model.Ede.DataMapping;

namespace Inprotech.Web.Configuration.Ede.DataMapping.Mappings
{
    public interface IMappings
    {
        IEnumerable<Mapping> Fetch(int? systemId, int structureId, Func<Entity.Mapping, string, Mapping> createMapping);
    }

    public class Mappings : IMappings
    {
        readonly IDbContext _dbContext;

        public Mappings(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public IEnumerable<Mapping> Fetch(int? systemId, int structureId,
            Func<Entity.Mapping, string, Mapping> createMapping)
        {
            if (systemId == null) throw new ArgumentNullException("systemId");
            if (createMapping == null) throw new ArgumentNullException("createMapping");

            var interim = _dbContext.Set<Entity.Mapping>()
                .Where(m => m.StructureId == structureId)
                .Where(m => m.DataSource != null && m.DataSource.SystemId == systemId)
                .ToArray();

            var distinctOuputEncodedValueIds = interim
                .Where(_ => _.OutputCodeId.HasValue)
                .Select(_ => _.OutputCodeId)
                .Distinct();

            var outputEncodedValues = _dbContext.Set<Entity.Mapping>()
                .Where(_ => _.StructureId == structureId)
                .Where(_ => _.InputCodeId.HasValue && distinctOuputEncodedValueIds.Contains(_.InputCodeId.Value))
                .ToArray()
                .ToDictionary(
                    k => k.InputCodeId.Value,
                    v => v.OutputValue
                );

            return
                interim.Select(mapping => createMapping(mapping, DeriveOutputValueFrom(mapping, outputEncodedValues)))
                    .ToArray();
        }

        static string DeriveOutputValueFrom(Entity.Mapping mapping,
            IReadOnlyDictionary<int, string> encodedValues)
        {
            return mapping.OutputCodeId.HasValue
                ? encodedValues[mapping.OutputCodeId.Value]
                : mapping.OutputValue;
        }
    }
}