using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.ExchangeIntegration;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json.Linq;

namespace Inprotech.Tests.Integration.EndToEnd.Exchange
{
    internal class ExchangeQueueDbSetup : DbSetup
    {
        public ScenarioData DataSetup(bool addAdditionItems = false, string serviceType = "Ews")
        {
            var loginUser = new Users()
                            .WithLicense(LicensedModule.CasesAndNames)
                            .WithPermission(ApplicationTask.ExchangeIntegrationAdministration)
                            .WithPermission(ApplicationTask.ExchangeIntegration)
                            .Create();

            var name = DbContext.Set<User>().Single(u => u.UserName == loginUser.Username).Name;
            var defaultConfiguration = GetDefaultConfigurationSettings(serviceType);
            var newConfiguration = new ExchangeConfigurationSettings
            {
                Domain = "Journey",
                Password = "&^CE$%GF",
                Server = "https://server.thefirm",
                UserName = "Pigsy",
                ServiceType = serviceType,
                ExchangeGraph = new ExchangeGraph() { ClientSecret = "RTT#$#%T%FGT&UU&", ClientId = "GG123", TenantId = "TID890" }
            };
            var eventData = new Event(Fixture.Integer(), Fixture.String(20));

            var readyRequest = new ExchangeRequestQueueItem
            {
                DateCreated = DateTime.Today,
                SequenceDate = DateTime.Now,
                RequestTypeId = (short)ExchangeRequestType.Add,
                StaffId = name.Id,
                StatusId = (short)ExchangeRequestStatus.Ready,
                Subject = Fixture.String(20),
                Event = eventData,
                Recipients = $"{Fixture.AlphaNumericString(10)};{Fixture.AlphaNumericString(15)};{Fixture.AlphaNumericString(15)}",
                MailBox = Fixture.AlphaNumericString(15)
            };
            var failedRequest = new ExchangeRequestQueueItem
            {
                DateCreated = DateTime.Today,
                SequenceDate = DateTime.Now,
                RequestTypeId = (short)ExchangeRequestType.Add,
                StaffId = name.Id,
                StatusId = (short)ExchangeRequestStatus.Failed,
                Subject = Fixture.String(20),
                Event = eventData,
                Recipients = $"{Fixture.AlphaNumericString(10)};{Fixture.AlphaNumericString(15)};{Fixture.AlphaNumericString(15)}",
                MailBox = Fixture.AlphaNumericString(15)
            };
            var draftRequest = new ExchangeRequestQueueItem
            {
                DateCreated = DateTime.Today,
                SequenceDate = DateTime.Now,
                RequestTypeId = (short)ExchangeRequestType.SaveDraftEmail,
                StaffId = name.Id,
                StatusId = (short)ExchangeRequestStatus.Ready,
                Subject = Fixture.String(20),
                Event = eventData,
                Recipients = $"{Fixture.AlphaNumericString(10)};{Fixture.AlphaNumericString(15)};{Fixture.AlphaNumericString(15)}",
                MailBox = Fixture.AlphaNumericString(15)
            };

            if (addAdditionItems)
            {
                for (var i = 0; i < 50; i++)
                {
                    var item = new ExchangeRequestQueueItem(name.Id, DateTime.Now, DateTime.Today, (short)ExchangeRequestType.Add, (short)ExchangeRequestStatus.Failed);
                    Insert(item);
                }
            }
            var setting = new SettingValues()
            {
                SettingId = 3,
                CharacterValue = Fixture.AlphaNumericString(10),
                User = new User(Fixture.AlphaNumericString(10), false) { NameId = name.Id }
            };

            if (serviceType == "Graph")
            {
                var externalCredentials = new ExternalCredentials
                {
                    User = DbContext.Set<User>().Single(u => u.UserName == loginUser.Username),
                    Password = "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",
                    UserName = loginUser.Username,
                    ProviderName = KnownExternalSettings.ExchangeSetting
                };
                Insert(externalCredentials);
            }

            return new ScenarioData
            {
                User = loginUser,
                ExchangeRequestQueueItem = Insert(readyRequest),
                FailedExchangeRequestQueueItem = Insert(failedRequest),
                DraftExchangeRequestQueueItem = Insert(draftRequest),
                DefaultConfiguration = defaultConfiguration,
                NewConfiguration = newConfiguration,
                Settings = Insert(setting)
            };
        }

        ExchangeConfigurationSettings GetDefaultConfigurationSettings(string serviceType = "Ews")
        {
            var exchangeConfigurationSettings = new ExchangeConfigurationSettings
            {
                Domain = Fixture.String(3),
                Password = "7WfUGefqWHf3bJ+CzAQ9aA==",
                Server = "https://server.thefirm",
                UserName = Fixture.String(20),
                ServiceType = serviceType,
                IsDraftEmailEnabled = true,
                ExchangeGraph = new ExchangeGraph() { ClientSecret = "Tu3FR6WaYrQuFFDWbCL+cqUIt32caworzY5MMeh0XdUIX5l2KkLHIUQjn42FStAC", ClientId = Fixture.AlphaNumericString(10), TenantId = Fixture.AlphaNumericString(10) }
            };

            var externalSetting = DbContext.Set<ExternalSettings>().Single(v => v.ProviderName == KnownExternalSettings.ExchangeSetting);
            externalSetting.Settings = JObject.FromObject(exchangeConfigurationSettings).ToString();

            return exchangeConfigurationSettings;
        }

        public class ScenarioData
        {
            public ExchangeRequestQueueItem ExchangeRequestQueueItem;
            public ExchangeRequestQueueItem FailedExchangeRequestQueueItem;
            public ExchangeRequestQueueItem DraftExchangeRequestQueueItem;
            public TestUser User;
            public ExchangeConfigurationSettings DefaultConfiguration;
            public ExchangeConfigurationSettings NewConfiguration;
            public SettingValues Settings;
        }
    }
}