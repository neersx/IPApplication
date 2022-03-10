using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Storage;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting.Tax;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    class IntegrationsStatusProvider : IAnalyticsEventProvider
    {
        readonly IDbContext _dbContext;
        readonly IRepository _repository;
        readonly ICryptoService _cryptoService;

        public IntegrationsStatusProvider(IDbContext dbContext, IRepository repository, ICryptoService cryptoService)
        {
            _dbContext = dbContext;
            _repository = repository;
            _cryptoService = cryptoService;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            async Task<long> SchemaMappingEnabled()
            {
                return await _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>().CountAsync();
            }

            async Task<bool> VatSubmittedSinceLastChecked()
            {
                return await (from vr in _dbContext.Set<VatReturn>()
                              where vr.IsSubmitted && vr.LastModified >= lastChecked
                              select 1).AnyAsync();
            }

            var result = new List<AnalyticsEvent>(await GetDataDownloadIntegrations(lastChecked))
            {
                new AnalyticsEvent(AnalyticsEventCategories.IntegrationsSchemaMapping, await SchemaMappingEnabled()),
                new AnalyticsEvent(AnalyticsEventCategories.IntegrationsHmrcVatReturns, await VatSubmittedSinceLastChecked()),
                new AnalyticsEvent(AnalyticsEventCategories.IntegrationsFirstToFileView, await GetFtfEnabled())
            };

            result.AddRange(await GetIManageAnalytics());

            return result;
        }

        async Task<IEnumerable<AnalyticsEvent>> GetDataDownloadIntegrations(DateTime lastChecked)
        {
            var requests = new List<AnalyticsEvent>();

            var casesUpdatedBySource = await (from cn in _repository.Set<CaseNotification>()
                                              join c in _repository.Set<Case>() on cn.CaseId equals c.Id into c1
                                              from c in c1
                                              where cn.UpdatedOn >= lastChecked
                                              group c by c.Source
                                              into g1
                                              select new
                                              {
                                                  Source = g1.Key,
                                                  Count = g1.Count()
                                              })
                .ToDictionaryAsync(k => k.Source, v => v.Count);

            var documentsDownloadedBySource = await (from d in _repository.Set<Document>()
                                                     where d.UpdatedOn >= lastChecked
                                                     group d by d.Source
                                                     into g1
                                                     select new
                                                     {
                                                         Source = g1.Key,
                                                         Count = g1.Count()
                                                     })
                .ToDictionaryAsync(k => k.Source, v => v.Count);

            var messagesReceivedByType = from m in _repository.Set<MessageStore>()
                                         where m.MessageTimestamp >= lastChecked
                                         group m by m.ServiceType
                                         into g1
                                         select new
                                         {
                                             Source = g1.Key,
                                             Count = g1.Count()
                                         };

            var ip1dMatchesByType = await (from i in _dbContext.Set<CpaGlobalIdentifier>()
                                           join c in _dbContext.Set<InprotechKaizen.Model.Cases.Case>() on i.CaseId equals c.Id into c1
                                           from c in c1
                                           where i.IsActive && i.LastChanged >= lastChecked
                                           group c by c.PropertyTypeId
                                           into g1
                                           select new
                                           {
                                               Source = g1.Key,
                                               Count = g1.Count()
                                           })
                .ToDictionaryAsync(k => k.Source, v => v.Count);

            foreach (var caseUpdate in casesUpdatedBySource)
            {
                var source = AnalyticsEventCategories.IntegrationsCasesPrefix + ExternalSystems.SystemCode(caseUpdate.Key);
                requests.Add(new AnalyticsEvent(source, caseUpdate.Value));
            }

            foreach (var docDownloaded in documentsDownloadedBySource)
            {
                var source = AnalyticsEventCategories.IntegrationsDocumentsPrefix + ExternalSystems.SystemCode(docDownloaded.Key);
                requests.Add(new AnalyticsEvent(source, docDownloaded.Value));
            }

            foreach (var messagesReceived in messagesReceivedByType)
            {
                var source = AnalyticsEventCategories.IntegrationsIp1dServiceTypePrefix + messagesReceived.Source;
                requests.Add(new AnalyticsEvent(source, messagesReceived.Count));
            }

            var wellKnowns = new Dictionary<string, string>
            {
                {KnownPropertyTypes.Design, "Designs"},
                {KnownPropertyTypes.TradeMark, "Trademarks"},
                {KnownPropertyTypes.Patent, "Patents"}
            };

            requests.AddRange(from ip in ip1dMatchesByType
                              where wellKnowns.Keys.Contains(ip.Key)
                              select new AnalyticsEvent
                              {
                                  Name = AnalyticsEventCategories.IntegrationsIp1dMatchedPrefix + wellKnowns[ip.Key],
                                  Value = ip.Value.ToString()
                              });

            var othersSum = (from ip in ip1dMatchesByType
                             where !wellKnowns.Keys.Contains(ip.Key)
                             select ip.Value).Sum();

            if (othersSum > 0)
            {
                requests.Add(new AnalyticsEvent(AnalyticsEventCategories.IntegrationsIp1dMatchedPrefix + "Others", othersSum));
            }

            return requests;
        }

        async Task<IEnumerable<AnalyticsEvent>> GetIManageAnalytics()
        {
            var externalSetting = await _dbContext.Set<ExternalSettings>().SingleOrDefaultAsync(setting => setting.ProviderName == KnownExternalSettings.IManage);
            if (externalSetting?.IsComplete == true)
            {
                var settings = JsonConvert.DeserializeObject<IManageSettings>(_cryptoService.Decrypt(externalSetting.Settings));
                if (settings.Disabled)
                {
                    return Enumerable.Empty<AnalyticsEvent>();
                }

                var analytics = new List<AnalyticsEvent>();

                analytics.Add(new AnalyticsEvent(AnalyticsEventCategories.IntegrationsIManageView, await (from dmsSection in _dbContext.Set<TopicControl>()
                                                                                                          join c in _dbContext.Set<Criteria>() on
                                                                                                              new
                                                                                                              {
                                                                                                                  CriteriaNo =
                                                                                                                      dmsSection.WindowControl.CriteriaId == null
                                                                                                                          ? (int)dmsSection.WindowControl.NameCriteriaId
                                                                                                                          : (int)dmsSection.WindowControl.CriteriaId
                                                                                                              }
                                                                                                              equals new
                                                                                                              {
                                                                                                                  CriteriaNo = c.Id
                                                                                                              }
                                                                                                              into c1
                                                                                                          from c in c1
                                                                                                          where (dmsSection.Name == KnownCaseScreenTopics.Dms || dmsSection.Name == KnownNameScreenTopics.Dms)
                                                                                                                && (c.RuleInUse != null && c.RuleInUse != 0)
                                                                                                          select 1).AnyAsync()));

                analytics.Add(new AnalyticsEvent(AnalyticsEventCategories.IntegrationsIManageType,
                                                 string.Join(", ",
                                                             settings.Databases.Select(_ => _.IntegrationType).Distinct())));

                return analytics;
            }

            return Enumerable.Empty<AnalyticsEvent>();
        }

        async Task<bool> GetFtfEnabled()
        {
            var externalSetting = await _dbContext.Set<ExternalSettings>().SingleOrDefaultAsync(setting => setting.ProviderName == KnownExternalSettings.FirstToFile);
            if (externalSetting?.IsComplete == true)
            {
                return await (from dmsSection in _dbContext.Set<TopicControl>()
                              join c in _dbContext.Set<Criteria>() on dmsSection.WindowControl.CriteriaId equals c.Id into c1
                              from c in c1
                              where dmsSection.Name == KnownCaseScreenTopics.FirstToFile && c.RuleInUse == 1
                              select 1).AnyAsync();
            }

            return false;
        }
    }
}