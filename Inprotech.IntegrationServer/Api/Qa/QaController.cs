using System;
using System.Collections.Generic;
using System.Configuration;
using System.Net.Configuration;
using System.Net.Mail;
using System.Web.Http;
using Autofac;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.IntegrationServer.BackgroundProcessing;

namespace Inprotech.IntegrationServer.Api.Qa
{
    [RequiresApiKey(ExternalApplicationName.E2E)]
    public class QaController : ApiController
    {
        readonly IEnumerable<IInterrupter> _interrupters;
        readonly ILogger<QaController> _logger;
        readonly ILifetimeScope _scope;

        public QaController(IEnumerable<IInterrupter> interrupters, ILogger<QaController> logger, ILifetimeScope scope)
        {
            _interrupters = interrupters;
            _logger = logger;
            _scope = scope;
        }

        [HttpGet]
        [Route("api/e2e/interrupt-schedulers")]
        public void Interrupt()
        {
            foreach (var interrupter in _interrupters)
                interrupter.Interrupt();
        }

        [HttpPut]
        [Route("api/e2e/settings")]
        public SettingsValue Update([FromUri] string key, [FromUri] string context, [FromBody] SettingsValue to)
        {
            var config = ConfigurationManager.OpenExeConfiguration(ConfigurationUserLevel.None);
            var currentValue = config.AppSettings.Settings[key]?.Value;

            _logger.Warning($"Changing AppSettings ({context}): [{key}] = {to.Value}, existing value = {currentValue}");

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

            using(var scope = _scope.BeginLifetimeScope())
            {
                var qaAuthSettings = scope.Resolve<QaAuthSettings>();
                qaAuthSettings.Reload();
            }

            _logger.Warning("Reset Auth Settings.");

            return new SettingsValue
            {
                Value = currentValue
            };
        }

        [HttpPut]
        [Route("api/e2e/mail-settings")]
        public void UpdateMailSettings([FromBody] SettingsValue to)
        {
            _logger.Warning($"Changing mail settings of Integration server to Folder location {to.Value}");

            var mailPickupLocation = to.Value;
            var config = ConfigurationManager.OpenExeConfiguration(ConfigurationUserLevel.None);
            var mailSettings = (MailSettingsSectionGroup)config.GetSectionGroup("system.net/mailSettings");
            if (mailSettings?.Smtp == null) throw new Exception("Cannot find mail settings");

            if (mailSettings.Smtp.DeliveryMethod != SmtpDeliveryMethod.SpecifiedPickupDirectory || mailSettings.Smtp.SpecifiedPickupDirectory.PickupDirectoryLocation != mailPickupLocation)
            {
                mailSettings.Smtp.DeliveryMethod = SmtpDeliveryMethod.SpecifiedPickupDirectory;
                mailSettings.Smtp.SpecifiedPickupDirectory.PickupDirectoryLocation = mailPickupLocation;

                config.Save(ConfigurationSaveMode.Modified, true);

                ConfigurationManager.RefreshSection("mailSettings");

                _logger.Warning($"New mail settings of Integration server applied");
            }
        }
    }

    public class SettingsValue
    {
        public string Value { get; set; }
    }
}