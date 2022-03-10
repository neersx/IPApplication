using System.Net.Http;
using System.Web.Http;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Portal
{
    [Authorize]
    [ViewInitialiser]
    public class PortalViewController : ApiController
    {
        public object Get(HttpRequestMessage request)
        {
            return null;
        }
    }
}