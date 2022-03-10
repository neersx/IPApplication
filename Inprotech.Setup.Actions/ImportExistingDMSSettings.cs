using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Utilities;
using Newtonsoft.Json;

namespace Inprotech.Setup.Actions
{
    public class ImportExistingDmsSettings : ISetupActionAsync
    {
        const string ProviderNameIManage = "IManage";

        static readonly Dictionary<string, string> IntegrationTypesMap =
            new Dictionary<string, string>
            {
                {"iManageCom", IManageSettings.IntegrationTypes.iManageCOM},
                {"Demo", IManageSettings.IntegrationTypes.Demo},
                {"WorkApiV2", IManageSettings.IntegrationTypes.iManageWorkApiV2}
            };

        readonly ICryptoService _cryptoService;
        readonly IIwsSettingHelper _iwsSettingHelper;

        public ImportExistingDmsSettings(ICryptoService cryptoService, IIwsSettingHelper iwsSettingHelper)
        {
            _cryptoService = cryptoService;
            _iwsSettingHelper = iwsSettingHelper;
        }

        public string Description => "Import Existing DMS Settings";
        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            RunAsync(context, eventStream).Wait();
        }

        public async Task RunAsync(IDictionary<string, object> context, IEventStream eventStream)
        {
            var connectionString = (string) context["InprotechAdministrationConnectionString"];
            var ctx = (SetupContext) context;
            var privateKey = ctx.PrivateKey;
            var configuredInWebConfig = _iwsSettingHelper.IsValidLocalAddress((string) context["IwsMachineName"]) || _iwsSettingHelper.IsValidLocalAddress((string) context["IwsDmsMachineName"]);

            await TryImport(connectionString, privateKey, eventStream, configuredInWebConfig);

            TrySquash(connectionString, privateKey, eventStream);
        }

        void TrySquash(string connectionString, string privateKey, IEventStream eventStream)
        {
            var hasExistingSetting = _iwsSettingHelper.HasExistingSetting(connectionString, "IManage");
            if (hasExistingSetting)
            {
                var encryptedSetting = _iwsSettingHelper.GetExistingSettingValue(connectionString, "IManage");
                var settingString = _cryptoService.Decrypt(privateKey, encryptedSetting);
                var setting = JsonConvert.DeserializeObject<IManageSettings>(settingString);
                var serverNames = setting.Databases.Select(_ => _.Server).Distinct().ToList();
                if (serverNames.Count != setting.Databases.Count())
                {
                    setting.Databases = setting.Databases.GroupBy(_ => _.Server.ToLower()).Select(_ => new IManageSettings.SiteDatabaseSettings()
                    {
                        Database = string.Join(",", _.Select(db => db.Database)),
                        AccessTokenUrl = _.First().AccessTokenUrl,
                        AuthUrl = _.First().AuthUrl,
                        CallbackUrl = _.First().CallbackUrl,
                        ClientId = _.First().ClientId,
                        ClientSecret = _.First().ClientSecret,
                        CustomerId = _.First().CustomerId,
                        IntegrationType = _.First().IntegrationType,
                        LoginType = _.First().LoginType,
                        Password = _.First().Password,
                        SiteDbId = _.First().SiteDbId,
                        Server = _.Key
                    }).ToArray();
                    eventStream.PublishInformation("Configuration contained duplicate server records. Duplicates were squashed together. Databases are separated by commas");
                    var newSettingString = _cryptoService.Encrypt(privateKey, JsonConvert.SerializeObject(setting));
                    _iwsSettingHelper.UpdateExistingSetting(connectionString, newSettingString, true, "IManage");
                }
            }
        }

        async Task TryImport(string connectionString, string privateKey, IEventStream eventStream, bool configuredInWebConfig)
        {
            var hasExistingSetting = _iwsSettingHelper.HasExistingSetting(connectionString, ProviderNameIManage);
            if (hasExistingSetting)
            {
                eventStream.PublishInformation("Configuration settings need not be imported as it already exists.");
                return;
            }

            if (!configuredInWebConfig)
            {
                eventStream.PublishInformation("Could not import as configuration settings of Document Management for WorkSite have not been configured.");
                return;
            }

            var encryptionKey = _iwsSettingHelper.GeneratePrivateKey();
            var result = await CommandLineUtility.RunAsync(Constants.MigrateIWSConfigSettings.MigrateUtilityPath,
                                                           "\"" + encryptionKey + "\" Dms \"" + _iwsSettingHelper.ResolveInstallationLocation() + "\\\"");

            if (result.ExitCode == -1)
            {
                eventStream.PublishWarning("Configuration settings could not be imported, the service information could not be located.");
                return;
            }

            if (result.ExitCode == -9)
            {
                eventStream.PublishWarning("Configuration settings could not be imported due to unknown errors.");
                return;
            }

            var output = _cryptoService.Decrypt(encryptionKey, result.Output);
            var config = XElement.Parse(output);

            var iManageSettings = IwsSettingParser.ParseIManageSettings(config);
            if (iManageSettings.IsDemo)
            {
                eventStream.PublishInformation("The configuration settings from Document Management for WorkSite in windows services are invalid for importing.");
                return;
            }

            if (iManageSettings.Databases.Any())
            {
                var settingString = _cryptoService.Encrypt(privateKey, JsonConvert.SerializeObject(iManageSettings));
                _iwsSettingHelper.SaveExternalSetting(connectionString, settingString, true, ProviderNameIManage);
                eventStream.PublishInformation("The configuration settings from Document Management for WorkSite in windows services have been imported.");
            }
            else
            {
                eventStream.PublishInformation("Could not import as configuration settings of Document Management for WorkSite have not been configured.");
            }
        }

        static string MapIntegrationType(string input)
        {
            input = input ?? "iManageCom";

            if (IntegrationTypesMap.ContainsKey(input))
            {
                return IntegrationTypesMap[input];
            }

            return input;
        }

        public class IwsSettingParser
        {
            public static IManageSettings ParseIManageSettings(XElement workSite)
            {
                var @case = workSite.Element("workspace")?.Element("case");
                var nameTypes = workSite.Element("workspace")?.Element("nametypes");
                var siteDbId = 0;
                var loginTypeSetting = (string) workSite.Attribute("loginType");
                var loginType = loginTypeSetting == "OAuth2" ? Integration.DmsIntegration.Component.iManage.IManageSettings.LoginTypes.OAuth : loginTypeSetting;
                var iManageSettings = new IManageSettings
                {
                    Databases = new[]
                    {
                        new IManageSettings.SiteDatabaseSettings
                        {
                            SiteDbId = (siteDbId++).ToString(),
                            Database = string.Join(",", workSite.Element("databases")?.Elements("add")?
                                                                .Select(_ => (string) _.Attribute("name")).Where(_ => !string.IsNullOrWhiteSpace(_))?? new List<string>()),
                            Server = (string) workSite.Attribute("serverName"),
                            Password = (string) workSite.Attribute("impersonationPassword"),
                            CustomerId = (int?) workSite.Attribute("customerId"),
                            LoginType = loginType,
                            IntegrationType = MapIntegrationType((string) workSite.Attribute("version")),
                            CallbackUrl = (string) workSite.Attribute("callbackUrl"),
                            AuthUrl = (string) workSite.Attribute("authUrl"),
                            AccessTokenUrl = (string) workSite.Attribute("accessTokenUrl"),
                            ClientId = (string) workSite.Attribute("clientId"),
                            ClientSecret = (string) workSite.Attribute("clientSecret")
                        }
                    },
                    Case = new IManageSettings.CaseSettings
                    {
                        SearchField = (string) @case?.Attribute("searchField"),
                        SubType = (string) @case?.Attribute("subtype"),
                        SubClass = (string) @case?.Attribute("subclass")
                    },
                    NameTypes = nameTypes?.Elements("add")
                                         .Select(_ => new IManageSettings.NameSettings
                                         {
                                             NameType = (string) _.Attribute("nametype"),
                                             SubClass = (string) _.Attribute("subclass")
                                         }).ToArray()
                };
                if (iManageSettings.Databases.Any(_ => _.IntegrationType == IManageSettings.IntegrationTypes.Demo))
                {
                    iManageSettings.IsDemo = true;
                    iManageSettings.Databases = iManageSettings.Databases?.Where(_ => _.IntegrationType != IManageSettings.IntegrationTypes.Demo).ToArray();
                }

                return iManageSettings;
            }
        }

        public class IManageSettings
        {
            public IManageSettings()
            {
                Databases = new SiteDatabaseSettings[0];
                Case = new CaseSettings();
                NameTypes = new NameSettings[0];
            }

            public bool IsDemo { get; set; }
            public SiteDatabaseSettings[] Databases { get; set; }
            public CaseSettings Case { get; set; }
            public NameSettings[] NameTypes { get; set; }

            public class CaseSettings
            {
                public string SearchField { get; set; }
                public string SubClass { get; set; }
                public string SubType { get; set; }
            }

            public class NameSettings
            {
                public string NameType { get; set; }
                public string SubClass { get; set; }
            }

            public class SiteDatabaseSettings
            {
                public string SiteDbId { get; set; }
                public string Database { get; set; }
                public string Server { get; set; }
                public string IntegrationType { get; set; }
                public string LoginType { get; set; }
                public int? CustomerId { get; set; }
                public string Password { get; set; }
                public string CallbackUrl { get; set; }
                public string AuthUrl { get; set; }
                public string AccessTokenUrl { get; set; }
                public string ClientId { get; set; }
                public string ClientSecret { get; set; }
            }

            public static class IntegrationTypes
            {
                public static string iManageWorkApiV2 = "iManage Work API V2";
                public static string iManageCOM = "iManage COM";
                public static string Demo = "Demo";
            }
        }
    }
}