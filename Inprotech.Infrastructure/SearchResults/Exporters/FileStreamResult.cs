using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;

namespace Inprotech.Infrastructure.SearchResults.Exporters
{
    public class FileStreamResult : IHttpActionResult
    {
        readonly ExportResult _exportResult;
        readonly HttpRequestMessage _httpRequestMessage;
        HttpResponseMessage _httpResponseMessage;

        public FileStreamResult(ExportResult exportResult, HttpRequestMessage httpRequestMessage)
        {
            _exportResult = exportResult;
            _httpRequestMessage = httpRequestMessage;
        }

        public Task<HttpResponseMessage> ExecuteAsync(CancellationToken cancellationToken)
        {
            _httpResponseMessage = _httpRequestMessage.CreateResponse(HttpStatusCode.OK);
            _httpResponseMessage.Content = new ByteArrayContent(_exportResult.Content);
            _httpResponseMessage.Headers.Add("x-filename", _exportResult.FileName);
            _httpResponseMessage.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment");
            _httpResponseMessage.Content.Headers.ContentType = new MediaTypeHeaderValue(_exportResult.ContentType);

            return Task.FromResult(_httpResponseMessage);
        }
    }
}
