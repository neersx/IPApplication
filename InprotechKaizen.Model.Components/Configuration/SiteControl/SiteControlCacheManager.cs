using System;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Configuration.SiteControl
{
    public interface ISiteControlCacheManager : IMonitorClockRunnable
    {
    }

    internal class SiteControlCacheManager : ISiteControlCacheManager
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlCache _cache;
        
        public SiteControlCacheManager(IDbContext dbContext, ISiteControlCache cache)
        {
            _dbContext = dbContext;
            _cache = cache;
        }

        static DateTime? _lastChanged;

        public void Run()
        {
            if (_lastChanged == null)
            {
                _lastChanged = _dbContext.Set<Model.Configuration.SiteControl.SiteControl>()
                                         .Select(_ => _.LastChanged ?? DateTime.MinValue).Max();
            }

            var currentLastChanged = _dbContext.Set<Model.Configuration.SiteControl.SiteControl>()
                                               .Select(_ => _.LastChanged ?? DateTime.MinValue).Max();

            if (!(currentLastChanged > _lastChanged)) return;
            
            _lastChanged = currentLastChanged;

            _cache.Clear();
        }
    }
}