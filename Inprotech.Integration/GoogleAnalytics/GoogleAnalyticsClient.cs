using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Integration.GoogleAnalytics.Parameters;

namespace Inprotech.Integration.GoogleAnalytics
{
    public interface IGoogleAnalyticsClient
    {
        Task<string> Post(IGoogleAnalyticsRequest request);
        Task Post(IGoogleAnalyticsRequest[] requests);
    }

    public static class GoogleEndpointAddresses
    {
        //    Measurement Protocol
        //https://developers.google.com/analytics/devguides/collection/protocol/v1

        public const string DebugCollect = "https://www.google-analytics.com/debug/collect";
        public const string Collect = "https://www.google-analytics.com/collect";
        public const string BatchCollect = "https://www.google-analytics.com/batch";
    }

    public class GoogleAnalyticsClient : IGoogleAnalyticsClient
    {
        const int MaxRequestsPerBatch = 20;
        readonly IGoogleAnalyticsSettingsResolver _settings;

        public GoogleAnalyticsClient(IGoogleAnalyticsSettingsResolver settings)
        {
            _settings = settings;
        }

        public async Task<string> Post(IGoogleAnalyticsRequest request)
        {
            AddRequiredParameters(request, _settings.Resolve());

            var api = new Uri(GoogleEndpointAddresses.Collect);
            using (var client = new HttpClient())
            {
                var response = await client.PostAsync(api, await GenerateStringContent(request));

                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsStringAsync();
            }
        }

        public async Task Post(IGoogleAnalyticsRequest[] requests)
        {
            var skip = 0;

            IGoogleAnalyticsRequest[] batch;
            do
            {
                batch = requests.Skip(skip).Take(MaxRequestsPerBatch).ToArray();
                await PostBatch(batch);
                skip += MaxRequestsPerBatch;
            }
            while (batch.Any());
        }

        async Task<string> PostBatch(IGoogleAnalyticsRequest[] requests)
        {
            if (!requests.Any()) return string.Empty;

            if (requests.Length > 20)
            {
                throw new Exception("A maximum of 20 hits can be specified per request.Refer to https://developers.google.com/analytics/devguides/collection/protocol/v1/devguide#batch-limitations");
            }

            var sb = new StringBuilder();
            var tracking = _settings.Resolve();

            foreach (var request in requests)
            {
                AddRequiredParameters(request, tracking);
                sb.AppendLine(await GenerateQueryString(request));
            }

            var api = new Uri(GoogleEndpointAddresses.BatchCollect);
            using (var client = new HttpClient())
            {
                var response = await client.PostAsync(api, new StringContent(sb.ToString()));

                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsStringAsync();
            }
        }

        void AddRequiredParameters(IGoogleAnalyticsRequest req, TrackingId tracking, string version = "1")
        {
            req.Parameters.Add(tracking);
            req.Parameters.Add(new ProtocolVersion(version));
        }

        async Task<StringContent> GenerateStringContent(IGoogleAnalyticsRequest req)
        {
            return new StringContent(await GenerateQueryString(req));
        }

        async Task<string> GenerateQueryString(IGoogleAnalyticsRequest req)
        {
            if (req?.Parameters == null)
            {
                return string.Empty;
            }

            var paramsDictionary = new Dictionary<string, string>();

            foreach (var param in req.Parameters)
            {
                switch (param.ValueType.Name)
                {
                    case "Boolean":

                        paramsDictionary[param.Name] = param.Value == null ? string.Empty : (bool)param.Value ? "1" : "0";
                        break;

                    case "Decimal":
                        paramsDictionary[param.Name] = param.Value == null ? string.Empty : Convert.ToString(param.Value, CultureInfo.InvariantCulture);
                        break;

                    default:
                        paramsDictionary[param.Name] = param.Value == null ? string.Empty : param.Value.ToString();
                        break;
                }
            }

            using (var formUrlEncodedContent = new FormUrlEncodedContent(paramsDictionary))
            {
                return await formUrlEncodedContent.ReadAsStringAsync();
            }
        }
    }
}