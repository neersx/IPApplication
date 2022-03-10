using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.Entity.SqlServer;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    public class SiteControlAnalyticsProvider : IAnalyticsEventProvider
    {
        static readonly string[] SensitiveOrIrrelevant =
        {
            SiteControls.AddressPassword, SiteControls.ConfirmationPasswd,
            SiteControls.LANGUAGE,
            SiteControls.DBReleaseVersion, SiteControls.InprotechWebAppsVersion, SiteControls.IntegrationVersion,
            SiteControls.CPALawUpdateService
        };

        readonly IDbContext _dbContext;

        public SiteControlAnalyticsProvider(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            var r = new List<AnalyticsEvent>();

            r.AddRange(await AnalyticsEvents(async () => await (from sc in _dbContext.Set<SiteControl>()
                                                                where sc.DataType == "B" && sc.InitialValue != "None" && sc.BooleanValue != null &&
                                                                      (sc.BooleanValue == true ? "true" : "false") != sc.InitialValue
                                                                select new Interim
                                                                {
                                                                    ControlId = sc.ControlId,
                                                                    Value = sc.BooleanValue == true ? "true" : "false"
                                                                })
                                                 .ToArrayAsync()));

            r.AddRange(await AnalyticsEvents(async () => await (from sc in _dbContext.Set<SiteControl>()
                                                                where sc.DataType == "I" &&
                                                                      sc.InitialValue != "None" && sc.InitialValue != null && sc.IntegerValue != null &&
                                                                      SqlFunctions.StringConvert((double) sc.IntegerValue) != sc.InitialValue
                                                                select new Interim
                                                                {
                                                                    ControlId = sc.ControlId,
                                                                    Value = SqlFunctions.StringConvert((double) sc.IntegerValue)
                                                                }).ToArrayAsync()));

            r.AddRange(await AnalyticsEvents(async () => await (from sc in _dbContext.Set<SiteControl>()
                                                                where sc.DataType == "D" &&
                                                                      sc.InitialValue != "None" && sc.InitialValue != null && sc.DecimalValue != null &&
                                                                      SqlFunctions.StringConvert(sc.DecimalValue) != sc.InitialValue
                                                                select new Interim
                                                                {
                                                                    ControlId = sc.ControlId,
                                                                    Value = SqlFunctions.StringConvert(sc.DecimalValue)
                                                                }).ToArrayAsync()));

            r.AddRange(await AnalyticsEvents(async () => await (from sc in _dbContext.Set<SiteControl>()
                                                                where !SensitiveOrIrrelevant.Contains(sc.ControlId)
                                                                where sc.DataType == "C" &&
                                                                      sc.InitialValue != "None" && sc.InitialValue != null && sc.StringValue != null &&
                                                                      sc.StringValue != sc.InitialValue
                                                                select new Interim
                                                                {
                                                                    ControlId = sc.ControlId,
                                                                    Value = sc.StringValue
                                                                }).ToArrayAsync()));

            return r;
        }

        async Task<IEnumerable<AnalyticsEvent>> AnalyticsEvents(Func<Task<IEnumerable<Interim>>> scResolver)
        {
            var a = new List<AnalyticsEvent>();

            foreach (var r in await scResolver())
            {
                a.Add(new AnalyticsEvent
                {
                    Name = AnalyticsEventCategories.SiteConfigurationsPrefix + r.ControlId,
                    Value = r.Value
                });
            }

            return a;
        }

        public class Interim
        {
            public string ControlId { get; set; }

            public string Value { get; set; }
        }
    }
}