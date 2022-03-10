using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    public class ModuleUsageAnalyticsProvider : IAnalyticsEventProvider
    {
        readonly IDbContext _dbContext;

        Dictionary<string, string> _customCaseTypeDescriptions = new Dictionary<string, string>();

        Dictionary<string, string> _customPropertyTypeDescriptions = new Dictionary<string, string>();

        public ModuleUsageAnalyticsProvider(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            var analytics = new List<AnalyticsEvent>();

            await PopulateTypeDescriptionsNotDeliveredByIpRules();

            await ClientServerModuleUsedSinceLastChecked(lastChecked, analytics);

            await ClientServerScreensConfigurationAnalysis(analytics);

            await WorkflowEntryScreenUsageAnalysis(analytics);

            await WebCaseScreenForInternalUsers(analytics);

            await WebCaseScreenForExternalUsers(analytics);

            await WebNameScreenForInternalUsers(analytics);

            return analytics;
        }

        async Task WebNameScreenForInternalUsers(List<AnalyticsEvent> analytics)
        {
            var r1 = from t in _dbContext.Set<TopicControl>()
                     join w in _dbContext.Set<WindowControl>() on t.WindowControlId equals w.Id into w1
                     from w in w1
                     join c in _dbContext.Set<NameCriteria>() on w.NameCriteriaId equals c.Id into c1
                     from c in c1
                     where w.Name == KnownNameScreenWindowNames.NameDetails
                     select new
                     {
                         Name = t.Name.StartsWith(KnownNameScreenTopics.NameText)
                             ? KnownNameScreenTopics.NameText
                             : t.Name.StartsWith(KnownNameScreenTopics.NameCustomContent)
                                 ? KnownNameScreenTopics.NameCustomContent
                                 : t.Name,
                         c.Description
                     };

            var r2 = from t in _dbContext.Set<TopicControl>()
                     join w in _dbContext.Set<WindowControl>() on t.WindowControlId equals w.Id into w1
                     from w in w1
                     join c in _dbContext.Set<NameCriteria>() on w.NameCriteriaId equals c.Id into c1
                     from c in c1
                     where w.Name == KnownNameScreenWindowNames.NameDetails
                     select new
                     {
                         Name = t.Name.StartsWith(KnownNameScreenTopics.NameText)
                             ? KnownNameScreenTopics.NameText
                             : t.Name.StartsWith(KnownNameScreenTopics.NameCustomContent)
                                 ? KnownNameScreenTopics.NameCustomContent
                                 : t.Name,
                         c.Description
                     };

            analytics.AddRange(await AnalyticsEvents(AnalyticsEventCategories.ConfigurationInternalWebNameTopicUsePrefix,
                                                     async () => await (from r in r1.Union(r2)
                                                                        group r by new {r.Name, r.Description}
                                                                        into g1
                                                                        select new NameScreenInterim
                                                                        {
                                                                            ScreenName = g1.Key.Name,
                                                                            Description = g1.Key.Description,
                                                                            Value = g1.Count()
                                                                        })
                                                         .ToArrayAsync()));
        }

        async Task WebCaseScreenForExternalUsers(List<AnalyticsEvent> analytics)
        {
            var r1 = from t in _dbContext.Set<TopicControl>()
                     join w in _dbContext.Set<WindowControl>() on t.WindowControlId equals w.Id into w1
                     from w in w1
                     join c in _dbContext.Set<Criteria>() on w.CriteriaId equals c.Id into c1
                     from c in c1
                     where w.Name == KnownCaseScreenWindowNames.CaseDetails && c.ProgramId == KnownCasePrograms.ClientAccess
                     select new
                     {
                         Name = t.Name.StartsWith(KnownCaseScreenTopics.CaseTexts)
                             ? KnownCaseScreenTopics.CaseTexts
                             : t.Name.StartsWith(KnownCaseScreenTopics.Names)
                                 ? KnownCaseScreenTopics.Names
                                 : t.Name.StartsWith(KnownCaseScreenTopics.CaseCustomContent)
                                     ? KnownCaseScreenTopics.CaseCustomContent
                                     : t.Name.StartsWith(KnownCaseScreenTopics.NameText)
                                         ? KnownCaseScreenTopics.NameText
                                         : t.Name,
                         c.CaseTypeId,
                         c.PropertyTypeId
                     };

            var r2 = from t in _dbContext.Set<TopicControl>()
                     join w in _dbContext.Set<WindowControl>() on t.WindowControlId equals w.Id into w1
                     from w in w1
                     join c in _dbContext.Set<Criteria>() on w.CriteriaId equals c.Id into c1
                     from c in c1
                     where w.Name == KnownCaseScreenWindowNames.CaseDetails && c.ProgramId == KnownCasePrograms.ClientAccess
                     select new
                     {
                         Name = t.Name.StartsWith(KnownCaseScreenTopics.CaseTexts)
                             ? KnownCaseScreenTopics.CaseTexts
                             : t.Name.StartsWith(KnownCaseScreenTopics.Names)
                                 ? KnownCaseScreenTopics.Names
                                 : t.Name.StartsWith(KnownCaseScreenTopics.CaseCustomContent)
                                     ? KnownCaseScreenTopics.CaseCustomContent
                                     : t.Name.StartsWith(KnownCaseScreenTopics.NameText)
                                         ? KnownCaseScreenTopics.NameText
                                         : t.Name,
                         c.CaseTypeId,
                         c.PropertyTypeId
                     };

            analytics.AddRange(await AnalyticsEvents(AnalyticsEventCategories.ConfigurationExternalWebCaseTopicUsePrefix,
                                                     async () => await (from r in r1.Union(r2)
                                                                        group r by new {r.Name, r.CaseTypeId, r.PropertyTypeId}
                                                                        into g1
                                                                        select new CaseScreenInterim
                                                                        {
                                                                            ScreenName = g1.Key.Name,
                                                                            CaseType = g1.Key.CaseTypeId,
                                                                            PropertyType = g1.Key.PropertyTypeId,
                                                                            Value = g1.Count()
                                                                        })
                                                         .ToArrayAsync()));
        }

        async Task WebCaseScreenForInternalUsers(List<AnalyticsEvent> analytics)
        {
            var r1 = from t in _dbContext.Set<TopicControl>()
                     join w in _dbContext.Set<WindowControl>() on t.WindowControlId equals w.Id into w1
                     from w in w1
                     join c in _dbContext.Set<Criteria>() on w.CriteriaId equals c.Id into c1
                     from c in c1
                     where w.Name == KnownCaseScreenWindowNames.CaseDetails && c.ProgramId != KnownCasePrograms.ClientAccess
                     select new
                     {
                         Name = t.Name.StartsWith(KnownCaseScreenTopics.CaseTexts)
                             ? KnownCaseScreenTopics.CaseTexts
                             : t.Name.StartsWith(KnownCaseScreenTopics.Names)
                                 ? KnownCaseScreenTopics.Names
                                 : t.Name.StartsWith(KnownCaseScreenTopics.CaseCustomContent)
                                     ? KnownCaseScreenTopics.CaseCustomContent
                                     : t.Name.StartsWith(KnownCaseScreenTopics.NameText)
                                         ? KnownCaseScreenTopics.NameText
                                         : t.Name,
                         c.CaseTypeId,
                         c.PropertyTypeId
                     };

            var r2 = from t in _dbContext.Set<TopicControl>()
                     join w in _dbContext.Set<WindowControl>() on t.WindowControlId equals w.Id into w1
                     from w in w1
                     join c in _dbContext.Set<Criteria>() on w.CriteriaId equals c.Id into c1
                     from c in c1
                     where w.Name == KnownCaseScreenWindowNames.CaseDetails && c.ProgramId != KnownCasePrograms.ClientAccess
                     select new
                     {
                         Name = t.Name.StartsWith(KnownCaseScreenTopics.CaseTexts)
                             ? KnownCaseScreenTopics.CaseTexts
                             : t.Name.StartsWith(KnownCaseScreenTopics.Names)
                                 ? KnownCaseScreenTopics.Names
                                 : t.Name.StartsWith(KnownCaseScreenTopics.CaseCustomContent)
                                     ? KnownCaseScreenTopics.CaseCustomContent
                                     : t.Name.StartsWith(KnownCaseScreenTopics.NameText)
                                         ? KnownCaseScreenTopics.NameText
                                         : t.Name,
                         c.CaseTypeId,
                         c.PropertyTypeId
                     };

            analytics.AddRange(await AnalyticsEvents(AnalyticsEventCategories.ConfigurationInternalWebCaseTopicUsePrefix,
                                                     async () => await (from r in r1.Union(r2)
                                                                        group r by new {r.Name, r.CaseTypeId, r.PropertyTypeId}
                                                                        into g1
                                                                        select new CaseScreenInterim
                                                                        {
                                                                            ScreenName = g1.Key.Name,
                                                                            CaseType = g1.Key.CaseTypeId,
                                                                            PropertyType = g1.Key.PropertyTypeId,
                                                                            Value = g1.Count()
                                                                        })
                                                         .ToArrayAsync()));
        }

        async Task PopulateTypeDescriptionsNotDeliveredByIpRules()
        {
            _customCaseTypeDescriptions = await (from c in _dbContext.Set<CaseType>()
                                                 where !Strings.CaseTypes.Keys.Contains(c.Code)
                                                 select c)
                .ToDictionaryAsync(k => k.Code, v => v.Name + "[" + v.Code + "]");

            _customPropertyTypeDescriptions = await (from c in _dbContext.Set<PropertyType>()
                                                     where !Strings.PropertyTypes.Keys.Contains(c.Code)
                                                     select c)
                .ToDictionaryAsync(k => k.Code, v => v.Name + "[" + v.Code + "]");
        }

        async Task WorkflowEntryScreenUsageAnalysis(List<AnalyticsEvent> analytics)
        {
            analytics.AddRange(await AnalyticsEvents(AnalyticsEventCategories.ConfigurationWorkflowEntryScreensUsePrefix,
                                                     async () => await (from sc in _dbContext.Set<DataEntryTaskStep>()
                                                                        join c in _dbContext.Set<Criteria>() on sc.CriteriaId equals c.Id into c1
                                                                        from c in c1
                                                                        where sc.DataEntryTaskId != null && c.ActionId != null
                                                                        group sc by new {sc.ScreenName, c.CaseTypeId, c.PropertyTypeId, c.Action.Name}
                                                                        into g1
                                                                        select new CaseScreenInterim
                                                                        {
                                                                            ScreenName = g1.Key.ScreenName,
                                                                            CaseType = g1.Key.CaseTypeId,
                                                                            PropertyType = g1.Key.PropertyTypeId,
                                                                            Value = g1.Count()
                                                                        })
                                                         .ToArrayAsync()));
        }

        async Task ClientServerScreensConfigurationAnalysis(List<AnalyticsEvent> analytics)
        {
            analytics.AddRange(await AnalyticsEvents(AnalyticsEventCategories.ConfigurationClientServerScreensUsePrefix,
                                                     async () => await (from sc in _dbContext.Set<DataEntryTaskStep>()
                                                                        join c in _dbContext.Set<Criteria>() on sc.CriteriaId equals c.Id into c1
                                                                        from c in c1
                                                                        where sc.DataEntryTaskId == null
                                                                        group sc by new {sc.ScreenName, c.CaseTypeId, c.PropertyTypeId}
                                                                        into g1
                                                                        select new CaseScreenInterim
                                                                        {
                                                                            ScreenName = g1.Key.ScreenName,
                                                                            CaseType = g1.Key.CaseTypeId,
                                                                            PropertyType = g1.Key.PropertyTypeId,
                                                                            Value = g1.Count()
                                                                        })
                                                         .ToArrayAsync()));
        }

        async Task ClientServerModuleUsedSinceLastChecked(DateTime lastChecked, List<AnalyticsEvent> analytics)
        {
            analytics.AddRange(await AnalyticsEvents(AnalyticsEventCategories.StatisticsClientServerModuleUsePrefix,
                                                     async () => await (from u in _dbContext.Set<UserIdentityAccessLog>()
                                                                        where u.Provider == "Centura" && u.LoginTime >= lastChecked
                                                                        group u by u.LogApplication
                                                                        into g1
                                                                        select new Interim
                                                                        {
                                                                            Name = g1.Key,
                                                                            Value = g1.Count()
                                                                        })
                                                         .ToArrayAsync()));
        }

        async Task<IEnumerable<AnalyticsEvent>> AnalyticsEvents(string prefix, Func<Task<IEnumerable<CaseScreenInterim>>> resolver)
        {
            var analytics = new List<AnalyticsEvent>();

            var all = (await resolver()).ToArray();

            foreach (var currentScreen in all.Select(_ => _.ScreenName).Distinct())
            {
                var detail = new StringBuilder();

                foreach (var screen in all.Where(_ => _.ScreenName == currentScreen))
                {
                    var caseType = !string.IsNullOrWhiteSpace(screen.CaseType)
                        ? Strings.CaseTypes.Get(screen.CaseType) ?? _customCaseTypeDescriptions.Get(screen.CaseType)
                        : string.Empty;

                    var propertyType = !string.IsNullOrWhiteSpace(screen.PropertyType)
                        ? Strings.PropertyTypes.Get(screen.PropertyType) ?? _customPropertyTypeDescriptions.Get(screen.PropertyType)
                        : string.Empty;

                    var action = !string.IsNullOrWhiteSpace(screen.Action)
                        ? " - " + screen.Action
                        : string.Empty;

                    var label = $"{caseType}.{propertyType}".Trim('.');

                    if (string.IsNullOrWhiteSpace(label))
                    {
                        label = "(default rule)";
                    }

                    detail.AppendLine($"{label}{action} ({screen.Value}); ");
                }

                analytics.Add(new AnalyticsEvent
                {
                    Name = prefix + currentScreen,
                    Value = detail.ToString()
                });
            }

            return analytics;
        }

        async Task<IEnumerable<AnalyticsEvent>> AnalyticsEvents(string prefix, Func<Task<IEnumerable<NameScreenInterim>>> resolver)
        {
            var analytics = new List<AnalyticsEvent>();

            var all = (await resolver()).ToArray();

            foreach (var currentScreen in all.Select(_ => _.ScreenName).Distinct())
            {
                var detail = new StringBuilder();

                foreach (var screen in all.Where(_ => _.ScreenName == currentScreen))
                {
                    detail.AppendLine($"{screen.Description} ({screen.Value}); ");
                }

                analytics.Add(new AnalyticsEvent
                {
                    Name = prefix + currentScreen,
                    Value = detail.ToString()
                });
            }

            return analytics;
        }

        async Task<IEnumerable<AnalyticsEvent>> AnalyticsEvents(string prefix, Func<Task<IEnumerable<Interim>>> resolver)
        {
            var a = new List<AnalyticsEvent>();

            foreach (var r in await resolver())
            {
                a.Add(new AnalyticsEvent
                {
                    Name = prefix + r.Name,
                    Value = r.Value.ToString()
                });
            }

            return a;
        }

        class Interim
        {
            public string Name { get; set; }

            public int Value { get; set; }
        }

        class CaseScreenInterim
        {
            public string ScreenName { get; set; }

            public string CaseType { get; set; }

            public string PropertyType { get; set; }

            public string Action { get; set; }

            public int Value { get; set; }
        }

        class NameScreenInterim
        {
            public string ScreenName { get; set; }

            public int Value { get; set; }
            public string Description { get; set; }
        }
    }
}