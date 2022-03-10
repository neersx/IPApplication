using System.Net.Http;
using System.Web.Http;

namespace Inprotech.Tests.E2e.Integration.Fake.Epo
{
    public class OpsController : ApiController
    {
        const string ContentRoot = "epo/ops/";

        [HttpGet]
        [Route("integration/epo/ops/application/epodoc/{number}/biblio,events,procedural-steps")]
        [Route("integration/epo/ops/publication/epodoc/{number}/biblio,events,procedural-steps")]
        public HttpResponseMessage EpoDoc(string number)
        {
            return ResponseHelper.ResponseAsString(ContentRoot + "applicationdetails.xml",
                content => content
                    .Replace(
                        "<reg:doc-number>07861016</reg:doc-number>", 
                        "<reg:doc-number>" + number.TrimStart('E', 'P' ) + "</reg:doc-number>"));
        }
    }
}
