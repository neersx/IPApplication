using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Web.Http;
using Inprotech.Tests.E2e.Integration.Fake;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Tests.E2e.Configuration.DMS
{

    [RoutePrefix("api/v1")]
    public class DmsServiceV1Controller : ApiController
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
        [Route("folders/{containerId}/documents")]
        public HttpResponseMessage GetDocuments(string containerId, string scope)
        {
            var folderId = int.Parse(containerId.Split('!').Last());
            var database = containerId.Split('!').First();

            var filepath = ContentRoot + $"/DocumentsInfo/{scope}/{folderId}.json";
            if (!ResponseHelper.FileExists(filepath))
            {
                filepath = ContentRoot + "/DocumentsInfo/default.json";
            }

            return ResponseHelper.ResponseAsString(filepath,
                                                   content => content);
        }

        [HttpGet]
        [Route("workspaces/{containerId}/children")]
        public HttpResponseMessage GetSubFolders(string containerId, string scope)
        {
            var filepath = ContentRoot + $"FoldersInfo/{containerId}.json";
            if (!ResponseHelper.FileExists(filepath))
            {
                filepath = ContentRoot + "FoldersInfo/default.json";
                var aa = File.Exists(filepath);
            }

            return ResponseHelper.ResponseAsString(filepath,
                                                   content => content);
        }

        [HttpGet]
        [Route("workspaces/search")]
        public HttpResponseMessage GetFolders(string scope)
        {
            return ResponseHelper.ResponseAsString(ContentRoot + "/search.json",
                                                   content => content);
        }
    }

    public class ResponseClass
    {
        [JsonProperty(PropertyName = "X-Auth-Token", NamingStrategyType = typeof(DefaultNamingStrategy))]
        public string Token { get; set; }
    }
}