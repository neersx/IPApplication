using System;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Web.Policing
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.PolicingAdministration)]
    [RoutePrefix("api/policing/dashboard/admin")]
    public class PolicingDashboardAdministrationController : ApiController
    {
        readonly IPolicingBackgroundServer _policingBackgroundServer;

        public PolicingDashboardAdministrationController(IPolicingBackgroundServer policingBackgroundServer)
        {
            if (policingBackgroundServer == null) throw new ArgumentNullException("policingBackgroundServer");

            _policingBackgroundServer = policingBackgroundServer;
        }

        [HttpPost]
        [Route("turnOff")]
        public void TurnOff()
        {
            _policingBackgroundServer.TurnOff();
        }

        [HttpPost]
        [Route("turnOn")]
        public void TurnOn()
        {
            _policingBackgroundServer.TurnOn();
        }
    }
}