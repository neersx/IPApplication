using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Analytics;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.Integration.GoogleAnalytics;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Reminders;
using InprotechKaizen.Model.Security;

namespace Inprotech.IntegrationServer.ExchangeIntegration
{
    public class ExchangeUsageAnalyticsProvider : IAnalyticsEventProvider
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly IExchangeIntegrationSettings _settings;
        readonly IServerTransactionDataQueue _serverTransactionDataQueue;

        public ExchangeUsageAnalyticsProvider(IDbContext dbContext, Func<DateTime> now, IExchangeIntegrationSettings settings, IServerTransactionDataQueue serverTransactionDataQueue)
        {
            _dbContext = dbContext;
            _now = now;
            _settings = settings;
            _serverTransactionDataQueue = serverTransactionDataQueue;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            var today = _now();

            var r = new[]
            {
                new AnalyticsEvent(AnalyticsEventCategories.IntegrationsExchangeDocumentsDeliveredViaExchange, await NumberOfDocumentsDeliveredViaExchange(lastChecked)),
                new AnalyticsEvent(AnalyticsEventCategories.IntegrationsExchangeReminders, await NumberOfRemindersWrittenToMailboxCalendars(lastChecked, today)),
                new AnalyticsEvent(AnalyticsEventCategories.IntegrationsExchangeBillsReviewed, await NumberOfBillsQueuedForReviewed())
            }.Concat(GetExchangeIntegrationStatus());
            
            return r.Where(_ => _.Value != null);
        }

        async Task<int?> NumberOfDocumentsDeliveredViaExchange(DateTime lastChecked)
        {
            var current = await (from ar in _dbContext.Set<CaseActivityRequest>()
                                 join d in _dbContext.Set<Document>() on ar.LetterNo equals d.Id into d1
                                 from d in d1
                                 where d.DeliveryMethodId == KnownDeliveryTypes.SaveDraftEmail
                                       && d.DocumentType == KnownDocumentTypes.DeliveryOnly
                                       && ar.LastModified >= lastChecked
                                 select ar).CountAsync();

            var past = await (from ah in _dbContext.Set<CaseActivityHistory>()
                              join d in _dbContext.Set<Document>() on ah.LetterNo equals d.Id into d1
                              from d in d1
                              where d.DeliveryMethodId == KnownDeliveryTypes.SaveDraftEmail
                                    && d.DocumentType == KnownDocumentTypes.DeliveryOnly
                                    && ah.WhenOccurred >= lastChecked
                              select ah).CountAsync();

            return current + past;
        }

        async Task<int?> NumberOfRemindersWrittenToMailboxCalendars(DateTime lastChecked, DateTime today)
        {
            var isInitialised = _dbContext.Set<SettingValues>().Where(_ => _.SettingId == KnownSettingIds.IsExchangeInitialised);
            var remindersSinceLastChecked = _dbContext.Set<StaffReminder>().Where(_ => _.ReminderDate >= lastChecked);

            var remindersIntegratedWithExchange = await (from sr in remindersSinceLastChecked
                                                         join u in _dbContext.Set<User>() on sr.StaffId equals u.NameId
                                                         join p in _dbContext.PermissionsGrantedAll("TASK", (int) ApplicationTask.ExchangeIntegration, null, today)
                                                             on u.Id equals p.IdentityKey
                                                         where p.CanExecute
                                                         join s in isInitialised on u.Id equals s.User.Id
                                                         select sr).CountAsync();
            return remindersIntegratedWithExchange;
        }
        
        async Task<int?> NumberOfBillsQueuedForReviewed()
        {
            return (await _serverTransactionDataQueue.Dequeue<RawEventData>(TransactionalEventTypes.ExchangeEmailDraftViaApi)).Count();
        }

        IEnumerable<AnalyticsEvent> GetExchangeIntegrationStatus()
        {
            var settings = _settings.ForEndpointTest();
            var analytics = new List<AnalyticsEvent>
            {
                new AnalyticsEvent(AnalyticsEventCategories.IntegrationsExchangeDocumentsDeliveredViaExchangeOption, settings.IsDraftEmailEnabled), 
                new AnalyticsEvent(AnalyticsEventCategories.IntegrationsExchangeRemindersOption, settings.IsReminderEnabled), 
                new AnalyticsEvent(AnalyticsEventCategories.IntegrationsExchangeBillReviewOption, settings.IsBillFinalisationEnabled),
                new AnalyticsEvent(AnalyticsEventCategories.IntegrationsExchangeType, settings.ServiceType)
            };

            return analytics;
        }
    }
}