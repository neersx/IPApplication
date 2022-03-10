using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Analytics;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    public class SchemaMappingGeneratedAnalyticsProvider : IAnalyticsEventProvider
    {
        readonly IDbContext _dbContext;
        readonly IServerTransactionDataQueue _serverTransactionDataQueue;

        public SchemaMappingGeneratedAnalyticsProvider(IDbContext dbContext, IServerTransactionDataQueue serverTransactionDataQueue)
        {
            _dbContext = dbContext;
            _serverTransactionDataQueue = serverTransactionDataQueue;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            var rawEventData = (await _serverTransactionDataQueue.Dequeue<RawEventData>(TransactionalEventTypes.SchemaMappingGeneratedViaApi)
                ).ToArray();

            var mappingIds = rawEventData.Select(_ => int.Parse(_.Value)).ToArray();

            var mappingIdMap = await (from m in _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>()
                                      where mappingIds.Contains(m.Id)
                                      select new
                                      {
                                          m.Id,
                                          m.Name
                                      }).ToDictionaryAsync(k => k.Id, v => v.Name);

            return from r in rawEventData
                   group r by r.Value
                   into r1
                   select new AnalyticsEvent
                   {
                       Name = AnalyticsEventCategories.StatisticsSchemaMappingViaApiPrefix + " (" + mappingIdMap[int.Parse(r1.Key)] + ")",
                       Value = r1.Count().ToString()
                   };
        }
    }
}