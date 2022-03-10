using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;

namespace Inprotech.Web.Portal
{
    [Authorize]
    [RoutePrefix("api/portal")]
    [NoEnrichment]
    public class AppsMenuController : ApiController
    {
        readonly IAppsMenu _appsMenu;

        public AppsMenuController(IAppsMenu appsMenu)
        {
            _appsMenu = appsMenu;
        }
        [HttpGet]
        [Route("menu")]
        public dynamic Menu()
        {
            return _appsMenu.Build();
        }

    }
}
