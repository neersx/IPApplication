using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Integration.Settings;
using Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr;

namespace Inprotech.IntegrationServer.Api.PtoSettings.Uspto
{
    [RequiresApiKey(ExternalApplicationName.InprotechServer, IsOneTimeUse = true)]
    public class TsdrIntegrationSettingsController : ApiController
    {
        readonly ITsdrClient _tsdrClient;

        public TsdrIntegrationSettingsController(ITsdrClient tsdrClient)
        {
            _tsdrClient = tsdrClient;
        }

        [HttpPut]
        [Route("api/tsdrsettings")]
        public async Task<bool> TestOnly(TsdrSecret tsdrSecret)
        {
            return await _tsdrClient.TestSettings(tsdrSecret);
        }
    }
}