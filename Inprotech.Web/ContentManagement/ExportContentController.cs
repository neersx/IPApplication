using System;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.SearchResults.Exporters;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.ContentManagement
{
    [Authorize]
    [RoutePrefix("api/export")]
    public class ExportContentController : ApiController
    {
        readonly IBackgroundProcessMessageClient _backgroundProcessMessage;
        readonly ISecurityContext _securityContext;
        readonly IExportContentService _exportContentService;

        public ExportContentController(IBackgroundProcessMessageClient backgroundProcessMessage,
                                             ISecurityContext securityContext,
                                             IExportContentService exportContentService)
        {
            _backgroundProcessMessage = backgroundProcessMessage;
            _securityContext = securityContext;
            _exportContentService = exportContentService;
        }

        [HttpGet]
        [Route("content/{connectionId}")]
        [NoEnrichment]
        public async Task<int> GenerateContentId(string connectionId)
        {
            return await _exportContentService.GenerateContentId(connectionId);
        }

        [HttpPost]
        [Route("download/content/{contentId:int}")]
        [NoEnrichment]
        public async Task<IHttpActionResult> ContentById(int contentId)
        {
            var content = _exportContentService.GetContentById(contentId);
            _exportContentService.RemoveContent(contentId);
            return new FileStreamResult(content, Request);
        }
        
        [HttpPost]
        [Route("download/process/{processId:int}")]
        [NoEnrichment]
        public async Task<IHttpActionResult> ContentByProcessId(int processId)
        {
            if (_backgroundProcessMessage.Get(new[] {_securityContext.User.Id}, true)
                                         .All(_ => _.ProcessId != processId))
            {
                return NotFound();
            }

            var content = _exportContentService.GetContentByProcessId(processId);

            return new FileStreamResult(content, Request);
        }

        [HttpPost]
        [Route("content/remove/{connectionId}")]
        [NoEnrichment]
        public async Task RemoveContentsByConnection(string connectionId)
        {
            if(string.IsNullOrEmpty(connectionId))
                throw new ArgumentNullException(nameof(connectionId));

            _exportContentService.RemoveContentsByConnection(connectionId);
        }
    }
}
