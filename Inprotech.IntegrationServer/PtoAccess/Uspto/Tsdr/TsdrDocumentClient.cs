using System;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.IntegrationServer.PtoAccess.Utilities;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr
{
    public interface ITsdrDocumentClient
    {
        Task Download(string serialNumber, string objectId, string documentName, string mediaType, string sourceUrl, string filePath);
    }

    public class TsdrDocumentClient : ITsdrDocumentClient
    {
        const string DocumentDownloadUrl = "sn{0}/{1}/download.pdf";
        const string MediaDownloadUrl = "sn{0}/{1}/1/media";

        readonly ITsdrSettings _tsdrSettings;
        readonly IChunkedStreamWriter _chunkedStreamWriter;
        readonly IThrottler _throttler;

        public TsdrDocumentClient(ITsdrSettings tsdrSettings, IChunkedStreamWriter chunkedStreamWriter, IThrottler throttler)
        {
            _tsdrSettings = tsdrSettings;
            _chunkedStreamWriter = chunkedStreamWriter;
            _throttler = throttler;
        }

        public async Task Download(string serialNumber, string objectId, string documentName, string mediaType, string sourceUrl, string filePath)
        {
            await _throttler.DelayUntilAvailableOrDefault((int) DataSourceType.UsptoTsdr, _tsdrSettings.Delay);

            if (!Uri.TryCreate(sourceUrl, UriKind.Absolute, out var uri))
            {
                var downloadPath = string.IsNullOrWhiteSpace(mediaType) ? DocumentDownloadUrl : MediaDownloadUrl;

                uri = new Uri(_tsdrSettings.TsdrBaseDocsUrl +
                              string.Format(downloadPath, OfficialNumbers.ExtractSearchTerm(serialNumber),
                                            OfficialNumbers.ExtractSearchTerm(objectId)));
            }
            
            using (var handler = new HttpClientHandler {UseCookies = false})
            using (var client = new HttpClient(handler) {BaseAddress = uri})
            using (var request = new HttpRequestMessage(HttpMethod.Get, uri))
            {
                client.NoTimeout();

                if (!string.IsNullOrWhiteSpace(sourceUrl))
                {
                    request.Headers.Add("USPTO-API-KEY", _tsdrSettings.ApiKey);
                }

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
    }
}