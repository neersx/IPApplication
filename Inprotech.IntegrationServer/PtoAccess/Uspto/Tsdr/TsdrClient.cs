using System;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration;
using Inprotech.Integration.Settings;
using Inprotech.IntegrationServer.PtoAccess.Utilities;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr
{
    public interface ITsdrClient
    {
        Task<Tuple<Stream, string>> DownloadStatus(string path);
        Task<string> DownloadDocumentsList(string serialNumber, string registrationNumber);
        Task<bool> TestSettings(TsdrSecret tsdrSecret);
    }

    public class TsdrClient : ITsdrClient
    {
        const string UsptoProvidedSampleSerialNumber = "78787878";
        const string SerialNumberDocsListUrlTemplate = "ts/cd/casedocs/bundle.xml?sn={0}";
        const string RegistrationNumberDocsListUrlTemplate = "ts/cd/casedocs/bundle.xml?rn={0}";

        readonly ITsdrSettings _tsdrSettings;
        readonly IThrottler _throttler;

        public TsdrClient(ITsdrSettings tsdrSettings, IThrottler throttler)
        {
            _tsdrSettings = tsdrSettings;
            _throttler = throttler;
        }

        public async Task<Tuple<Stream, string>> DownloadStatus(string path)
        {
            var uri = new Uri(string.Join("/", _tsdrSettings.TsdrBaseUrl + path));

            return await DownloadStream(uri);
        }

        public async Task<string> DownloadDocumentsList(string serialNumber, string registrationNumber)
        {
            var uriPath = !string.IsNullOrWhiteSpace(serialNumber)
                ? string.Format(SerialNumberDocsListUrlTemplate, OfficialNumbers.ExtractSearchTerm(serialNumber))
                : string.Format(RegistrationNumberDocsListUrlTemplate,
                    OfficialNumbers.ExtractSearchTerm(registrationNumber));

            var uri = new Uri(_tsdrSettings.TsdrBaseUrl + uriPath);

            return await DownloadString(uri);
        }

        public async Task<bool> TestSettings(TsdrSecret tsdrSecret)
        {
            if (string.IsNullOrWhiteSpace(tsdrSecret.ApiKey))
                return false;

            var testUri = new Uri(_tsdrSettings.TsdrBaseUrl + string.Format(SerialNumberDocsListUrlTemplate, UsptoProvidedSampleSerialNumber));

            var xml = await DownloadString(testUri, tsdrSecret.ApiKey);

            return !string.IsNullOrWhiteSpace(xml);
        }

        async Task<string> DownloadString(Uri uri, string apiKeyOverride = null)
        {
            await _throttler.DelayUntilAvailableOrDefault((int) DataSourceType.UsptoTsdr, _tsdrSettings.Delay);

            using (var handler = new HttpClientHandler {UseCookies = false})
            using (var client = new HttpClient(handler) {BaseAddress = uri})
            using (var request = new HttpRequestMessage(HttpMethod.Get, uri))
            {
                client.NoTimeout();
                request.Headers.Add("USPTO-API-KEY", apiKeyOverride ?? _tsdrSettings.ApiKey);
                var response = await client.SendAsync(request, HttpCompletionOption.ResponseContentRead);

                if (response.StatusCode == HttpStatusCode.BadRequest ||
                    response.StatusCode == HttpStatusCode.NotFound)
                {
                    throw new ExternalCaseNotFoundException();
                }

                response.EnsureSuccessStatusCode();

                return await response.Content.ReadAsStringAsync();
            }
        }

        async Task<Tuple<Stream, string>> DownloadStream(Uri uri)
        {
            await _throttler.DelayUntilAvailableOrDefault((int)DataSourceType.UsptoTsdr, _tsdrSettings.Delay);

            using (var handler = new HttpClientHandler { UseCookies = false })
            using (var client = new HttpClient(handler) { BaseAddress = uri })
            using (var request = new HttpRequestMessage(HttpMethod.Get, uri))
            {
                client.NoTimeout();
                request.Headers.Add("USPTO-API-KEY", _tsdrSettings.ApiKey);
                var response = await client.SendAsync(request, HttpCompletionOption.ResponseContentRead);

                if (response.StatusCode == HttpStatusCode.BadRequest ||
                    response.StatusCode == HttpStatusCode.NotFound)
                {
                    throw new ExternalCaseNotFoundException();
                }

                response.EnsureSuccessStatusCode();
                
                var returnFileName = response.Content.Headers.ContentDisposition.FileName;
                var returnStream = await response.Content.ReadAsStreamAsync();

                return new Tuple<Stream, string>(returnStream, returnFileName);
            }
        }
    }
}