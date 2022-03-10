using System;
using System.Data.Entity;
using System.Globalization;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.SourceChanges
{
    public interface IMostRecentlyAppliedChanges
    {
        Task<DateTime> Resolve();

        Task Set(DateTime mostRecentChange);
    }

    public class MostRecentlyAppliedChanges : IMostRecentlyAppliedChanges
    {
        readonly Func<DateTime> _clock;
        readonly IDbContext _dbContext;

        public MostRecentlyAppliedChanges(IDbContext dbContext, Func<DateTime> clock)
        {
            _dbContext = dbContext;
            _clock = clock;
        }

        public async Task<DateTime> Resolve()
        {
            var provider = await _dbContext
                .Set<ExternalSettings>()
                .SingleAsync(_ => _.ProviderName == "InnographyId");

            return DateTime.TryParseExact(provider.Settings, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out DateTime result)
                ? result.AddDays(1)
                : _clock().ToUniversalTime().Date;
        }

        public async Task Set(DateTime mostRecentChange)
        {
            var provider = await _dbContext
                .Set<ExternalSettings>()
                .SingleAsync(_ => _.ProviderName == "InnographyId");

            provider.Settings = mostRecentChange.ToString("yyyy-MM-dd");

            _dbContext.SaveChanges();
        }
    }
}