using System.Configuration;
using System.Linq;
using Inprotech.Contracts;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;

namespace Inprotech.Web.Accounting.VatReturns
{
    public static class KnownUrls
    {
        public const string Production = "https://api.service.hmrc.gov.uk";
        public const string Test = "https://test-api.service.hmrc.gov.uk";
    }

    public interface IHmrcSettingsResolver
    {
        HmrcVatSettings Resolve();
    }

    public class HmrcSettingsResolver : IHmrcSettingsResolver
    {
        readonly IAppSettingsProvider _appSettingsProvider;
        readonly ICryptoService _cryptoService;
        readonly IDbContext _dbContext;

        public HmrcSettingsResolver(IDbContext dbContext, ICryptoService cryptoService, IAppSettingsProvider appSettingsProvider)
        {
            _dbContext = dbContext;
            _cryptoService = cryptoService;
            _appSettingsProvider = appSettingsProvider;
        }

        public HmrcVatSettings Resolve()
        {
            var externalSetting = _dbContext.Set<ExternalSettings>().SingleOrDefault(s => s.ProviderName == KnownExternalSettings.HmrcVatSettings);
            if (externalSetting == null)
            {
                throw new ConfigurationErrorsException("Required settings have not been configured");
            }

            var setting = JsonConvert.DeserializeObject<HmrcVatSettings>(externalSetting.Settings);

            var vatSettings = new HmrcVatSettings
                              {
                                  HmrcApplicationName = setting.HmrcApplicationName,
                                  RedirectUri = setting.RedirectUri,
                                  ClientId = _cryptoService.Decrypt(setting.ClientId),
                                  ClientSecret = _cryptoService.Decrypt(setting.ClientSecret),
                                  IsProduction = setting.IsProduction,
                                  BaseUrl = setting.IsProduction ? KnownUrls.Production : KnownUrls.Test
                              };

            var baseUrlOverride = _appSettingsProvider["HmrcOverride"];
            if (!string.IsNullOrEmpty(baseUrlOverride))
                vatSettings.BaseUrl = baseUrlOverride;

            return vatSettings;
        }
    }

    public class HmrcVatSettings
    {
        public string RedirectUri { get; set; }
        public string ClientId { get; set; }
        public string ClientSecret { get; set; }
        public bool IsProduction { get; set; }
        public string BaseUrl { get; set; }
        public string HmrcApplicationName { get; set; }
    }
}