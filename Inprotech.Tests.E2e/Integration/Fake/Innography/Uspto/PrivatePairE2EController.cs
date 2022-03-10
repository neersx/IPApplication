using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Tests.E2e.Integration.Fake.Innography.Uspto
{
    [RoutePrefix("only")]
    public class PrivatePairE2EController : ApiController
    {
        static E2ESession _session;
        static E2EMessageGenerator _generator;
        static DateTime _lastMessage = DateTime.Now.AddDays(-1);
        const string e2eSessionFilePath = "e2e-session.txt";

        [HttpPost]
        [Route("private-pair/setup")]
        public bool CreateSession(E2ESession model)
        {
            SaveSessionFile(model);
            _session = model;
            _generator = new E2EMessageGenerator(_session);

            EnsureCleanDirectory();
            if (model.CopyExistingService)
                CopyExistingServices();
            if (!string.IsNullOrEmpty(model.ServiceId) && !string.IsNullOrEmpty(model.PublicKey))
                CreateService(model.ServiceId, model.PublicKey);

            _lastMessage = DateTime.Now.AddDays(-1);
            return true;
        }
        void EnsureCleanDirectory()
        {
            var count = 0;
            while (count<5)
            {
                if (Directory.Exists(_generator.GeneratedFilePath))
                    Directory.Delete(_generator.GeneratedFilePath, true);
                else
                    break;
                count++;
                Task.Delay(TimeSpan.FromSeconds(1));
            }
            
            Directory.CreateDirectory(_generator.GeneratedFilePath);
        }

        void CopyExistingServices()
        {
            var sourcePath = new MessageGenerator().GeneratedFilePath;
            if (Directory.Exists(sourcePath))
            {
                foreach (var file in Directory.EnumerateFiles(sourcePath, "Service-*.txt"))
                {
                    var fileName = Path.GetFileName(file);
                    var destFile = Path.Combine(_generator.GeneratedFilePath, fileName);
                    File.Copy(file, destFile, true);
                }
            }
        }

        void CreateService(string serviceId, string publicKey)
        {
            File.WriteAllText(Path.Combine(_generator.GeneratedFilePath, $"Service-{serviceId}-{RandomString.Next(16)}-{RandomString.Next(32)}.txt"), publicKey);
        }

        [HttpPost]
        [Route(Urls.CreateAccount)]
        public dynamic CreateAccount() => MainController.CreateAccount();

        [HttpDelete]
        [Route(Urls.DeleteAccount)]
        public dynamic DeleteAccount(string accountId) => MainController.DeleteAccount(accountId);

        [HttpPost]
        [Route(Urls.CreateUsptoService)]
        public dynamic CreateUsptoService(string accountId, [FromBody] JObject body) => MainController.CreateUsptoService(accountId, body);

        [HttpPatch]
        [Route(Urls.UsptoServiceId)]
        public dynamic UpdateUsptoService(string accountId, string serviceId, [FromBody] JObject body) => MainController.UpdateUsptoService(accountId, serviceId, body);

        [HttpDelete]
        [Route(Urls.UsptoServiceId)]
        public dynamic DeleteUsptoService(string accountId, string serviceId) => MainController.DeleteUsptoService(accountId, serviceId);

        [HttpGet]
        [Route(Urls.GetDocument)]
        public HttpResponseMessage GetDocument(string accountId, string serviceId, string documentId) => MainController.GetDocument(accountId, serviceId, documentId);

        [HttpGet]
        [Route(Urls.GetMessages)]
        public dynamic GetMessages(string accountId)
        {
            if ((DateTime.Now - _lastMessage).TotalMinutes <= 1)
            {
                return MainController.LogResult($"GetMessages {accountId}, no more messages to send",
                                                response: new
                                                {
                                                    status = "success",
                                                    message = string.Empty,
                                                    result = new
                                                    {
                                                        messages = new string[0]
                                                    }
                                                });
            }

            EnsureGeneratorSession();
            var messages = _generator.GenerateMessages(accountId).ToArray();
            _lastMessage = DateTime.Now;
            return MainController.LogResult($"GetMessages {accountId}, returning {messages.Length} messages",
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

        PrivatePairController MainController => new PrivatePairController(_generator ?? EnsureGeneratorSession()) { RequestContext = RequestContext, Request = Request };

        void SaveSessionFile(E2ESession model)
        {
            File.WriteAllText(e2eSessionFilePath, JsonConvert.SerializeObject(model));
        }

        E2EMessageGenerator EnsureGeneratorSession()
        {
            if (_generator == null)
            {
                if (File.Exists(e2eSessionFilePath))
                {
                    var session = JsonConvert.DeserializeObject<E2ESession>(File.ReadAllText(e2eSessionFilePath));
                    CreateSession(session);
                }
            }
            return _generator;
        }

        public class E2ESession
        {
            public string SessionId { get; set; }

            public string ServiceId { get; set; }
            public string PublicKey { get; set; }
            public List<string> ApplicationNumbers { get; set; }
            public bool CopyExistingService { get; set; }
            public bool HasErrors { get; set; }
        }
    }
}