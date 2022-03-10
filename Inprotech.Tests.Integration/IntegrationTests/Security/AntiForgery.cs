using System;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Web.Security;
using Inprotech.Infrastructure.Security.AntiForgery;
using Inprotech.Web.Configuration.Core;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Security
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class AntiForgery : IntegrationTest
    {
        HttpResponseMessage MakeApiCall(Uri apiUrl, CookieContainer cookieContainer, object data, string csrfToken = null)
        {
            using (var handler = new HttpClientHandler {CookieContainer = cookieContainer})
            using (var client = new HttpClient(handler) {BaseAddress = apiUrl})
            using (var request = new HttpRequestMessage(HttpMethod.Post, apiUrl))
            {
                request.Headers.Add("Accept", "application/json");

                if (!string.IsNullOrEmpty(csrfToken)) request.Headers.Add(CsrfConfigOptions.HeaderName, csrfToken);

                request.Content = new StringContent(JsonConvert.SerializeObject(data), Encoding.UTF8, "application/json");

                return client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead).Result;
            }
        }

        [Test]
        public void CsrMiddlewareIntegration()
        {
            var ticket = FormsAuthentication.Encrypt(new FormsAuthenticationTicket(Env.LoginUsername, false, 30));
            var uri = new Uri(Env.RootUrl);

            var cookieContainer = new CookieContainer();
            cookieContainer.Add(new Cookie(".CPASSInprotech", ticket, "/", uri.Host));

            var apiUrl = new Uri(uri, "apps/api/" + "configuration/numbertypes");

            var data = new NumberTypeSaveDetails
            {
                NumberTypeCode = "x",
                NumberTypeDescription = "csrf integration"
            };

            //Scenerio 1: Donot send csrf cookie
            var httpResponse = MakeApiCall(apiUrl, cookieContainer, data);

            Assert.AreEqual(HttpStatusCode.BadRequest, httpResponse.StatusCode);
            Assert.AreEqual("Csrf cookie not sent in the request.", httpResponse.ReasonPhrase);

            var csrfToken = AntiForgeryToken.Generate(ticket);

            //Scenerio 2: Send csrf cookie but donot add the csrf token in request header
            cookieContainer.Add(new Cookie(CsrfConfigOptions.CookieName, csrfToken, "/", uri.Host));
            httpResponse = MakeApiCall(apiUrl, cookieContainer, data);

            Assert.AreEqual(HttpStatusCode.BadRequest, httpResponse.StatusCode);
            Assert.AreEqual("Csrf header not present in the request.", httpResponse.ReasonPhrase);

            //Scenerio 3: Send csrf cookie and csrf token in request header but with manipulated request header 
            httpResponse = MakeApiCall(apiUrl, cookieContainer, data, csrfToken + "xyz");

            Assert.AreEqual(HttpStatusCode.BadRequest, httpResponse.StatusCode);
            Assert.AreEqual("Csrf token in the header and auth cookie token doesnot match.", httpResponse.ReasonPhrase);

            //Ideal Scenerio: Send csrf cookie and csrf token in request header
            httpResponse = MakeApiCall(apiUrl, cookieContainer, data, csrfToken);

            Assert.AreEqual(HttpStatusCode.OK, httpResponse.StatusCode);
        }
    }
}