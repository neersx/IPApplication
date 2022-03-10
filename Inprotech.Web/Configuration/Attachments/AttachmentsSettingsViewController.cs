using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.DmsIntegration.Component;

namespace Inprotech.Web.Configuration.Attachments
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/attachments")]
    [RequiresAccessTo(ApplicationTask.ConfigureAttachmentsIntegration)]
    public class AttachmentsSettingsViewController : ApiController
    {
        readonly IDmsSettingsProvider _dmsSettingsProvider;
        readonly IAttachmentSettings _settings;

        public AttachmentsSettingsViewController(IAttachmentSettings settings, IDmsSettingsProvider dmsSettingsProvider)
        {
            _settings = settings;
            _dmsSettingsProvider = dmsSettingsProvider;
        }

        [HttpGet]
        [Route("settingsView")]
        public async Task<dynamic> Get()
        {
            var settings = await _settings.Resolve();
            return new
            {
                ViewData = new
                {
                    Settings = settings,
                    HasDmsSettings = await _dmsSettingsProvider.HasSettings()
                }
            };
        }
    }
}