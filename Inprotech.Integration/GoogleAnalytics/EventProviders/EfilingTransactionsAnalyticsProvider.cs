using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    public class EfilingTransactionsAnalyticsProvider : IAnalyticsEventProvider
    {
        readonly IDbContext _dbContext;
        readonly IDbArtifacts _dbArtifacts;

        const string EFilingTransactionDetection = @"
            select TC.DESCRIPTION, count(*)
            from B2BEXCHANGEHISTORY HIST
            join B2BEXCHANGE EXC on HIST.EXCHANGEID = EXC.EXCHANGEID
            join TABLECODES TC on EXC.EXCHANGEFILETYPE = TC.TABLECODE
            where HIST.STATUSCODE = 1302 and TABLETYPE = 102 and HIST.STATUSDATE >= @lastCheck
            group by TC.DESCRIPTION
";

        public EfilingTransactionsAnalyticsProvider(IDbContext dbContext, IDbArtifacts dbArtifacts)
        {
            _dbContext = dbContext;
            _dbArtifacts = dbArtifacts;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            if (!_dbArtifacts.Exists("B2BEXCHANGE", SysObjects.Table))
                return Enumerable.Empty<AnalyticsEvent>();

            var parameters = new Dictionary<string, object>
            {
                {"@lastCheck", lastChecked}
            };

            var result = new List<AnalyticsEvent>();

            using (var command = _dbContext.CreateSqlCommand(EFilingTransactionDetection, parameters))
            using (var reader = await command.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    result.Add(new AnalyticsEvent(AnalyticsEventCategories.IntegrationsEfilingPrefix + reader.GetString(0), reader.GetInt32(1)));
                }
            }

            return result;
        }
    }
}