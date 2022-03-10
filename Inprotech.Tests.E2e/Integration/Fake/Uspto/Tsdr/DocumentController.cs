using System.Linq;
using System.Net.Http;
using System.Web.Http;

namespace Inprotech.Tests.E2e.Integration.Fake.Uspto.Tsdr
{
    public class DocumentController : ApiController
    {
        [HttpGet]
        [Route("integration/uspto/tsdr/ts/cd/casedocs/bundle.xml")]
        public HttpResponseMessage ListDocsBySerialNumber(string sn)
        {
            return ResponseHelper.ResponseAsString("uspto/tsdr/86440740_DocumentsList.xml");
        }
        [HttpGet]
        [Route("integration/uspto/tsdr/ts/cd/casedocs/bundle.xml")]
        public HttpResponseMessage ListDocsByRegistrationNumber(string rn)
        {
            return ResponseHelper.ResponseAsString("uspto/tsdr/86440740_DocumentsList.xml");
        }

        readonly string[] _availableDocs = {"COA20150211095149", "DSC20141113055517"};

        [HttpGet]
        [Route("integration/uspto/Tsdr/sn{serialNumber}/{documentId}/download.pdf")]
        public HttpResponseMessage Document(string serialNumber, string documentId)
        {
            var docId = _availableDocs.Contains(documentId + ".pdf") ? documentId : _availableDocs.First();

            return ResponseHelper.ResponseAsStream(string.Format("uspto/tsdr/{0}.pdf", docId));
        }
    }
}