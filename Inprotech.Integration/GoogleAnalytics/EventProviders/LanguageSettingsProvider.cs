using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    class LanguageSettingsProvider : IAnalyticsEventProvider
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControlReader;

        public LanguageSettingsProvider(IDbContext dbContext, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _siteControlReader = siteControlReader;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            var firmCulturePreference =
                (from sv in _dbContext.Set<SettingValues>()
                 where sv.SettingId == KnownSettingIds.PreferredCulture && sv.User == null
                 select sv.CharacterValue).SingleOrDefault();

            var userCulturePreference =
                string.Join("; ", await (from sv in _dbContext.Set<SettingValues>()
                                         where sv.SettingId == KnownSettingIds.PreferredCulture && sv.User != null && sv.CharacterValue != null
                                         group sv by sv.CharacterValue
                                         into g1
                                         select new
                                         {
                                             CulturePreferred = g1.Key,
                                             Popularity = g1.Count()
                                         })
                                        .OrderByDescending(_ => _.Popularity)
                                        .Select(_ => _.CulturePreferred + " (" + _.Popularity + ")").ToArrayAsync()
                           );

            string dbLanguage = null;
            var tableCode = _siteControlReader.Read<int?>(SiteControls.LANGUAGE);
            if (tableCode.HasValue)
            {
                var tc = await _dbContext.Set<TableCode>().FirstOrDefaultAsync(_ => _.Id == tableCode.Value && _.TableTypeId == (short)TableTypes.Language);
                if (tc != null) dbLanguage = tc.Name;
            }

            var events = new List<AnalyticsEvent>();

            if (!string.IsNullOrWhiteSpace(dbLanguage)) events.Add(new AnalyticsEvent(AnalyticsEventCategories.LanguageDb, dbLanguage));
            if (!string.IsNullOrWhiteSpace(firmCulturePreference)) events.Add(new AnalyticsEvent(AnalyticsEventCategories.LanguageFirm, firmCulturePreference));
            if (!string.IsNullOrWhiteSpace(userCulturePreference)) events.Add(new AnalyticsEvent(AnalyticsEventCategories.LanguageUsers, userCulturePreference));

            return events;
        }
    }
}