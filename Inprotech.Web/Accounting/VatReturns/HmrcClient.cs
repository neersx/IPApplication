using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Microsoft.Rest;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Web.Accounting.VatReturns
{
    public interface IHmrcClient
    {
        Task<ObligationsResponse> RetrieveObligations(VatObligationsQuery q, string accessToken, HttpRequestMessage httpRequest);
        Task<dynamic> SubmitVatReturn(VatReturnData data, string vatNo, string accessToken, HttpRequestMessage httpRequest);
        Task<dynamic> GetVatReturn(string vatNo, string periodKey, string accessToken, HttpRequestMessage httpRequest);
    }

    public class HmrcClient : IHmrcClient
    {
        readonly IHmrcSettingsResolver _settings;
        readonly IVatReturnStore _vatReturnStore;
        readonly IFraudPreventionHeaders _fraudPreventionHeaders;

        public HmrcClient(IHmrcSettingsResolver settings, IVatReturnStore vatReturnStore, IFraudPreventionHeaders fraudPreventionHeaders)
        {
            _settings = settings;
            _vatReturnStore = vatReturnStore;
            _fraudPreventionHeaders = fraudPreventionHeaders;
        }

        public async Task<ObligationsResponse> RetrieveObligations(VatObligationsQuery q, string accessToken, HttpRequestMessage httpRequest)
        {
            var jsonData = string.Empty;
            HttpStatusCode? statusCode = null;
            var config = _settings.Resolve();
            var fromDate = q.PeriodFrom.Date.ToString("yyyy-MM-dd");
            var toDate = q.PeriodTo.Date.ToString("yyyy-MM-dd");
            var status = q.GetFulfilled && !q.GetOpen ? @"&status=F" : !q.GetFulfilled && q.GetOpen ? "&status=O" : string.Empty;
            var uri = new Uri(config.BaseUrl + $"/organisations/vat/{q.TaxNo}/obligations?from={fromDate}&to={toDate}{status}");
            using (var handler = new HttpClientHandler {UseCookies = false})
            using (var client = new HttpClient(handler) {BaseAddress = uri})
            using (var request = new HttpRequestMessage(HttpMethod.Get, uri))
            {
                var invocationId = ServiceClientTracing.NextInvocationId.ToString();
                ServiceClientTracing.Enter(invocationId, this, "Hmrc-Vat-Mtd:GET", new Dictionary<string, object>());

                client.NoTimeout();

                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
                request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/vnd.hmrc.1.0+json"));
                _fraudPreventionHeaders.Include(request, httpRequest);
                ServiceClientTracing.SendRequest(invocationId, request);

                using (var response = await client.SendAsync(request, HttpCompletionOption.ResponseContentRead))
                {
                    ServiceClientTracing.ReceiveResponse(invocationId, response);

                    if (response.Content != null)
                    {
                        statusCode = response.StatusCode;
                        jsonData = await response.Content.ReadAsStringAsync();

                        if (!response.IsSuccessStatusCode)
                        {
                            ServiceClientTracing.Error(invocationId, new HttpOperationException($"Operation returned an invalid status code '{response.StatusCode}'")
                            {
                                Request = new HttpRequestMessageWrapper(request, null),
                                Response = new HttpResponseMessageWrapper(response, jsonData)
                            });

                            if (response.StatusCode != HttpStatusCode.Unauthorized)
                            {
                                var error = JObject.Parse(jsonData);
                                throw new HttpRequestException($"Response status code does not indicate success: {(int) statusCode} ({response.ReasonPhrase}) - {error["message"]}");
                            }

                            return new ObligationsResponse
                            {
                                Status = statusCode,
                                Data = null
                            };
                        }

                        ServiceClientTracing.Exit(invocationId, jsonData);
                    }
                }
            }

            var data = JsonConvert.DeserializeObject<VatObligations>(jsonData).Obligations.OrderByDescending(_ => _.Due);
            foreach (var vatObligation in data)
            {
                vatObligation.HasLogErrors = _vatReturnStore.HasLogErrors(q.TaxNo, vatObligation.PeriodKey);
            }

            return new ObligationsResponse
            {
                Status = statusCode,
                Data = data
            };
        }

        public async Task<dynamic> SubmitVatReturn(VatReturnData data, string vatNo, string accessToken, HttpRequestMessage httpRequest)
        {
            var config = _settings.Resolve();
            var uri = new Uri(config.BaseUrl + $"/organisations/vat/{vatNo}/returns");

            using (var handler = new HttpClientHandler {UseCookies = false})
            using (var client = new HttpClient(handler) {BaseAddress = uri})
            using (var request = new HttpRequestMessage(HttpMethod.Post, uri))
            {
                var invocationId = ServiceClientTracing.NextInvocationId.ToString();
                ServiceClientTracing.Enter(invocationId, this, "Hmrc-Vat-Mtd:POST", new Dictionary<string, object>());

                client.NoTimeout();

                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
                request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/vnd.hmrc.1.0+json"));
                _fraudPreventionHeaders.Include(request, httpRequest);
                var payLoad = JsonConvert.SerializeObject(data, new JsonSerializerSettings
                {
                    ContractResolver = new DefaultContractResolver
                    {
                        NamingStrategy = new CamelCaseNamingStrategy()
                    }
                });
                request.Content = new StringContent(payLoad, Encoding.UTF8, "application/json");

                ServiceClientTracing.SendRequest(invocationId, request);

                var response = await client.SendAsync(request);

                ServiceClientTracing.ReceiveResponse(invocationId, response);

                var result = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    ServiceClientTracing.Error(invocationId, new HttpOperationException($"Operation returned an invalid status code '{response.StatusCode}'")
                    {
                        Request = new HttpRequestMessageWrapper(request, null),
                        Response = new HttpResponseMessageWrapper(response, result)
                    });

                    if (response.StatusCode != HttpStatusCode.BadRequest && response.StatusCode != HttpStatusCode.Forbidden)
                        response.EnsureSuccessStatusCode();
                }
                ServiceClientTracing.Exit(invocationId, response.Content);
                return
                    new
                    {
                        IsSuccessful = response.IsSuccessStatusCode,
                        Data = JsonConvert.DeserializeObject<dynamic>(result)
                    };
            }
        }

        public async Task<dynamic> GetVatReturn(string vatNo, string periodKey, string accessToken, HttpRequestMessage httpRequest)
        {
            var config = _settings.Resolve();
            var uri = new Uri(config.BaseUrl + $"/organisations/vat/{vatNo}/returns/{periodKey}");
            using (var handler = new HttpClientHandler {UseCookies = false})
            using (var client = new HttpClient(handler) {BaseAddress = uri})
            using (var request = new HttpRequestMessage(HttpMethod.Get, uri))
            {
                var invocationId = ServiceClientTracing.NextInvocationId.ToString();
                ServiceClientTracing.Enter(invocationId, this, "Hmrc-Vat-Mtd:POST", new Dictionary<string, object>());
                client.NoTimeout();
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
                request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/vnd.hmrc.1.0+json"));
                _fraudPreventionHeaders.Include(request, httpRequest);

                ServiceClientTracing.SendRequest(invocationId, request);
                var response = await client.SendAsync(request, HttpCompletionOption.ResponseContentRead);
                ServiceClientTracing.ReceiveResponse(invocationId, response);
                var result = await response.Content.ReadAsStringAsync();
                HttpStatusCode? statusCode = response.StatusCode;

                if (!response.IsSuccessStatusCode)
                {
                    ServiceClientTracing.Error(invocationId, new HttpOperationException($"Operation returned an invalid status code '{response.StatusCode}'")
                    {
                        Request = new HttpRequestMessageWrapper(request, null),
                        Response = new HttpResponseMessageWrapper(response, result)
                    });

                    if (response.StatusCode != HttpStatusCode.BadRequest && response.StatusCode != HttpStatusCode.Forbidden)
                        response.EnsureSuccessStatusCode();

                    return new
                    {
                        Status = statusCode,
                        Error = JsonConvert.DeserializeObject<dynamic>(result)
                    };
                }
                ServiceClientTracing.Exit(invocationId, response.Content);

                var i = JsonConvert.DeserializeObject<VatReturnData>(result);
                var data = new[]
                {
                    i.VatDueSales,
                    i.VatDueAcquisitions,
                    i.TotalVatDue,
                    i.VatReclaimedCurrPeriod,
                    i.NetVatDue,
                    i.TotalValueSalesExVAT,
                    i.TotalValuePurchasesExVAT,
                    i.TotalValueGoodsSuppliedExVAT,
                    i.TotalAcquisitionsExVAT
                };

                return
                    new
                    {
                        Status = statusCode,
                        Data = data
                    };
            }
        }
    }
}