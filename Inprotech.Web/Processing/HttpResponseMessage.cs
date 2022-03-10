using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Xml;

namespace Inprotech.Web.Processing
{
    public class FileExportResponse
    {
        public XmlDocument Document { get; set; }
        public string ContentType{ get; set; }
        public string FileName{ get; set; }
    }
    
    public class HttpFileDownloadResponseMessage : IHttpActionResult
    {
        readonly FileExportResponse _response;
        readonly HttpRequestMessage _httpRequestMessage;
        HttpResponseMessage _httpResponseMessage;

        public HttpFileDownloadResponseMessage(FileExportResponse response, HttpRequestMessage httpRequestMessage)
        {
            _response = response;
            _httpRequestMessage = httpRequestMessage;
        }

        public Task<HttpResponseMessage> ExecuteAsync(CancellationToken cancellationToken)
        {
            _httpResponseMessage = _httpRequestMessage.CreateResponse(HttpStatusCode.OK);
            _httpResponseMessage.Content = new StringContent(_response.Document.InnerText, Encoding.UTF8, "application/xml");
            _httpResponseMessage.Headers.Add("x-filename", _response.FileName);
            _httpResponseMessage.Content.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment");

            return Task.FromResult(_httpResponseMessage);
        }
    }
}
