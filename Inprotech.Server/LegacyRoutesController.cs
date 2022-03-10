using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace Inprotech.Server
{
    /// <summary>
    /// This Legacy routes are used by server software versions from version 10 till 13.
    /// They are added here and redirected to correct pages to ensure these Inprotech versions continue to work without any issue on these links.
    /// From version 13.1 onwards all the links are updated and these legacy routes are no more required.
    /// THIS CODE CAN BE REMOVED ONLY AFTER 13.1 BECOMES THE LAST SUPPORTED VERSION.
    /// </summary>
    public class LegacyRoutesController : ApiController
    {
        readonly Dictionary<string, string> _routeReplacements = new Dictionary<string, string>
        {
            { "configuration/events/eventnotetype", "#/configuration/general/events/eventnotetypes"},
            { "configuration/dmsintegration", "#/configuration/dmsintegration"},
            { "bulkcaseimport", "#/bulkcaseimport"},
            { "priorart", "#/priorartold/search"},
            { "reports", "#/reports"},
            { "integration/ptoaccess", "#/integration/ptoaccess/schedules"},
            { "integration/uspto", "#/casecomparison/inbox"},
            { "integration/externalapplication", "#/integration/externalapplication"}
        };

        [HttpGet]
        [Route("configuration/events/eventnotetype" )]
        [Route("configuration/dmsintegration")]
        [Route("bulkcaseimport")]
        [Route("priorart")]
        [Route("reports")]
        [Route("integration/ptoaccess")]
        [Route("integration/uspto")]
        [Route("integration/externalapplication")]
        public HttpResponseMessage ReplaceLegacyRoutes()
        {
            var incomingRoute = Request.GetRouteData().Route.RouteTemplate;
            var wholeRequestUri = Request.RequestUri.AbsoluteUri;

            var newRoute = wholeRequestUri.Replace("/i/", "/apps/").Replace(incomingRoute, _routeReplacements[incomingRoute]);
            
            if (newRoute.EndsWith("/"))
            {
                newRoute = newRoute.Remove(newRoute.Length - 1, 1);
            }

            var response = Request.CreateResponse(HttpStatusCode.Moved);
            response.Headers.Location = new Uri(newRoute);

            return response;
        }
    }
}
