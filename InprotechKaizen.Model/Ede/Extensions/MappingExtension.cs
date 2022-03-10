using System;
using System.Linq;
using Entity = InprotechKaizen.Model.Ede.DataMapping;

namespace InprotechKaizen.Model.Ede.Extensions
{
    public static class MappingExtension
    {
        public static IQueryable<Entity.Mapping> For(this IQueryable<Entity.Mapping> dataMappings, int structureId, int systemId)
        {
            if (dataMappings == null) throw new ArgumentNullException("dataMappings");
            return dataMappings
                .Where(_ => _.DataSource != null && _.DataSource.SystemId == systemId && _.StructureId == structureId);
        }

        public static IQueryable<Entity.Mapping> WithInputCodeOrDescription(this IQueryable<Entity.Mapping> dataMappings, string input)
        {
            if (input == null) throw new ArgumentNullException("input");

            return dataMappings
                .Where(_ => _.InputCode == input || _.InputDescription == input);
        }
    }
}
