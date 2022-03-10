using System;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Net.Configuration;
using System.Net.Mail;
using System.Threading.Tasks;
using System.Web.Http;
using Autofac;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Filters;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Qa
{
    [RequiresApiKey(ExternalApplicationName.E2E)]
    public class QaSettingsController : ApiController
    {
        readonly IAppSettingsProvider _appSettingsProvider;
        readonly IIntegrationServerClient _integrationServerClient;
        readonly ILogger<QaSettingsController> _logger;
        readonly ILifetimeScope _scope;

        public QaSettingsController(ILogger<QaSettingsController> logger, IIntegrationServerClient integrationServerClient, IAppSettingsProvider appSettingsProvider, ILifetimeScope scope)
        {
            _logger = logger;
            _integrationServerClient = integrationServerClient;
            _appSettingsProvider = appSettingsProvider;
            _scope = scope;
        }

        [HttpPut]
        [NoEnrichment]
        [HandleNullArgument]
        [Route("api/e2e/settings")]
        public SettingsValue Update([FromUri] string key, [FromUri] string context, [FromUri] string configSettingKey, [FromBody] SettingsValue to)
        {
            var config = ConfigurationManager.OpenExeConfiguration(ConfigurationUserLevel.None);
            var currentValue = config.AppSettings.Settings[key]?.Value;
            var instance = config.AppSettings.Settings["InstanceName"].Value;

            _logger.Warning($"Changing on instance[{instance}][{context}] AppSettings[{key}] = {to.Value}, existing value = {currentValue}");

            if (currentValue == null)
            {
                config.AppSettings.Settings.Add(new KeyValueConfigurationElement(key, to.Value));
            }
            else
            {
                config.AppSettings.Settings[key].Value = to.Value;
            }

            config.Save(ConfigurationSaveMode.Modified);

            ConfigurationManager.RefreshSection("appSettings");

            _logger.Warning("AppSettings modified and refreshed.");

            using (var scope = _scope.BeginLifetimeScope())
            {
                var qaAuthSettings = scope.Resolve<QaAuthSettings>();
                if (!string.IsNullOrWhiteSpace(configSettingKey))
                {
                    var settings = scope.Resolve<IConfigSettings>();
                    settings[configSettingKey] = to.Value;

                    _logger.Warning("ConfigSettings modified.");
                }

                qaAuthSettings.Reload();
            }

            _logger.Warning("Reset Auth Settings.");

            return new SettingsValue
            {
                Value = currentValue
            };
        }

        [HttpPut]
        [NoEnrichment]
        [HandleNullArgument]
        [Route("api/e2e/integration-settings")]
        public async Task<SettingsValue> UpdateIntegrationSettings([FromUri] string key, [FromUri] string context, [FromBody] SettingsValue to)
        {
            var instance = _appSettingsProvider["InstanceName"];
            var intergationServerUrl = _appSettingsProvider["IntegrationServerBaseUrl"];

            _logger.Warning($"Changing (from instance='{instance}', api='{intergationServerUrl}api/e2e/settings?key={key}&context={context}') IntegrationServer Settings [{key}] = {to.Value}");
            
            string valueBeforeSaving;
            using (var r = await _integrationServerClient.Put($"api/e2e/settings?key={key}&context={context}", to))
            {
                valueBeforeSaving = await r.Content.ReadAsStringAsync();
            }

            _logger.Warning("IntegrationServer Settings updated.");

            return JsonConvert.DeserializeObject<SettingsValue>(valueBeforeSaving);
        }

        [HttpPut]
        [NoEnrichment]
        [HandleNullArgument]
        [Route("api/e2e/interrupt-schedulers")]
        public async Task InterruptSchedulers([FromBody] JObject any)
        {
            var instance = _appSettingsProvider["InstanceName"];
            var intergationServerUrl = _appSettingsProvider["IntegrationServerBaseUrl"];

            _logger.Warning($"E2E interrupt schedule runner clock (from instance='{instance}', api='{intergationServerUrl}api/e2e/interrupt-schedulers')");

            using (var r = await _integrationServerClient.GetResponse("api/e2e/interrupt-schedulers"))
            {
                r.EnsureSuccessStatusCode();
            }

            _logger.Warning("E2E schedule runner clock interrupted");
        }

        [HttpGet]
        [NoEnrichment]
        [HandleNullArgument]
        [Route("api/e2e/client-root")]
        public SettingsValue ClientRoot()
        {
            _logger.Warning("Requesting client-root");

            var root = Path.GetFullPath(@"client");

            _logger.Warning($"client-root = {root}");

            return new SettingsValue
            {
                Value = root
            };
        }

        [HttpPut]
        [NoEnrichment]
        [HandleNullArgument]
        [Route("api/e2e/mail-settings")]
        public async Task UpdateMailSettings([FromBody] SettingsValue to)
        {
            _logger.Warning($"Requesting mail settings change for Integration server to Folder location {to.Value}");

            using (var r = await _integrationServerClient.Put("api/e2e/mail-settings", to))
            {
                r.EnsureSuccessStatusCode();
            }

            _logger.Warning($"Changing mail settings of Inprotech server to Folder location {to.Value}");

            var mailPickupLocation = to.Value;
            var config = ConfigurationManager.OpenExeConfiguration(ConfigurationUserLevel.None);
            var mailSettings = (MailSettingsSectionGroup) config.GetSectionGroup("system.net/mailSettings");
            if (mailSettings?.Smtp == null) throw new Exception("Cannot find mail settings");

            if (mailSettings.Smtp.DeliveryMethod != SmtpDeliveryMethod.SpecifiedPickupDirectory || mailSettings.Smtp.SpecifiedPickupDirectory.PickupDirectoryLocation != mailPickupLocation)
            {
                mailSettings.Smtp.DeliveryMethod = SmtpDeliveryMethod.SpecifiedPickupDirectory;
                mailSettings.Smtp.SpecifiedPickupDirectory.PickupDirectoryLocation = mailPickupLocation;

                config.Save(ConfigurationSaveMode.Modified, true);

                ConfigurationManager.RefreshSection("mailSettings");

                _logger.Warning("New mail settings of Inprotech server applied");
            }
        }
    }

    public class SettingsValue
    {
        public string Value { get; set; }
    }
}