using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Documents
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ViewCaseDataComparison)]
    [RoutePrefix("api/casecomparison")]
    public class DownloadDocumentController : ApiController
    {
        readonly IRepository _repository;
        readonly IIntegrationServerClient _integrationServerClient;

        public DownloadDocumentController(IRepository repository, IIntegrationServerClient integrationServerClient)
        {
            _repository = repository;
            _integrationServerClient = integrationServerClient;
        }

        [HttpGet]
        [Route("download")]
        public async Task<HttpResponseMessage> Get(int? id)
        {
            if (id == null) throw new ArgumentNullException(nameof(id));

            var document = _repository.Set<Document>()
                                      .Include(d => d.FileStore)
                                      .Single(n => n.Id == id);

            var fileStoreId = document.FileStore.Id;

            var stream = await _integrationServerClient.DownloadContent("api/filestore/" + fileStoreId);

            var response = new HttpResponseMessage(HttpStatusCode.OK)
                           {
                               Content = new StreamContent(stream)
                           };

            response.Content.Headers.ContentType = new MediaTypeHeaderValue(document.MediaType ?? "application/pdf");

            return response;
        }
    }
}