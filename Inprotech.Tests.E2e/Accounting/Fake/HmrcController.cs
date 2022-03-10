using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using Newtonsoft.Json;

namespace Inprotech.Tests.E2e.Accounting.Fake
{
    [RoutePrefix("hmrc")]
    public class HmrcController : ApiController
    {
        [HttpGet]
        [Route("oauth/authorize")]
        public HttpResponseMessage GetAuthCode()
        {
            return Request.CreateResponse(HttpStatusCode.OK);
        }

        [HttpPost]
        [Route("oauth/token")]
        public dynamic GetToken()
        {
            return new OAuthTokenResponse
            {
                TokenType = "bearer",
                ExpiresIn = 14440,
                RefreshToken = "52432394bc7df76ba759954f16c1d9bd",
                AccessToken = "fce140ff7e2aa2bfddc25adebd435e8f"
            };
        }

        [HttpGet]
        [Route("organisations/vat/{taxNo}/obligations")]
        public dynamic Obligations(string taxNo)
        {
            var obligations = new List<VatObligation>
                              {
                                  new VatObligation { Start = DateTime.Now.AddDays(-56), End = DateTime.Now.AddDays(-28), Due = DateTime.Now.AddDays(-28), Received = DateTime.Now.AddDays(-28), PeriodKey = "18A3", Status = "F"},
                                  new VatObligation { Start = DateTime.Now.AddDays(-14), End = DateTime.Now.AddDays(7), Due = DateTime.Now.AddDays(-7), PeriodKey = "18A1", Status = "O"},
                                  new VatObligation { Start = DateTime.Now.AddDays(7), End = DateTime.Now.AddDays(28), Due = DateTime.Now.AddDays(30), PeriodKey = "18A2", Status = "O"}
                              };
            var results = new VatObligations
            {
                Obligations = obligations
            };
            return results;
        }

        [HttpPost]
        [Route("organisations/vat/{taxNo}/returns")]
        public dynamic SubmitVatReturn(string taxNo)
        {
            return new
                   {
                       processingDate = DateTime.Now,
                       paymentIndicator = "BANK",
                       formBundleNumber = "256660290587",
                       chargeRefNumber = "aCxFaNx0FZsCvyWF"
                   };
        }

        [HttpGet]
        [Route("organisations/vat/{taxNo}/returns/{periodKey}")]
        public dynamic GetVatReturn(string taxNo, string periodKey)
        {
            return new
                   {   
                       periodKey,
                       vatDueSales = 100,
                       vatDueAcquisitions= 100,
                       totalVatDue= 200,
                       vatReclaimedCurrPeriod= 100,
                       netVatDue = 100,
                       totalValueSalesExVAT = 500,
                       totalValuePurchasesExVAT= 500,
                       totalValueGoodsSuppliedExVAT = 500,
                       totalAcquisitionsExVAT= 500
                   };
        }

        class OAuthTokenResponse
        {
            [JsonProperty("token_type")]
            public string TokenType { get; set; }

            [JsonProperty("expires_in")]
            public int ExpiresIn { get; set; }

            [JsonProperty("refresh_token")]
            public string RefreshToken { get; set; }

            [JsonProperty("access_token")]
            public string AccessToken { get; set; }
        }

        class VatObligations
        {
            public IEnumerable<VatObligation> Obligations { get; set; }
        }
        class VatObligation
        {
            public DateTime Start { get; set; }
            public DateTime End { get; set; }
            public DateTime Due { get; set; }
            public DateTime? Received { get; set; }
            public string Status { get; set; }
            public string PeriodKey { get; set; }
        }

    }
    
}