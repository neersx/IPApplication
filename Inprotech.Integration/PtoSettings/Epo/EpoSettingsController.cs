using System;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Settings;

namespace Inprotech.Integration.PtoSettings.Epo
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ScheduleEpoDataDownload)]
    public class EpoSettingsController : ApiController
    {
        readonly IEpoIntegrationSettings _epoIntegrationSettings;
        readonly IIntegrationServerClient _integrationServerClient;

        public EpoSettingsController(IIntegrationServerClient integrationServerClient, IEpoIntegrationSettings epoIntegrationSettings)
        {
            _integrationServerClient = integrationServerClient;
            _epoIntegrationSettings = epoIntegrationSettings;
        }

        [HttpGet]
        [Route("api/configuration/ptosettings/epo")]
        public EpoKeys Get()
        {
            var keys = _epoIntegrationSettings.Keys;

            keys.ConsumerKey = keys.ConsumerKey?.MaskAsAsterisks();
            keys.PrivateKey = keys.PrivateKey?.MaskAsAsterisks();

            return keys;
        }

        [HttpPut]
        [Route("api/configuration/ptosettings/epo")]
        public async Task<dynamic> TestOnly(EpoKeys epoKeys)
        {
            if (epoKeys == null)
                throw new ArgumentNullException(nameof(epoKeys));

            epoKeys = string.IsNullOrWhiteSpace(epoKeys.ConsumerKey) && string.IsNullOrWhiteSpace(epoKeys.PrivateKey) ? _epoIntegrationSettings.Keys : epoKeys;
            var result = await TestKeys(epoKeys);

            return new
            {
                Status = result ? "success" : "error"
            };
        }

        [HttpPost]
        [Route("api/configuration/ptosettings/epo")]
        public async Task<dynamic> TestAndSave(EpoKeys epoKeys)
        {
            if (epoKeys == null)
                throw new ArgumentNullException(nameof(epoKeys));

            var result = await TestKeys(epoKeys);

            if (result)
            {
                _epoIntegrationSettings.Keys = epoKeys;
            }

            return new
            {
                Status = result ? "success" : "error"
            };
        }

        async Task<bool> TestKeys(EpoKeys keys)
        {
            var result = !string.IsNullOrWhiteSpace(keys.PrivateKey) && !string.IsNullOrWhiteSpace(keys.ConsumerKey);
            if (!result)
            {
                return false;
            }

            try
            {
                const string url = "api/eposettings";
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