using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Web.Http;
using Inprotech.Tests.E2e.Integration.Fake;
using Inprotech.Web.Configuration.DMSIntegration;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Tests.E2e.Configuration.DMS
{
    [RoutePrefix("api/case")]
    public class WorkspaceManagementController : ApiController
    {
        const string ContentRoot = "Configuration/DMS.V1/";

        [HttpPut]
        [Route("session/login")]
        public IHttpActionResult Login()
        {
            return Ok(new ResponseClass
            {
                Token = Guid.NewGuid().ToString()
            });
        }

        [HttpGet]
        [Route("testCaseFolders/{caseKey:int}")]
        public HttpResponseMessage TestCaseFolders(int caseKey, SettingsController.DmsModel model)
        {
            var filepath = ContentRoot + $"/workspace.json";

            return ResponseHelper.ResponseAsString(filepath,
                                                   content => content);
        }

        [HttpGet]
        [Route("testNameFolders/{nameKey:int}")]
        public HttpResponseMessage TestNameFolders(int caseKey, SettingsController.DmsModel model)
        {
            var filepath = ContentRoot + $"/workspace.json";

            return ResponseHelper.ResponseAsString(filepath,
                                                   content => content);
        }
    }
}
