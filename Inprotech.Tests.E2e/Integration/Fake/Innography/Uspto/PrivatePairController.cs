using System;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Web.Http;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NLog;
using Org.BouncyCastle.Crypto.Engines;
using Org.BouncyCastle.Crypto.Modes;
using Org.BouncyCastle.Crypto.Paddings;
using Org.BouncyCastle.Crypto.Parameters;

namespace Inprotech.Tests.E2e.Integration.Fake.Innography.Uspto
{
    public class Urls
    {
        public const string CreateAccount = "private-pair/account";
        public const string DeleteAccount = "private-pair/account/{accountId}";
        public const string CreateUsptoService = "private-pair/account/{accountId}/service/uspto";
        public const string UsptoServiceId = "private-pair/account/{accountId}/service/uspto/{serviceId}";
        public const string GetDocument = "private-pair/account/{accountId}/service/uspto/{serviceId}/document/{*documentId}";
        public const string GetMessages = "private-pair/account/{accountId}/queue";
    }

    public class PrivatePairController : ApiController
    {
        readonly MessageGenerator _generator;
        readonly Logger _logger = LogManager.GetLogger(typeof(PrivatePairController).FullName);

        public PrivatePairController() : this(new MessageGenerator())
        {
        }

        internal PrivatePairController(MessageGenerator generator)
        {
            _generator = generator;
        }

        [HttpPost]
        [Route(Urls.CreateAccount)]
        public dynamic CreateAccount()
        {
            return LogResult("Create account", response:
                             new
                             {
                                 status = "success",
                                 message = string.Empty,
                                 result = new
                                 {
                                     account_id = Guid.NewGuid().ToString("N"),
                                     account_secret = Guid.NewGuid().ToString("N"),
                                     queue_access_id = Guid.NewGuid().ToString("N"),
                                     queue_access_secret = Guid.NewGuid().ToString("N"),
                                     sqs_region = "US East Coast"
                                 }
                             });
        }

        [HttpDelete]
        [Route(Urls.DeleteAccount)]
        public dynamic DeleteAccount(string accountId)
        {
            return LogResult($"Delete account: {accountId}",
                             response:
                             new
                             {
                                 status = "success",
                                 message = string.Empty,
                                 result = new { }
                             });
        }

        [HttpPost]
        [Route(Urls.CreateUsptoService)]
        public dynamic CreateUsptoService(string accountId, [FromBody] JObject body)
        {
            var serviceId = Guid.NewGuid().ToString("N");

            if (!Directory.Exists(_generator.GeneratedFilePath)) Directory.CreateDirectory(_generator.GeneratedFilePath);

            File.WriteAllText(Path.Combine(_generator.GeneratedFilePath, $"Service-{serviceId}-{RandomString.Next(16)}-{RandomString.Next(32)}.txt"), (string) body["pubkey"]);

            return LogResult($"Create Uspto Service for account {accountId}",
                             body,
                             new
                             {
                                 status = "success",
                                 message = string.Empty,
                                 result = new
                                 {
                                     service_id = serviceId
                                 }
                             });
        }

        [HttpPatch]
        [Route(Urls.UsptoServiceId)]
        public dynamic UpdateUsptoService(string accountId, string serviceId, [FromBody] JObject body)
        {
            return LogResult($"Update Uspto Service for account {accountId}, service {serviceId}",
                             body,
                             new
                             {
                                 status = "success",
                                 message = string.Empty,
                                 result = new { service_id = serviceId }
                             });
        }

        [HttpDelete]
        [Route(Urls.UsptoServiceId)]
        public dynamic DeleteUsptoService(string accountId, string serviceId)
        {
            var publicKey = Directory.GetFiles(_generator.GeneratedFilePath, "Service-*.txt").FirstOrDefault();
            if (!string.IsNullOrWhiteSpace(publicKey))
            {
                File.Delete(publicKey);
            }

            return LogResult($"Delete Uspto Service for account {accountId}, service {serviceId}",
                             response: new
                             {
                                 status = "success",
                                 message = string.Empty,
                                 result = new { }
                             });
        }

        [HttpGet]
        [Route(Urls.GetDocument)]
        public HttpResponseMessage GetDocument(string accountId, string serviceId, string documentId)
        {
            var service = _generator.GetTopRecentlyCreatedServices(1, $"Service-{serviceId}-*.txt")[serviceId];
            var documentName = Path.GetFileName(new Uri(documentId).LocalPath);

            var content = $"Document - {documentName} for Service - {serviceId} and Account - {accountId}";

            if (File.Exists(Path.Combine(_generator.GeneratedFilePath, documentName)))
            {
                content = File.ReadAllText(Path.Combine(_generator.GeneratedFilePath, documentName));
            }

            var enc = EncryptUsingPublicKey(service.IV, service.Decrypter, content);

            var response = Request.CreateResponse(HttpStatusCode.OK);
            response.Content = new ByteArrayContent(enc);
            response.Content.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
            return response;
        }

        [HttpGet]
        [Route(Urls.GetMessages)]
        public dynamic GetMessages(string accountId)
        {
            var messages = _generator.GenerateMessages(accountId).ToArray();

            return LogResult($"GetMessages {accountId}, returning {messages.Length} messages",
                             response: new
                             {
                                 status = "success",
                                 message = string.Empty,
                                 result = new
                                 {
                                     messages
                                 }
                             });
        }

        internal dynamic LogResult(string message, JObject request = null, dynamic response = null)
        {
            var m = new StringBuilder(message);
            m.AppendLine();
            m.AppendLine($"{Request.Method} {Request.RequestUri.PathAndQuery}");
            if (request != null) m.AppendLine(request.ToString(Formatting.Indented));
            if (response != null)
            {
                m.AppendLine("===========================================");
                m.AppendLine(JsonConvert.SerializeObject(response, Formatting.Indented));
                m.AppendLine("===========================================");
            }

            _logger.Debug(m.ToString());

            return response;
        }

        byte[] EncryptUsingPublicKey(byte[] ivBytes, byte[] decrypterBytes, string originalContent)
        {
            return AESEncrypt(Encoding.Default.GetBytes(originalContent), decrypterBytes, ivBytes);
        }

        byte[] AESEncrypt(byte[] input, byte[] key, byte[] iv)
        {
            var aes = new PaddedBufferedBlockCipher(new CbcBlockCipher(new AesEngine()));
            var ivAndKey = new ParametersWithIV(new KeyParameter(key), iv);
            aes.Init(true, ivAndKey);

            var outputBytes = new byte[aes.GetOutputSize(input.Length)];
            var length = aes.ProcessBytes(input, outputBytes, 0);
            aes.DoFinal(outputBytes, length);
            return outputBytes;
        }
    }
}