using System;
using System.Collections.Concurrent;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Web.Http;
using Inprotech.Tests.E2e.Integration.Fake;
using Newtonsoft.Json;

namespace Inprotech.Tests.E2e.Configuration.DMS
{
    public class DmsServiceV2Controller : ApiController
    {
        const string ContentRoot = "Configuration/DMS.V2/";
        static readonly ConcurrentDictionary<string, string> LifeTimeDictionaryToken = new ConcurrentDictionary<string, string>();

        [HttpGet]
        [Route("work/auth/oauth2/authorize/")]
        public IHttpActionResult GetCode(string response_type, string state, string client_id, string scope, string redirect_uri)
        {
            if (string.IsNullOrWhiteSpace(response_type)) throw new ArgumentException(@"Value cannot be null or whitespace.", nameof(response_type));
            if (string.IsNullOrWhiteSpace(state)) throw new ArgumentException(@"Value cannot be null or whitespace.", nameof(state));
            if (string.IsNullOrWhiteSpace(client_id)) throw new ArgumentException(@"Value cannot be null or whitespace.", nameof(client_id));
            if (string.IsNullOrWhiteSpace(scope)) throw new ArgumentException(@"Value cannot be null or whitespace.", nameof(scope));
            if (string.IsNullOrWhiteSpace(redirect_uri)) throw new ArgumentException(@"Value cannot be null or whitespace.", nameof(redirect_uri));

            if (string.IsNullOrWhiteSpace(Request.Headers.UserAgent.ToString()))
            {
                return BadRequest("UserAgent not presented");
            }

            if (redirect_uri.IndexOf("api/dms/imanage/auth/redirect", StringComparison.InvariantCulture) == -1) return BadRequest();

            var code = Guid.NewGuid().ToString();
            var token = Guid.NewGuid().ToString();
            LifeTimeDictionaryToken.TryAdd(code, token);
            var callbackUrl = $"{redirect_uri}?state={state}&code={code}";
            return Redirect(callbackUrl);
        }

        [HttpPost]
        [Route("work/auth/oauth2/token")]
        public IHttpActionResult GetDocuments([FromBody] TokenResponse response)
        {
            if (response == null) throw new ArgumentNullException(nameof(response));

            if (LifeTimeDictionaryToken.TryGetValue(response.code, out var token))
            {
                return Ok(new OAuthTokenResponse {AccessToken = token, ExpiresIn = 1800, RefreshToken = $"", TokenType = "Bearer"});
            }

            return BadRequest();
        }

        [HttpGet]
        [Route("work/api/v2/customers/{customerId}/libraries/{database}/folders/{record}/documents")]
        public HttpResponseMessage GetDocuments(int customerId, string database, string record)
        {
            var folderId = int.Parse(record.Split('!').Last());

            var filepath = ContentRoot + $"/SubFoldersInfo/{database}/{folderId}.json";
            if (!ResponseHelper.FileExists(filepath))
            {
                filepath = ContentRoot + "/SubFoldersInfo/default.json";
            }

            return ResponseHelper.ResponseAsString(filepath,
                                                   content => content);
        }

        [HttpGet]
        [Route("work/api/v2/customers/{customerId}/libraries/{database}/documents/{record}")]
        public HttpResponseMessage GetDocumentById(int customerId, string record, string database)
        {
            var documentId = record.Split('!').Last();

            var filepath = ContentRoot + $"/DocumentsInfo/{database}/{documentId}.json";

            if (!ResponseHelper.FileExists(filepath))
            {
                filepath = ContentRoot + "/DocumentsInfo/default.json";
            }

            return ResponseHelper.ResponseAsString(filepath,
                                                   content => content);
        }

        [HttpGet]
        [Route("work/api/v2/customers/{customerId}/libraries/{database}/documents/{record}/download")]
        public HttpResponseMessage DownloadDocument(int customerId, string record, string database)
        {
            var version = int.Parse(record.Split('.').Last());
            var documentId = int.Parse(record.Split('!').Last().Split('.').First());

            return ResponseHelper.ResponseAsString(ContentRoot + "/documents.json",
                                                   content => content);
        }

        [HttpGet]
        [Route("work/api/v2/customers/{customerId}/libraries/{database}/documents/{record}/related-documents")]
        public HttpResponseMessage PopulateRelatedDocuments(int customerId, string database, string record)
        {
            var documentId = record.Split('!').Last();

            var filepath = ContentRoot + $"/DocumentsInfo/relatedDocuments/{database}/{documentId}.json";
            if (!ResponseHelper.FileExists(filepath))
            {
                filepath = ContentRoot + "/DocumentsInfo/relatedDocuments/default.json";
            }

            return ResponseHelper.ResponseAsString(filepath,
                                                   content => content);
        }

        [HttpGet]
        [Route("work/api/v2/customers/{customerId}/libraries/{database}/folders/{containerId}/children")]
        public HttpResponseMessage GetSubFolders(int customerId, string database, string containerId)
        {
            var filepath = ContentRoot + $"FoldersInfo/{database}/{containerId}.json";
            if (!ResponseHelper.FileExists(filepath))
            {
                filepath = ContentRoot + "FoldersInfo/default.json";
                var aa = File.Exists(filepath);
            }

            return ResponseHelper.ResponseAsString(filepath,
                                                   content => content);
        }

        [HttpGet]
        [Route("work/api/v2/customers/{customerId}/libraries/{database}/workspaces/{containerId}/children")]
        public HttpResponseMessage GetWorkspaceSubFolders(int customerId, string database, string containerId)
        {
            var filepath = ContentRoot + $"FoldersInfo/{database}/{containerId}.json";
            if (!ResponseHelper.FileExists(filepath))
            {
                filepath = ContentRoot + "FoldersInfo/default.json";
                var aa = File.Exists(filepath);
            }

            return ResponseHelper.ResponseAsString(filepath,
                                                   content => content);
        }

        [HttpPost]
        [Route("work/api/v2/customers/{customerId}/libraries/{database}/workspaces/search")]
        public HttpResponseMessage GetFolders(int customerId, [FromBody] dynamic parameters)
        {
            return ResponseHelper.ResponseAsString(ContentRoot + "/search.json",
                                                   content => content);
        }

        public class TokenResponse
        {
            public string grant_type { get; set; }
            public string code { get; set; }
            public string client_secret { get; set; }
            public string client_id { get; set; }
            public string redirect_uri { get; set; }
        }

        public class OAuthTokenResponse
        {
            [JsonProperty("token_type")]
            public string TokenType { get; set; }

            [JsonProperty("expires_in")]
            public int ExpiresIn { get; set; }

            [JsonProperty("refresh_token")]
            public string RefreshToken { get; set; }

            [JsonProperty("access_token")]
            public string AccessToken { get; set; }
        }

        public class IManagerException
        {
            [JsonProperty("error")]
            public IManageError Error { get; set; }

            public class IManageError
            {
                [JsonProperty("code")]
                public string Code { get; set; }

                [JsonProperty("code_message")]
                public string CodeMessage { get; set; }
            }
        }
    }
}