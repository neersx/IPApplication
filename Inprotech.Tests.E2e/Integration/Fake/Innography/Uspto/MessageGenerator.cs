using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Newtonsoft.Json;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Encodings;
using Org.BouncyCastle.Crypto.Engines;
using Org.BouncyCastle.OpenSsl;
using ConfigurationManager = System.Configuration.ConfigurationManager;

namespace Inprotech.Tests.E2e.Integration.Fake.Innography.Uspto
{
    class MessageGenerator
    {
        public virtual string GeneratedFilePath => "fake-uspto";

        static readonly Random R = new Random();

        public virtual IEnumerable<dynamic> GenerateMessages(string accountId)
        {
            var services = GetTopRecentlyCreatedServices(3);

            var numberOfMessages = NumberOfMessagesToGenerate();

            var createErrorPdf = Boolean.Parse(ConfigurationManager.AppSettings["includeErrors"]);

            for (var i = 0; i < numberOfMessages; i++)
            {
                var s = services.ElementAt(Next(services.Count));
                var serviceId = s.Key;
                var service = s.Value;

                var app = GetNextApplication(i);
                var appId = app.Summary.AppId;
                var doc = GetNextDocument(app);

                var path = $"i/a/{accountId}/service/uspto/{serviceId}/docs/{appId}";

                var insertError = createErrorPdf && R.Next(0, 3) == 1;

                var pdfLink = new LinkInfo
                {
                    Decrypter = service.DecrypterEncryptedBase64String,
                    Iv = service.IvEncryptedBase64String,
                    Status = insertError ? "error" : "success",
                    Message = insertError ? "Pdf not exists" : null,
                    Type = "pdf",
                    Link = $"http://scp.com/{path}/images/{doc.FileName}?accessKey={RandomString.Next(20)}"
                };

                var biblioLink = new LinkInfo
                {
                    Decrypter = service.DecrypterEncryptedBase64String,
                    Iv = service.IvEncryptedBase64String,
                    Status = "success",
                    Type = "biblio",
                    Link = $"http://scp.com/{path}/biblio_{appId}.json?accessKey={RandomString.Next(20)}"
                };

                yield return new
                {
                    meta = new
                    {
                        service_id = serviceId,
                        service_type = "uspto",
                        event_date = DateTime.Today.ToString("yyyy-MM-dd"),
                        event_timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.ffffff"),
                        status = "success",
                        message = string.Empty
                    },
                    links = new List<LinkInfo>
                    {
                        pdfLink,
                        biblioLink
                    }
                };
            }
        }

        protected virtual (string appId, string appNumber) GetApplicationNumber(int? index = null)
        {
            var usePct = Convert.ToBoolean(R.Next(0, 1));
            var appId = usePct
                ? $"PCTUS{DateTime.Today.ToString("yy")}{R.Next(50000, 60000)}"
                : $"{R.Next(11150000, 11160000)}";

            var appNumber = usePct
                ? "PCT/US" + appId.Remove(0, 5).Substring(2) + "/" + appId.Remove(0, 7)
                : appId.Substring(0, 2) + "/" + appId.Remove(0, 2).Substring(0, 3) + "," + appId.Substring(5);

            return (appId, appNumber);
        }

        BiblioFile GetNextApplication(int index)
        {
            (string appId, string appNumber) = GetApplicationNumber(index);

            var biblioFileName = Path.Combine(GeneratedFilePath, $"biblio_{appId}.json");

            var biblio = File.Exists(biblioFileName)
                ? JsonConvert.DeserializeObject<BiblioFile>(File.ReadAllText(biblioFileName))
                : new BiblioFile();

            biblio.Summary.AppId = appId;
            biblio.Summary.AppNumber = appNumber;
            biblio.Summary.CustomerNumber = "123456";
            biblio.Summary.Title = $"{RandomString.Next(20)} {RandomString.Next(20)} {RandomString.Next(20)} {RandomString.Next(20)}";

            biblio.ForeignPriority.Add(new ForeignPriority
            {
                Country = ForeignPriorityCountries.Next(),
                ForeignPriorityNumber = GetApplicationNumber().appId,
                ForeignPriorityDate = DateTime.Today.ToString("yyyy-MM-dd")
            });

            File.WriteAllText(biblioFileName, JsonConvert.SerializeObject(biblio));

            return biblio;
        }

        ImageFileWrapper GetNextDocument(BiblioFile biblioFile)
        {
            var topImageFileWrapper = biblioFile.ImageFileWrappers.LastOrDefault() ??
                                      new ImageFileWrapper
                                      {
                                          MailDate = "2017-12-01"
                                      };

            var nextMailDate = topImageFileWrapper.MailDateTime.AddDays(R.Next(0, 5));
            if (nextMailDate > DateTime.Today)
                nextMailDate = DateTime.Today;

            var ifw = Documents.IFWs.ElementAt(R.Next(0, Documents.IFWs.Count));

            var newDoc = new ImageFileWrapper
            {
                AppId = biblioFile.Summary.AppId,
                DocCode = ifw.Key,
                DocDesc = ifw.Value,
                DocCategory = Documents.PriorArts.Contains(ifw.Key) ? "PRIOR ART" : "PROSECUTION",
                MailDate = nextMailDate.ToString("yyyy-MM-dd"),
                PageCount = R.Next(1, 5),
                TimeStamp = nextMailDate + DateTime.Today.TimeOfDay,
                RowId = (biblioFile.ImageFileWrappers.Count + 1).ToString(),
                Sequence = biblioFile.ImageFileWrappers.Count(_ => _.MailDateTime == nextMailDate) + 1
            }.CalculatingFileName();

            biblioFile.ImageFileWrappers.Add(newDoc);

            var biblioFileName = Path.Combine(GeneratedFilePath, $"biblio_{biblioFile.Summary.AppId}.json");

            File.WriteAllText(biblioFileName, JsonConvert.SerializeObject(biblioFile));

            return newDoc;
        }

        byte[] RSAEncrypt(byte[] clear, string publicKeyAsPem)
        {
            var engine = new OaepEncoding(new RsaEngine());
            using (var sr = new StringReader(publicKeyAsPem))
            {
                var keyParameter = (AsymmetricKeyParameter)new PemReader(sr).ReadObject();
                engine.Init(true, keyParameter);
            }

            return engine.ProcessBlock(clear, 0, clear.Length);
        }

        public Dictionary<string, Service> GetTopRecentlyCreatedServices(int number, string pattern = "Service-*.txt")
        {
            return (from f in Directory.EnumerateFiles(GeneratedFilePath, pattern)
                    let finfo = new FileInfo(f)
                    let iv = finfo.Name.Split('-')[2]
                    let d = finfo.Name.Split('-')[3].Replace(".txt", string.Empty)
                    orderby finfo.CreationTimeUtc descending
                    select new
                    {
                        ServiceId = finfo.Name.Replace("Service-", string.Empty).Replace(iv, string.Empty).Replace(d, string.Empty).Replace("-", string.Empty).Replace(".txt", string.Empty),
                        PublicKey = File.ReadAllText(f),
                        IVBytes = Encoding.ASCII.GetBytes(iv),
                        DecrypterBytes = Encoding.ASCII.GetBytes(d)
                    }).Take(number)
                      .ToDictionary(k => k.ServiceId, v => new Service
                      {
                          PublicKey = v.PublicKey,
                          IV = v.IVBytes,
                          IvEncryptedBase64String = Convert.ToBase64String(RSAEncrypt(v.IVBytes, v.PublicKey)),
                          Decrypter = v.DecrypterBytes,
                          DecrypterEncryptedBase64String = Convert.ToBase64String(RSAEncrypt(v.DecrypterBytes, v.PublicKey))
                      });
        }

        protected virtual int NumberOfMessagesToGenerate()
        {
            var i = R.Next(0, 3);
            if (i == 0) return 0;
            if (i == 2) return 20;
            return R.Next(0, 20);
        }

        public int Next(int max)
        {
            return R.Next(0, max);
        }
    }
}