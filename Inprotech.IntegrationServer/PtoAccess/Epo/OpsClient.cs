using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;

namespace Inprotech.IntegrationServer.PtoAccess.Epo
{
    public interface IOpsClient
    {
        Task<string> DownloadApplicationData(OpsClient.DownloadByNumberType type, string refNumber);
    }

    public class OpsClient : IOpsClient
    {
        readonly IEpoSettings _epoSettings;
        readonly IEpoAuthClient _epoAuthClient;

        string _authToken;

        const string RelativePath = "{0}/epodoc/{1}/biblio,events,procedural-steps";

        public enum DownloadByNumberType
        {
            Application,
            Publication
        }

        readonly Dictionary<DownloadByNumberType, string> _numberTypeUri = new Dictionary<DownloadByNumberType, string>
        {
            {DownloadByNumberType.Application, "application"},
            {DownloadByNumberType.Publication, "publication"}
        };

        public OpsClient(IEpoSettings epoSettings, IEpoAuthClient epoAuthClient)
        {
            _epoSettings = epoSettings;
            _epoAuthClient = epoAuthClient;
        }

        public async Task<string> DownloadApplicationData(DownloadByNumberType type, string refNumber)
        {
            refNumber = Utility.FormatEpNumber(refNumber);

            var path = string.Format(RelativePath, _numberTypeUri[type], refNumber);

            var uri = new Uri(new Uri(_epoSettings.EpoBaseApiUrl), new Uri(path, UriKind.Relative));

            return await DownloadXmlString(uri);
        }

        async Task<string> DownloadXmlString(Uri uri)
        {
            using (var handler = new HttpClientHandler { UseCookies = false })
            using (var client = new HttpClient(handler) { BaseAddress = uri })
            using (var request = new HttpRequestMessage(HttpMethod.Get, uri))
            {
                client.NoTimeout();

                if (string.IsNullOrEmpty(_authToken))
                    _authToken = await _epoAuthClient.GetAccessToken();

                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _authToken);
                request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/xml"));

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
    }
}