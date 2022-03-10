using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Integration.Settings;
using Inprotech.IntegrationServer.PtoAccess.Epo;

namespace Inprotech.IntegrationServer.Api.PtoSettings.Epo
{
    [RequiresApiKey(ExternalApplicationName.InprotechServer, IsOneTimeUse = true)]
    public class EpoIntegrationSettingsController : ApiController
    {
        readonly IEpoAuthClient _epoAuthClient;

        public EpoIntegrationSettingsController(IEpoAuthClient epoAuthClient)
        {
            _epoAuthClient = epoAuthClient;
        }

        [HttpPut]
        [Route("api/eposettings")]
        public async Task<bool> TestOnly(EpoKeys epoKeys)
        {
            return await _epoAuthClient.TestSettings(epoKeys);
        }
    }
}