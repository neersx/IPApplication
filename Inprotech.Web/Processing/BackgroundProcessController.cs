using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Web.ContentManagement;
using Inprotech.Web.Search.Export;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Processing
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/backgroundProcess")]
    public class BackgroundProcessController : ApiController
    {
        readonly IBackgroundProcessMessageClient _backgroundProcessMessage;
        readonly ICpaXmlExporter _cpaXmlExporter;
        readonly ISecurityContext _securityContext;

        public BackgroundProcessController(IBackgroundProcessMessageClient backgroundProcessMessage, ISecurityContext securityContext, ICpaXmlExporter cpaXmlExporter, IExportContentService exportContentService)
        {
            _backgroundProcessMessage = backgroundProcessMessage;
            _securityContext = securityContext;
            _cpaXmlExporter = cpaXmlExporter;
        }

        [HttpGet]
        [Route("list")]
        public IEnumerable<BackgroundProcessMessage> List()
        {
            return _backgroundProcessMessage.Get(new[] {_securityContext.User.Id});
        }

        [HttpPost]
        [Route("cpaXmlExport")]
        public IHttpActionResult DownloadCpaXmlExport(int processId)
        {
            if (_backgroundProcessMessage.Get(new[] {_securityContext.User.Id}, true).All(_ => _.ProcessId != processId))
            {
                return NotFound();
            }

            var response = _cpaXmlExporter.DownloadCpaXmlExport(processId, _securityContext.User.Id);

            return new HttpFileDownloadResponseMessage(response, Request);
        }

        [HttpPost]
        [Route("delete")]
        public bool DeleteBackgroundProcessMessages(int[] processIds)
        {
            return _backgroundProcessMessage.DeleteBackgroundProcessMessages(processIds);
        }
    }
}