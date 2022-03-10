using System.Collections.Generic;
using System.Linq;
using Inprotech.Contracts;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede.DataMapping;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.IntegrationServer.PtoAccess.Innography
{
    public interface ICountryCodeResolver
    {
        Dictionary<string, string> ResolveMapping();
    }

    public class CountryCodeResolver : ICountryCodeResolver
    {
        readonly IDbContext _dbContext;
        readonly IBackgroundProcessLogger<CountryCodeResolver> _logger;

        public CountryCodeResolver(IDbContext dbContext, IBackgroundProcessLogger<CountryCodeResolver> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public Dictionary<string, string> ResolveMapping()
        {
            var reverseMap = (from map in _dbContext.Set<Mapping>()
                              where map.StructureId == KnownMapStructures.Country &&
                                    map.DataSourceId == (int) KnownExternalSystemIds.IPONE &&
                                    (map.OutputValue != null || map.OutputCodeId != null)
                              select new
                                     {
                                         ForInnography = map.InputCode,
                                         InprotechCode = DbFuncs.ResolveMapping(KnownMapStructures.Country, KnownEncodingSchemes.Wipo, map.InputCode, "IpOneData")
                                     })
                .GroupBy(_ => _.InprotechCode)
                .ToArray();

            var output = new Dictionary<string, string>();
            foreach (var map in reverseMap)
            {
                var first = map.First().ForInnography;

                if (map.Count() > 1)
                {
                    var duplicateMappings = map.Select(_ => $"'{_.ForInnography}'");
                    _logger.Warning($"Detected multiple country code mapping for Innography: '{map.Key}' is mapped to {string.Join(",", duplicateMappings)}.  '{first}' will be used.");
                }

                output.Add(map.Key, first);
            }
            return output;
        }
    }
}