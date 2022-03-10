using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Web.Configuration.DMSIntegration
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/dms-integration/settings")]
    [RequiresAccessTo(ApplicationTask.ConfigureDmsIntegration)]
    public class SettingTestController : ApiController
    {
        readonly ISettingTester _settingTester;
        public SettingTestController(ISettingTester settingTester)
        {
            _settingTester = settingTester;
        }

        [HttpPut]
        [Route("testConnection")]
        public async Task<IEnumerable<ConnectionResponseModel>> TestConnections(ConnectionTestRequestModel settings)
        {
            return await _settingTester.TestConnections(settings);
        }
    }
}
