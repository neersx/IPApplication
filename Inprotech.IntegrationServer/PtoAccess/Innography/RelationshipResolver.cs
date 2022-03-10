using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public interface IRelationshipCodeResolver
    {
        Dictionary<string, string> ResolveMapping(params string[] requiredCodes);
    }

    public class RelationshipCodeResolver : IRelationshipCodeResolver
    {
        readonly IDbContext _dbContext;

        public RelationshipCodeResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public Dictionary<string, string> ResolveMapping(params string[] requiredCodes)
        {
            return (from map in _dbContext.Set<Mapping>()
                    where map.StructureId == KnownMapStructures.CaseRelationship &&
                          map.DataSourceId == (int) KnownExternalSystemIds.IPONE &&
                            requiredCodes.Contains(map.InputCode)
                    select new
                    {
                        ForInnography = map.InputCode,
                        InprotechCode = DbFuncs.ResolveMapping(KnownMapStructures.CaseRelationship, KnownEncodingSchemes.CpaXml, map.InputCode, "IpOneData")
                    })
                .ToDictionary(k => k.ForInnography, v => v.InprotechCode);
        }
    }
}