using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.PriorArt;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    internal class PriorArtImportAnalyticsEventProvider : IAnalyticsEventProvider
    {
        readonly IDbContext _dbContext;

        public PriorArtImportAnalyticsEventProvider(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            return await (from sr in _dbContext.Set<PriorArt>()
                          where sr.ImportedFrom != null && sr.LastModified >= lastChecked
                          group sr by sr.ImportedFrom
                          into sr1
                          select new AnalyticsEvent
                          {
                              Name = AnalyticsEventCategories.StatisticsPriorArtImportedPrefix + sr1.Key,
                              Value = sr1.Count().ToString()
                          }).ToArrayAsync();
        }
    }
}