using System.Web.Http;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web
{
    /// <summary>
    /// In app.js, specify initViewController with defaultView to avoid boilerplate code for viewController.
    /// </summary>
    [Authorize]
    [ViewInitialiser]
    public class DefaultViewController : ApiController
    {
        public object Get()
        {
            return null;
        }

        [Route("api/enrichment")]
        public object GetEnrichment()
        {
            return null;
        }
    }
}