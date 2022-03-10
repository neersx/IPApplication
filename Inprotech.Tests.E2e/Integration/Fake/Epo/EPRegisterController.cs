using System.Net.Http;
using System.Web.Http;

namespace Inprotech.Tests.E2e.Integration.Fake.Epo
{
    public class EpRegisterController : ApiController
    {
        const string ContentRoot = "epo/register/";

        [HttpGet]
        [Route("integration/epo/epregister/application")]
        public HttpResponseMessage Application(string number = null, string documentId = null, string lng = "en",
            string tab = "doclist", string appNumber = null, string showPdfPage = "all")
        {
            if (!string.IsNullOrWhiteSpace(number))
                return ResponseHelper.ResponseAsString(ContentRoot + "documents.html");

            return ResponseHelper.ResponseAsStream(ContentRoot + "sample.pdf");
        }
    }
}