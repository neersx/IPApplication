using System;
using System.IO;
using System.Linq;
using System.Net;
using System.Threading;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions.Uspto.PrivatePair;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.PtoAccess.Uspto
{
    [TestFixture]
    [Category(Categories.Integration)]
    [ChangeAppSettings(AppliesTo.IntegrationServer, "InnographyOverrides:pp", "http://localhost/e2e/only/")]
    [RebuildsIntegrationDatabase]
    public class UsptoIntegration : IntegrationTest
    {
        void SetupFakeServer(string[] applicationNumbers, string serviceId, string publicKey)
        {
            var url = $"{Env.FakeServerUrl}/only/private-pair/setup";

            CallPost(url, JsonConvert.SerializeObject(new
            {
                SessionId = Guid.NewGuid().ToString(),
                ApplicationNumbers = applicationNumbers,
                ServiceId = serviceId,
                PublicKey = publicKey
            }));
        }

        void CallPost(string apiUrl, string body)
        {
            var request = (HttpWebRequest)WebRequest.Create(apiUrl);

            request.Method = "POST";
            request.ContentType = "application/json";

            using (var writer = new StreamWriter(request.GetRequestStream()))
            {
                writer.Write(body);
            }

            GetResponse(request);
        }

        static void GetResponse(HttpWebRequest request)
        {
            try
            {
                request.GetResponse();
            }
            catch (WebException ex)
            {
                throw new ApiClientException($"{request.Method} {request.RequestUri}", ex);
            }
        }

        (string serviceId, string publicKey) GetService()
        {
            return ("16b70b836a53479aa229387b2946156a", "-----BEGIN PUBLIC KEY-----\r\nMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAti1C6lmz3dxXiI/Fg/c2\r\n6i8mOdUq/gZSkyEpMHMA6gT92NLMc/T5jNnepZpyzCdkZo/mJ2UQBefH5L67wWmy\r\ndHXvsU+W0ToWR/ZkLgXAMVFtOppRX1DqtxmTn63rYzpp+dtmMLKXNX0vptCPeGW4\r\nuRpREGDZNG4W+YI8TVVHMm8VBmTf715XRiMy7o1GCYMVWZ5J3W3cnVQe5bZIbdLb\r\nipGfF2VaWfFDih6hS1esvHE3zLto8yeRqjJ8RSqtV7NUQ/ZorWUiexPHQ6lRLn2W\r\nccJD8tEufX5J4f2Kr7UUu53Xe+gbnmPQov0Wy43iKBfP2cnV4MOu8llf9KHIs1hg\r\nV9ffx/zacTwZ19Rh5/+axERTorvriRAGWv6F4cK3F5xDE9msCefPx/tkIZDGb/Xp\r\ne++M6Z3OcsYhULKMJ9/zeqnzzeoqvTI4gpn6s6QE9gcHeQCNNjDEpoQ5PjIIq7MK\r\nTmY+kE/Y+/iFK4xTAVH1U5JFbqKsb4SzJWkkNec5Ad5f7NrhqW8E3e00QrHGhwBq\r\nbMGIohdnRnxWgsR6vKI/iOreHxkB9KwUyMjx2LqpOMFGvUUzWdP6kbR98hbkZfwv\r\nkn2fXePVeUWI2sDHExOmYLO0/OYXXhDGCftkejrI6ca2VfvxCoSiaaUroUUW/MOh\r\nr9ylDsRD0EpF042YkR+Hg/MCAwEAAQ==\r\n-----END PUBLIC KEY-----");
        }

        [Test]
        [Ignore("e2e-flaky: DR-54707")]
        public void UsptoTest()
        {
            var applicationNumbers = new[] { "123456" };
            var (serviceId, publicKey) = GetService();

            using (var db = new UsptoDataSetup())
            {
                var @case = db.BuildInprotechCase("US", "D", db.CreateFamily());
                db.AddOfficialNumber(@case, "A", applicationNumbers.First());

                db.SetupExternalSettingsForPrivatePair();
                db.SetupExternalSettingsForPrivatePairEnvironmentOverride();
            }

            SetupFakeServer(applicationNumbers, serviceId, publicKey);

            var scheduleId = IntegrationDbSetup.Do(x =>
            {
                var schedule = x.Insert(new Schedule
                {
                    Name = RandomString.Next(20),
                    CreatedBy = 1,
                    CreatedOn = DateTime.Now,
                    DataSourceType = DataSourceType.UsptoPrivatePair,
                    DownloadType = DownloadType.All,
                    NextRun = new DateTime(2000, 1, 1),
                    ExpiresAfter = new DateTime(2000, 1, 1),
                    State = ScheduleState.RunNow,
                    Type = ScheduleType.OnDemand,
                    ExtendedSettings = JsonConvert.SerializeObject(new PrivatePairSchedule
                    {
                        CustomerNumbers = Fixture.String(6)
                    })
                });

                return schedule.Id;
            });

            var now = DateTime.Now;

            InprotechServer.InterruptJobsScheduler();

            while (DateTime.Now - now < TimeSpan.FromMinutes(10))
            {
                Thread.Sleep(TimeSpan.FromSeconds(10));
                using (var db = new IntegrationDbSetup())
                {
                    var schedule = db.IntegrationDbContext.Set<ScheduleExecution>()
                                     .SingleOrDefault(_ => _.ScheduleId == scheduleId);

                    if (schedule?.Finished != null)
                    {
                        break;
                    }
                }
            }

            using (var db = new IntegrationDbSetup())
            {
                var schedule = db.IntegrationDbContext.Set<ScheduleExecution>()
                                 .SingleOrDefault(_ => _.ScheduleId == scheduleId);
                Assert.NotNull(schedule);
                Assert.NotNull(schedule.Finished);
                Assert.AreEqual(applicationNumbers.Length, schedule.CasesIncluded);
                Assert.AreEqual(applicationNumbers.Length, schedule.CasesProcessed);
                Assert.AreEqual(applicationNumbers.Length, schedule.DocumentsIncluded);
                Assert.AreEqual(applicationNumbers.Length, schedule.DocumentsProcessed);

                var documents = db.IntegrationDbContext.Set<Document>().Count(_ => applicationNumbers.Contains(_.ApplicationNumber));

                Assert.AreEqual(applicationNumbers.Length, documents);

                var cases = db.IntegrationDbContext.Set<Case>().Count(_ => applicationNumbers.Contains(_.ApplicationNumber));

                Assert.AreEqual(applicationNumbers.Length, cases);
            }
        }
    }
}