using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Rest;

namespace Inprotech.Web.DocumentManagement
{
    public interface IUrlTester
    {
        Task TestAuthorizationUrl(string url, HttpMethod method, KeyValuePair<string, string>[] headers = null);
    }

    internal class UrlTester : IUrlTester
    {
        public async Task TestAuthorizationUrl(string url, HttpMethod method, KeyValuePair<string, string>[] headers = null)
        {
            var uri = new Uri(url);
            using (var handler = new HttpClientHandler {UseCookies = true})
            using (var client = new HttpClient(handler) {BaseAddress = uri})
            using (var request = new HttpRequestMessage(method, uri))
            {
                var invocationId = ServiceClientTracing.NextInvocationId.ToString();
                if (headers != null && headers.Any())
                {
                    foreach (var kv in headers)
                    {
                        client.DefaultRequestHeaders.Add(kv.Key,kv.Value);
                    }
                }

                using (var response = await client.SendAsync(request, HttpCompletionOption.ResponseContentRead))
                {
                    ServiceClientTracing.ReceiveResponse(invocationId, response);
                    var jsonData = await response.Content.ReadAsStringAsync();
                    var hasValidationError = response.RequestMessage.RequestUri.AbsoluteUri.Contains("authorize-error");
                    if (!response.IsSuccessStatusCode || hasValidationError)
                    {
                        var errorMessage = hasValidationError ? response.RequestMessage.RequestUri.AbsoluteUri : jsonData;
                        ServiceClientTracing.Error(invocationId,
                                                   new HttpOperationException(
                                                                              $"Operation returned an invalid status code '{response.StatusCode}'")
                                                   {
                                                       Request = new HttpRequestMessageWrapper(request, null),
                                                       Response = new HttpResponseMessageWrapper(response, errorMessage)
                                                   });

                        throw new HttpRequestException(
                                                       $"Response status code does not indicate success: {(int) response.StatusCode} ({response.ReasonPhrase}) - {errorMessage}");
                    }

                    ServiceClientTracing.Exit(invocationId, jsonData);
                }
            }
        }
    }
}