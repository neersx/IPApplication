using System;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Settings;

namespace Inprotech.Integration.PtoSettings.Uspto
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoTsdrDataDownload)]
    public class UsptoTsdrSettingsController : ApiController
    {
        readonly IIntegrationServerClient _integrationServerClient;
        readonly ITsdrIntegrationSettings _tsdrIntegrationSettings;

        public UsptoTsdrSettingsController(IIntegrationServerClient integrationServerClient, ITsdrIntegrationSettings tsdrIntegrationSettings)
        {
            _integrationServerClient = integrationServerClient;
            _tsdrIntegrationSettings = tsdrIntegrationSettings;
        }

        [HttpGet]
        [Route("api/configuration/ptosettings/uspto-tsdr")]
        public TsdrSecret Get()
        {
            var key = _tsdrIntegrationSettings.Key;

            return new TsdrSecret(key?.MaskAsAsterisks());
        }

        [HttpPut]
        [Route("api/configuration/ptosettings/uspto-tsdr")]
        public async Task<dynamic> TestOnly(TsdrSecret secret)
        {
            if (secret == null)
            {
                throw new ArgumentNullException(nameof(secret));
            }

            secret = string.IsNullOrWhiteSpace(secret.ApiKey) ? new TsdrSecret(_tsdrIntegrationSettings.Key) : secret;

            var result = await TestKeys(secret);

            return new
            {
                Status = result ? "success" : "error"
            };
        }

        [HttpPost]
        [Route("api/configuration/ptosettings/uspto-tsdr")]
        public async Task<dynamic> TestAndSave(TsdrSecret secret)
        {
            if (secret == null)
            {
                throw new ArgumentNullException(nameof(secret));
            }

            var result = await TestKeys(secret);

            if (result)
            {
                _tsdrIntegrationSettings.Key = secret.ApiKey;
            }

            return new
            {
                Status = result ? "success" : "error"
            };
        }

        async Task<bool> TestKeys(TsdrSecret keys)
        {
            var result = !string.IsNullOrWhiteSpace(keys.ApiKey);
            if (!result)
            {
                return false;
            }

            try
            {
                const string url = "api/tsdrsettings";
                await _integrationServerClient.Put(url, keys);
            }
            catch (Exception)
            {
                result = false;
            }

            return result;
        }
    }
}