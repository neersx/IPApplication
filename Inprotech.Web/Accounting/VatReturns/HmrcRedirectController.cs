using System;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Web.Accounting.VatReturns
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.HmrcVatSubmission)]
    public class HmrcRedirectController : ApiController
    {
        readonly IHmrcAuthenticator _hmrcAuthenticator;

        public HmrcRedirectController(IHmrcAuthenticator hmrcAuthenticator)
        {
            _hmrcAuthenticator = hmrcAuthenticator;
        }

        [HttpGet]
        [Route("hmrc/accounting/vat")]
        public async Task<HttpResponseMessage> RedirectToAccounting()
        {
            var parsed = HttpUtility.ParseQueryString(Request.RequestUri.Query);
            var authCode = parsed.Get("code");
            var stateId = parsed.Get("state");
            var vrn = stateId.Split(',').Last();
            await _hmrcAuthenticator.GetToken(authCode, vrn);

            var newUrl = StripAuthCode(Request.RequestUri.Query);
            
            var newRoute = newUrl.ToLower().Replace("hmrc/accounting/vat", $"{Uri.EscapeUriString("#/accounting/vat")}");
            var response = Request.CreateResponse(HttpStatusCode.Moved);
            response.Headers.Location = new Uri(newRoute);
            return response;            
        }

        string StripAuthCode(string query)
        {
            var param = HttpUtility.ParseQueryString(query);
            var stateId = param.Get("state");
            stateId = stateId.Split(',').First();
            param.Remove("code");
            param.Remove("state");
            param.Add("state", stateId);
            var leftPart = new Uri(Request.RequestUri.GetLeftPart(UriPartial.Path));

            var uri = new Uri(leftPart, $"?{param}");
            return uri.AbsoluteUri;
        }
    }
}