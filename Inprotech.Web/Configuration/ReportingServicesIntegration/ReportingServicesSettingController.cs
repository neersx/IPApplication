using System;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Reports;
using InprotechKaizen.Model.Components.Integration.ReportingServices;

namespace Inprotech.Web.Configuration.ReportingServicesIntegration
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/reportingservicessetting")]
    [RequiresAccessTo(ApplicationTask.ConfigureReportingServicesIntegration)]
    public class ReportingServicesSettingController : ApiController
    {
        readonly string _passwordMask = "******";
        readonly IReportingServicesSettingsResolver _settingsResolver;
        readonly IReportingServicesSettingsPersistence _settingsPersister;
        readonly IReportClient _reportClient;

        public ReportingServicesSettingController(
            IReportingServicesSettingsResolver settingsResolver,
            IReportingServicesSettingsPersistence settingsPersister, IReportClient reportClient)
        {
            _settingsResolver = settingsResolver;
            _settingsPersister = settingsPersister;
            _reportClient = reportClient;
        }

        [HttpPost]
        [Route("save")]
        public async Task<dynamic> Save(ReportingServicesSetting settings)
        {
            if (settings == null)
            {
                throw new ArgumentNullException(nameof(settings));
            }

            if (!Uri.IsWellFormedUriString(settings.ReportServerBaseUrl, UriKind.Absolute))
            {
                return new {Success = false, InvalidUrl = true};
            }

            settings.ReportServerBaseUrl = settings.ReportServerBaseUrl.TrimEnd('/');
            await SetOldPasswordIfRequired(settings);
            return new
            {
                Success = await _settingsPersister.Save(settings), 
                InvalidUrl = false
            };
        }

        async Task SetOldPasswordIfRequired(ReportingServicesSetting settings)
        {
            if (string.IsNullOrEmpty(settings.Security.Password) || settings.Security.Password != _passwordMask) return;
            var oldSetting = await _settingsResolver.Resolve();
            settings.Security.Password = oldSetting.Security.Password;
        }

        [HttpGet]
        [Route("")]
        public async Task<dynamic> Get()
        {
            var setting = await _settingsResolver.Resolve();
            if (!string.IsNullOrEmpty(setting.Security.Password))
            {
                setting.Security.Password = _passwordMask;
            }

            return new {Settings = setting};
        }

        [HttpPost]
        [Route("connection")]
        public async Task<dynamic> TestConnection(ReportingServicesSetting settings)
        {
            if (settings == null)
            {
                throw new ArgumentNullException(nameof(settings));
            }

            if (!Uri.IsWellFormedUriString(settings.ReportServerBaseUrl, UriKind.Absolute))
            {
                return new
                {
                    Success = false, 
                    InvalidUrl = true
                };
            }

            await SetOldPasswordIfRequired(settings);

            return new
            {
                Success = await _reportClient.TestConnectionAsync(settings), 
                InvalidUrl = false
            };
        }
    }
}