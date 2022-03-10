using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Integration.Schedules;

namespace Inprotech.Web.Configuration.DMSIntegration
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/dms-integration/settings")]
    [RequiresAccessTo(ApplicationTask.ConfigureDmsIntegration)]
    public class SettingManifestController : ApiController
    {
        readonly ISettingYamlMapper _settingYamlMapper;
        readonly IArtifactsService _artifactsService;
        public SettingManifestController(IArtifactsService artifactsService, ISettingYamlMapper settingYamlMapper)
        {
            _artifactsService = artifactsService;
            _settingYamlMapper = settingYamlMapper;
        }

        [HttpPost]
        [Route("get-yaml")]
        public async Task<HttpResponseMessage> GetYaml(IManageSettings.SiteDatabaseSettings config)
        {
            var yamlString = (await _settingYamlMapper.GetYamlStringForSiteConfig(config)).ToString();

            var compressedResult = await _artifactsService.Compress("manifest.yaml", yamlString);

            var response = new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new ByteArrayContent(compressedResult)
            };
            response.Content.Headers.ContentType = new MediaTypeHeaderValue("application/zip");
            response.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
            {
                FileName = "inprotech-app-manifest.zip"
            };
            response.Headers.Add("x-filename", "inprotech-app-manifest.zip");
            response.Headers.Add("x-filetype", "application/zip");

            return response;
        }
    }
}