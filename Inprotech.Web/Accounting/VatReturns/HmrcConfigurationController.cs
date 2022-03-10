using System;
using System.Linq;
using System.Web.Http;
using Inprotech.Contracts;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Accounting.VatReturns
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.HmrcSaveSettings)]
    [RoutePrefix("api/accounting/vat/settings")]
    public class HmrcConfigurationController : ApiController
    {
        readonly ICryptoService _dataProtectionService;
        readonly IDbContext _dbContext;

        public HmrcConfigurationController(IDbContext dbContext, ICryptoService dataProtectionService)
        {
            _dbContext = dbContext;
            _dataProtectionService = dataProtectionService;
        }

        [HttpGet]
        [Route("view")]
        public dynamic GetSettings()
        {
            var externalSetting = _dbContext.Set<ExternalSettings>().SingleOrDefault(setting => setting.ProviderName == KnownExternalSettings.HmrcVatSettings);
            if (externalSetting == null) return new HmrcVatSettings();

            var hmrcSettings = JObject.Parse(externalSetting.Settings).ToObject<HmrcVatSettings>();
            hmrcSettings.ClientId = _dataProtectionService.Decrypt(hmrcSettings.ClientId);
            hmrcSettings.ClientSecret = null;

            return new
            {
                HmrcSettings = hmrcSettings,
                HasValidSettings = externalSetting.IsComplete
            };
        }

        [HttpPost]
        [Route("save")]
        public dynamic SaveExchangeSettings(HmrcVatSettings hmrcSettings)
        {
            if (hmrcSettings == null) throw new ArgumentNullException(nameof(hmrcSettings));

            if (!string.IsNullOrWhiteSpace(hmrcSettings.ClientId))
            {
                hmrcSettings.ClientId = _dataProtectionService.Encrypt(hmrcSettings.ClientId);
            }

            if (!string.IsNullOrWhiteSpace(hmrcSettings.ClientSecret))
            {
                hmrcSettings.ClientSecret = _dataProtectionService.Encrypt(hmrcSettings.ClientSecret);
            }

            var externalSettings = _dbContext.Set<ExternalSettings>().SingleOrDefault(v => v.ProviderName == KnownExternalSettings.HmrcVatSettings);
            if (externalSettings == null)
            {
                _dbContext.Set<ExternalSettings>()
                          .Add(new ExternalSettings(KnownExternalSettings.HmrcVatSettings)
                          {
                              Settings = JObject.FromObject(hmrcSettings).ToString(),
                              IsComplete = true
                          });
            }
            else
            {
                var t = JObject.Parse(externalSettings.Settings).ToObject<HmrcVatSettings>();
                t.HmrcApplicationName = hmrcSettings.HmrcApplicationName;
                t.ClientId = hmrcSettings.ClientId;
                t.RedirectUri = hmrcSettings.RedirectUri;
                t.IsProduction = hmrcSettings.IsProduction;
                if (!string.IsNullOrWhiteSpace(hmrcSettings.ClientSecret))
                {
                    t.ClientSecret = hmrcSettings.ClientSecret;
                }

                externalSettings.Settings = JObject.FromObject(t).ToString();
                externalSettings.IsComplete = true;
            }

            _dbContext.SaveChanges();

            return new
            {
                Result = new
                {
                    Status = "success"
                }
            };
        }
    }
}