using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    class LawUpdateAnalyticsProvider : IAnalyticsEventProvider
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;

        public LawUpdateAnalyticsProvider(IDbContext dbContext, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {

            var analytics = new List<AnalyticsEvent>();
            var lawUpdateDate = _siteControlReader.Read<string>(SiteControls.CPALawUpdateService);
            if (!string.IsNullOrEmpty(lawUpdateDate))
            {
                analytics.Add(new AnalyticsEvent(AnalyticsEventCategories.LawUpdateServiceDate, lawUpdateDate));
            }

            var ictDetectionEventControl = await (from ec in _dbContext.Set<ValidEvent>()
                                                  where ec.LogApplication.StartsWith("Inprotech Configuration Tool") && ec.LastChanged != null
                                                  orderby ec.LastChanged descending
                                                  select new Ict
                                                  {
                                                      Version = ec.LogApplication,
                                                      LastChanged = ec.LastChanged
                                                  }).FirstOrDefaultAsync();

            if (ictDetectionEventControl != null)
            {
                analytics.Add(new AnalyticsEvent(AnalyticsEventCategories.IctDate, ictDetectionEventControl.LastChanged));
                analytics.Add(new AnalyticsEvent(AnalyticsEventCategories.IctVersion, ictDetectionEventControl.Version));
            }
            else
            {
                var ictDetectionCriteria = await (from det in _dbContext.Set<Criteria>()
                                                  where det.LogApplication.StartsWith("Inprotech Configuration Tool") && det.LastChanged != null
                                                  orderby det.LastChanged descending
                                                  select new
                                                  {
                                                      Version = det.LogApplication,
                                                      det.LastChanged
                                                  }).FirstOrDefaultAsync();

                if (ictDetectionCriteria != null)
                {
                    analytics.Add(new AnalyticsEvent(AnalyticsEventCategories.IctDate, ictDetectionCriteria.LastChanged));
                    analytics.Add(new AnalyticsEvent(AnalyticsEventCategories.IctVersion, ictDetectionCriteria.Version));
                }
            }

            return analytics;
        }

        class Ict
        {
            public string Version { get; set; }

            public DateTime? LastChanged { get; set; }
        }
    }
}