using System.Collections.Generic;
using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Utilities;
using Newtonsoft.Json;

namespace Inprotech.Setup.Actions
{
    public class ImportExistingReportingServicesSettings : ISetupActionAsync
    {
        const string MsReportingServices = "MSReportingServices";
        const string ProviderName = "ReportingServicesSetting";
        readonly ICryptoService _cryptoService;
        readonly IIwsSettingHelper _iwsSettingHelper;
        string _reportServerBaseUrl;
        string _rootFolder;

        public ImportExistingReportingServicesSettings(ICryptoService cryptoService, IIwsSettingHelper iwsSettingHelper)
        {
            _cryptoService = cryptoService;
            _iwsSettingHelper = iwsSettingHelper;
        }

        public string Description => "Import Existing Reporting Service Settings";
        public bool ContinueOnException => true;

        public async void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            RunAsync(context, eventStream).Wait();
        }

        public async Task RunAsync(IDictionary<string, object> context, IEventStream eventStream)
        {
            var connectionString = (string) context["InprotechAdministrationConnectionString"];

            var ctx = (SetupContext) context;
            var privateKey = ctx.PrivateKey;
            var machineName = (string) context["IwsReportsMachineName"] ?? (string) context["IwsMachineName"];
            _reportServerBaseUrl = (string) context["ReportServiceUrl"];
            _rootFolder = (string) context["ReportServiceEntryFolder"];

            var configuredInWebConfig = (string) context["ReportProvider"] == MsReportingServices
                                        && !string.IsNullOrEmpty(_reportServerBaseUrl)
                                        && !string.IsNullOrEmpty(_rootFolder);

            var configuredInIws = _iwsSettingHelper.IsValidLocalAddress(machineName);

            await TryConnect(connectionString, privateKey, eventStream, configuredInWebConfig, configuredInIws);
        }

        async Task TryConnect(string connectionString, string privateKey, IEventStream eventStream, bool configuredInWebConfig, bool configuredInIws)
        {
            var hasExistingSetting = _iwsSettingHelper.HasExistingSetting(connectionString, ProviderName);
            if (hasExistingSetting)
            {
                eventStream.PublishInformation("Configuration settings need not be imported as it already exists.");
                return;
            }

            if (!configuredInWebConfig && !configuredInIws)
            {
                eventStream.PublishInformation("Could not import as configuration settings of Reporting Services have not been configured.");
                return;
            }

            ReportingServicesSetting rsSetting = null;
            if (configuredInIws)
            {
                var encryptionKey = _iwsSettingHelper.GeneratePrivateKey();
                var result = await CommandLineUtility.RunAsync(Constants.MigrateIWSConfigSettings.MigrateUtilityPath,
                                                               "\"" + encryptionKey + "\" Reports \"" + _iwsSettingHelper.ResolveInstallationLocation() + "\\\"");
                if (result.ExitCode != -1 && result.ExitCode != -9)
                {
                    var output = _cryptoService.Decrypt(encryptionKey, result.Output);
                    var reports = XElement.Parse(output);
                    rsSetting = IwsSettingParser.ParseReportingServicesSetting(reports);
                }
            }

            if ((rsSetting == null || string.IsNullOrEmpty(rsSetting.ReportServerBaseUrl) || string.IsNullOrEmpty(rsSetting.RootFolder)) && configuredInWebConfig)
            {
                rsSetting = rsSetting ?? new ReportingServicesSetting();
                _reportServerBaseUrl = _reportServerBaseUrl.Replace("/ReportService2005.asmx", string.Empty);
                rsSetting.ReportServerBaseUrl = _reportServerBaseUrl;
                rsSetting.RootFolder = _rootFolder;
            }

            if (rsSetting != null)
            {
                var isComplete = !string.IsNullOrEmpty(rsSetting.ReportServerBaseUrl) && !string.IsNullOrEmpty(rsSetting.RootFolder);
                var settingString = _cryptoService.Encrypt(privateKey, JsonConvert.SerializeObject(rsSetting));
                _iwsSettingHelper.SaveExternalSetting(connectionString, settingString, isComplete, ProviderName);
                eventStream.PublishInformation("The configuration settings from Reporting Services in windows services have been imported.");
            }
            else
            {
                eventStream.PublishInformation("Could not import as configuration settings of Reporting Services have not been configured.");
            }
        }

        public class IwsSettingParser
        {
            public static ReportingServicesSetting ParseReportingServicesSetting(XElement reports)
            {
                var reportingServicesElement = reports.Element("reportingServices");
                var securityElement = reportingServicesElement?.Element("security");

                var reportingServicesSetting = new ReportingServicesSetting
                {
                    RootFolder = (string) reportingServicesElement?.Attribute("rootFolder"),
                    ReportServerBaseUrl = (string) reportingServicesElement?.Attribute("reportServerBaseUrl"),
                    ParameterLanguage = (string) reportingServicesElement?.Attribute("parameterLanguage"),
                    Security = new SecurityElement
                    {
                        Username = (string) securityElement?.Attribute("username"),
                        Password = (string) securityElement?.Attribute("password"),
                        Domain = (string) securityElement?.Attribute("domain")
                    }
                };
                return reportingServicesSetting;
            }
        }

        public class ReportingServicesSetting
        {
            public int MessageSize => 105;

            public int Timeout => 10;

            public string RootFolder { get; set; }

            public string ReportServerBaseUrl { get; set; }

            public string ParameterLanguage { get; set; }

            public SecurityElement Security { get; set; }
        }

        public class SecurityElement
        {
            public string Username { get; set; }

            public string Password { get; set; }

            public string Domain { get; set; }
        }
    }
}