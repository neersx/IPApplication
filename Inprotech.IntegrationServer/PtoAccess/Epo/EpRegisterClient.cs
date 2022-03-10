using System;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Storage;

namespace Inprotech.IntegrationServer.PtoAccess.Epo
{
    public interface IEpRegisterClient
    {
        Task<string> DownloadDocumentsList(string applicationNumber);
        Task DownloadDocument(string applicationNumber, string documentId, string documentName, string mediaType, string sourceUrl, string filePath);
    }

    public class EpRegisterClient : IEpRegisterClient
    {
        readonly IEpoSettings _epoSettings;
        readonly IChunkedStreamWriter _chunkedStreamWriter;
        const string DocumentsListPage = "application?number={0}&lng=en&tab=doclist";
        const string DocumentDownloadPath = "application?documentId={0}&appnumber={1}&showPdfPage=all";

        public EpRegisterClient(IEpoSettings epoSettings, IChunkedStreamWriter chunkedStreamWriter)
        {
            _epoSettings = epoSettings;
            _chunkedStreamWriter = chunkedStreamWriter;
        }

        public async Task<string> DownloadDocumentsList(string applicationNumber)
        {
            if (string.IsNullOrEmpty(applicationNumber)) return null;

            var uriPath = new Uri(string.Format(DocumentsListPage, Utility.FormatEpNumber(applicationNumber)), UriKind.Relative);

            var uri = new Uri(new Uri(_epoSettings.EpoBaseUrl), uriPath);

            return await DownloadHtml(uri);
        }

        public async Task DownloadDocument(string applicationNumber, string documentId, string documentName, string mediaType, string sourceUrl,
            string filePath)
        {
            if (applicationNumber == null) throw new ArgumentNullException(nameof(applicationNumber));
            // media type is unused in EPO.

            var documentPath = new Uri(string.Format(DocumentDownloadPath, documentId, Utility.FormatEpNumber(applicationNumber)), UriKind.Relative);
            var uri = new Uri(new Uri(_epoSettings.EpoBaseUrl), documentPath);

            using (var handler = new HttpClientHandler { UseCookies = false })
            using (var client = new HttpClient(handler) { BaseAddress = uri })
            using (var request = new HttpRequestMessage(HttpMethod.Get, uri))
            {
                client.NoTimeout();
                var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead);

                if (response.StatusCode == HttpStatusCode.BadRequest ||
                    response.StatusCode == HttpStatusCode.NotFound)
                {
                    throw new ExternalDocumentDownloadFailedException(documentName);
                }

                response.EnsureSuccessStatusCode();

                // Efficiently download large file and written to file system without first reading response in memory.
                await _chunkedStreamWriter.Write(filePath,
                    await response.Content.ReadAsStreamAsync());
            }
        }

        static async Task<string> DownloadHtml(Uri documentsUrl)
        {
            var request = (HttpWebRequest)WebRequest.Create(documentsUrl);

            using (var response = (HttpWebResponse)request.GetResponse())
            {
                if (response.StatusCode != HttpStatusCode.OK)
                    return null;

                using (var stream = response.GetResponseStream())
                using (var reader = new StreamReader(stream))
                {
                    return await reader.ReadToEndAsync();
                }
            }
        }
    }
}