using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    public class GeneralStatisticsAnalyticsProvider : IAnalyticsEventProvider
    {
        readonly IDbContext _dbContext;

        public GeneralStatisticsAnalyticsProvider(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            var analytics = new List<AnalyticsEvent>();
            analytics.AddRange(await NewCasesByPropertyTypeAddedSince(lastChecked));
            analytics.AddRange(await NewDocumentsGeneratedSince(lastChecked));
            return analytics;
        }

        async Task<IEnumerable<AnalyticsEvent>> NewDocumentsGeneratedSince(DateTime lastChecked)
        {
            var newDocsGenerated = await (from d in _dbContext.Set<CaseActivityHistory>()
                                          where d.WhenOccurred >= lastChecked && d.LetterNo != null
                                          select d).CountAsync();

            return new[]
            {
                new AnalyticsEvent(AnalyticsEventCategories.StatisticsDocGenerated, newDocsGenerated)
            };
        }

        async Task<IEnumerable<AnalyticsEvent>> NewCasesByPropertyTypeAddedSince(DateTime lastChecked)
        {
            var newCases = await (from c in _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                                  join ce in _dbContext.Set<CaseEvent>() on c.Id equals ce.CaseId into ce1
                                  from ce in ce1
                                  where ce.EventNo == (int) KnownEvents.DateOfEntry && ce.Cycle == 1 && ce.EventDate != null && ce.EventDate >= lastChecked
                                  group c by new {c.PropertyTypeId, c.TypeId}
                                  into g1
                                  select new Interim
                                  {
                                      CaseType = g1.Key.TypeId,
                                      PropertyType = g1.Key.PropertyTypeId,
                                      Count = g1.Count()
                                  })
                .ToArrayAsync();

            var customCaseTypeDescriptions = await (from c in _dbContext.Set<CaseType>()
                                                    where !Strings.CaseTypes.Keys.Contains(c.Code)
                                                    select c)
                .ToDictionaryAsync(k => k.Code, v => v.Name + "[" + v.Code + "]");

            var customPropertyTypeDescriptions = await (from c in _dbContext.Set<PropertyType>()
                                                        where !Strings.PropertyTypes.Keys.Contains(c.Code)
                                                        select c)
                .ToDictionaryAsync(k => k.Code, v => v.Name + "[" + v.Code + "]");

            return from nc in newCases
                   let caseType = Strings.CaseTypes.Get(nc.CaseType) ?? customCaseTypeDescriptions[nc.CaseType]
                   let propertyType = Strings.PropertyTypes.Get(nc.PropertyType) ?? customPropertyTypeDescriptions[nc.PropertyType]
                   select new AnalyticsEvent
                   {
                       Name = AnalyticsEventCategories.StatisticsNewCasesPrefix + caseType + ".Cases." + propertyType,
                       Value = nc.Count.ToString()
                   };
        }

        class Interim
        {
            public string CaseType { get; set; }

            public string PropertyType { get; set; }

            public int Count { get; set; }
        }
    }
}