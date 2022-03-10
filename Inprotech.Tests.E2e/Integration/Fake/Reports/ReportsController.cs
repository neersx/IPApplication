using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace Inprotech.Tests.E2e.Integration.Fake.Reports
{
    public class ReportsController : ApiController
    {
        [HttpGet]
        [Route("reportserver")]
        public HttpResponseMessage GetChildren()
        {
            var queryString = Request.GetQueryNameValuePairs();
            var keyValuePairs = queryString as KeyValuePair<string, string>[] ?? queryString.ToArray();
            var rsCommand = keyValuePairs.SingleOrDefault(_ => _.Key == "rs:Command");
            if (rsCommand.Value == "GetChildren" && keyValuePairs.Any(_ => _.Key == "/inpro/billing/standard"))
            {
                return new HttpResponseMessage(HttpStatusCode.OK)
                {
                    Content = new StringContent("Microsoft SQL Server Reporting Services")
                };
            }

            return new HttpResponseMessage(HttpStatusCode.BadRequest);
        }

        [HttpPost]
        [Route("reportserver")]
        public HttpResponseMessage GetReportContent([FromBody] Dictionary<string, string> Parameters)
        {
            var queryString = Request.GetQueryNameValuePairs();
            var keyValuePairs = queryString as KeyValuePair<string, string>[] ?? queryString.ToArray();
            if (keyValuePairs.All(_ => _.Key != "/inpro/billing/standard/billingworksheet"))
            {
                return new HttpResponseMessage(HttpStatusCode.BadRequest)
                {
                    Content = new StringContent("rsItemNotFound")
                };
            }
            return ResponseHelper.ResponseAsStream("Reports\\BillingWorksheet.pdf");
        }
    }
}