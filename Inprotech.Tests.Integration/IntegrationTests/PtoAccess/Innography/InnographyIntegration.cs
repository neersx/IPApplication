using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using Inprotech.Integration;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions.Innography;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Settings;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.PtoAccess.Innography
{
    [TestFixture]
    [Category(Categories.Integration)]
    [RebuildsIntegrationDatabase]
    public class InnographyIntegration : IntegrationTest
    {
        [TearDown]
        public void Restore()
        {
            UpdateAuthMode();
        }

        void UpdateAuthMode(string auth = "Forms,Windows,Sso")
        {
            DbSetup.Do(x =>
                       {
                           var settings = x.DbContext.Set<ConfigSetting>();

                           var authMode = settings.Single(_ => _.Key == "InprotechServer.AppSettings.AuthenticationMode");

                           authMode.Value = auth;

                           x.DbContext.SaveChanges();
                       });
        }

        [Test]
        public void InnographyIdShouldBeClearedWhenRequired()
        {
            using (var db = new InnographyDataSetup())
            {
                var @case = db.BuildInprotechCase("US", "D", db.CreateFamily());
                var otherEvent = RandomString.Next(20);
                var application = db.CreateDataMappingFor("Application");
                var publication = db.CreateDataMappingFor("Publication");
                var registration = db.CreateDataMappingFor("Registration/Grant");
                var otherEventMapping = db.CreateDataMappingFor(otherEvent);

                //Change - ProperttyType - CpaGlobalIdentifier deleted
                db.AddCpaGlobalIdentifier(@case.Id, "InnographyId1");
                db.ChangePropertyType(@case, "P");
                Assert.AreEqual(0, db.CountCpaGlobalIdentifierFor(@case.Id), "CPAGlobalIdentifier deleted - since case property changed");

                //Change - Country - CpaGlobalIdentifier deleted
                db.AddCpaGlobalIdentifier(@case.Id, "InnographyId1");
                db.ChangeCountry(@case, "AU");
                Assert.AreEqual(0, db.CountCpaGlobalIdentifierFor(@case.Id), "CPAGlobalIdentifier deleted - since country changed");

                //Add - Official number - CpaGlobalIdentifier not deleted
                db.AddCpaGlobalIdentifier(@case.Id, "InnographyId1");
                db.AddOfficialNumber(@case, "A", "123456");
                Assert.AreEqual(1, db.CountCpaGlobalIdentifierFor(@case.Id), "CPAGlobalIdentifier NOT deleted - since current official is newly added");

                //Change - Official number - CpaGlobalIdentifier deleted
                db.ChangeOfficialNumber(@case, "A", "123456", "999999");
                Assert.AreEqual(1, db.CountCpaGlobalIdentifierFor(@case.Id), "CPAGlobalIdentifier deleted - since current official no changed");

                //Delete - Official number - CpaGlobalIdentifier deleted
                db.AddCpaGlobalIdentifier(@case.Id, "InnographyId1");
                db.DeleteOfficialNumber(@case, "A", "999999");
                Assert.AreEqual(1, db.CountCpaGlobalIdentifierFor(@case.Id), "CPAGlobalIdentifier deleted - since current official no is deleted");

                //Add - Event - CpaGlobalIdentifier not deleted 
                db.AddCpaGlobalIdentifier(@case.Id, "InnographyId1");
                db.AddEvent(@case, application, Fixture.Today());
                db.AddEvent(@case, publication, Fixture.Today());
                db.AddEvent(@case, registration, Fixture.Today());
                db.AddEvent(@case, otherEventMapping, Fixture.Today());
                Assert.AreEqual(1, db.CountCpaGlobalIdentifierFor(@case.Id), "CPAGlobalIdentifier NOT deleted - since application date is newly added");

                //Change - Event - CpaGlobalIdentifier deleted for 'Application' 
                db.ChangeEventDate(@case, application, Fixture.PastDate());
                Assert.AreEqual(1, db.CountCpaGlobalIdentifierFor(@case.Id), "CPAGlobalIdentifier NOT deleted - since 'Application' date is deleted");

                //Change - Event - CpaGlobalIdentifier deleted for 'Publication' 
                db.AddCpaGlobalIdentifier(@case.Id, "InnographyId1");
                db.ChangeEventDate(@case, publication, Fixture.PastDate());
                Assert.AreEqual(1, db.CountCpaGlobalIdentifierFor(@case.Id), "CPAGlobalIdentifier NOT deleted - since 'Publication' date is deleted");

                //Change - Event - CpaGlobalIdentifier deleted for 'Registration/Grant' 
                db.AddCpaGlobalIdentifier(@case.Id, "InnographyId1");
                db.ChangeEventDate(@case, registration, Fixture.PastDate());
                Assert.AreEqual(1, db.CountCpaGlobalIdentifierFor(@case.Id), "CPAGlobalIdentifier NOT deleted - since 'Registration/Grant' date is deleted");

                //Change - Event - CpaGlobalIdentifier NOT deleted for other events
                db.AddCpaGlobalIdentifier(@case.Id, "InnographyId1");
                db.ChangeEventDate(@case, otherEventMapping, Fixture.PastDate());
                Assert.AreEqual(1, db.CountCpaGlobalIdentifierFor(@case.Id), $"CPAGlobalIdentifier NOT deleted - since '{otherEvent}' date is not considered in Event Date Update trigger");

                //Delete - Event - CpaGlobalIdentifier deleted for 'Application' 
                db.DeleteEventDate(@case, application);
                Assert.AreEqual(1, db.CountCpaGlobalIdentifierFor(@case.Id), "CPAGlobalIdentifier NOT deleted - since 'Application' date is deleted");

                //Delete - Event - CpaGlobalIdentifier deleted for 'Publication' 
                db.AddCpaGlobalIdentifier(@case.Id, "InnographyId1");
                db.DeleteEventDate(@case, publication);
                Assert.AreEqual(1, db.CountCpaGlobalIdentifierFor(@case.Id), "CPAGlobalIdentifier NOT deleted - since 'Publication' date is deleted");

                //Delete - Event - CpaGlobalIdentifier deleted for 'Registration/Grant' 
                db.AddCpaGlobalIdentifier(@case.Id, "InnographyId1");
                db.DeleteEventDate(@case, registration);
                Assert.AreEqual(1, db.CountCpaGlobalIdentifierFor(@case.Id), "CPAGlobalIdentifier NOT deleted - since 'Registration/Grant' date is deleted");

                //Delete - Event - CpaGlobalIdentifier NOT deleted for other events
                db.AddCpaGlobalIdentifier(@case.Id, "InnographyId1");
                db.DeleteEventDate(@case, otherEventMapping);
                Assert.AreEqual(1, db.CountCpaGlobalIdentifierFor(@case.Id), $"CPAGlobalIdentifier NOT deleted - since '{otherEvent}' date is not considered in Event Date Delete trigger");
            }
        }

        [Test]
        [Ignore("e2e-flaky: DR-54708")]
        public void PopulateInnographyId()
        {
            Query q;
            var linked = new List<Tuple<string, int>>();
            var notLinked = new List<int>();

            using (var db = new InnographyDataSetup())
            {
                var family = db.CreateFamily();

                /* I-000101474745 - BED SHEET FOR SECURE PLACEMENT OF A CHILD */
                var usPatentHighConfidence = db.BuildInprotechCase("US", "P", family);
                db.AddOfficialNumberAndDate(usPatentHighConfidence, KnownNumberTypes.Application, "13/153685", new DateTime(2011, 6, 6))
                  .AddOfficialNumberAndDate(usPatentHighConfidence, KnownNumberTypes.Publication, "US-2011-0296612-A1", new DateTime(2011, 12, 8));

                /* I-000083258210 - Self lubrication self cleaning type ejection piston for cold chamber ejection unit */
                var jpPatentHighConfidence = db.BuildInprotechCase("JP", "P", family);
                db.AddOfficialNumberAndDate(jpPatentHighConfidence, KnownNumberTypes.Application, "2000-592094", new DateTime(1999, 12, 17))
                  .AddOfficialNumberAndDate(jpPatentHighConfidence, KnownNumberTypes.Registration, "4230117", new DateTime(2008, 12, 12));

                /* Method of protecting digest authentication and key agreement (AKA) against man-in-the-middle (MITM) attack - medium because application date */
                var usPatentMediumConfidence = db.BuildInprotechCase("US", "P", family);
                db.AddOfficialNumberAndDate(usPatentMediumConfidence, KnownNumberTypes.Registration, "US7908484B2", new DateTime(2011, 3, 15))
                  .AddOfficialNumberAndDate(usPatentMediumConfidence, KnownNumberTypes.Application, "US10920845", new DateTime(2003, 8, 22));

                /* Ultrasonic diagnostic apparatus - low because publication date should be 2008-04-16 */
                var chinesePatentLowConfidence = db.BuildInprotechCase("CN", "P", family);
                db.AddOfficialNumberAndDate(chinesePatentLowConfidence, KnownNumberTypes.Publication, "CN100381108C", new DateTime(2004, 8, 19));

                linked.AddRange(new[]
                                {
                                    new Tuple<string, int>("I-000101474745", usPatentHighConfidence.Id),
                                    new Tuple<string, int>("I-000083258210", jpPatentHighConfidence.Id)
                                });

                notLinked.AddRange(new[]
                                   {
                                       usPatentMediumConfidence.Id
                                   });

                q = db.CreateQuery(family);
            }

            var scheduleId = IntegrationDbSetup.Do(x =>
                                                   {
                                                       var schedule = x.Insert(new Schedule
                                                                               {
                                                                                   Name = RandomString.Next(20),
                                                                                   CreatedBy = 1,
                                                                                   CreatedOn = DateTime.Now,
                                                                                   DataSourceType = DataSourceType.IpOneData,
                                                                                   DownloadType = DownloadType.All,
                                                                                   NextRun = new DateTime(2000, 1, 1),
                                                                                   ExpiresAfter = new DateTime(2000, 1, 1),
                                                                                   State = ScheduleState.RunNow,
                                                                                   Type = ScheduleType.OnDemand,
                                                                                   ExtendedSettings = JsonConvert.SerializeObject(new InnographySchedule
                                                                                                                                  {
                                                                                                                                      RunAsUserId = Env.LoginUserId,
                                                                                                                                      RunAsUserName = Env.LoginUsername,
                                                                                                                                      SavedQueryId = q.Id,
                                                                                                                                      SavedQueryName = q.Name
                                                                                                                                  })
                                                                               });

                                                       return schedule.Id;
                                                   });

            var now = DateTime.Now;
            var numberOfCasesProcessed = 0;

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
                        numberOfCasesProcessed = schedule.CasesProcessed.GetValueOrDefault();
                        break;
                    }
                }
            }

            var results = DbSetup.Do(x =>
                                     {
                                         var linked1 = linked.First();
                                         var linked2 = linked.Last();

                                         var l1 = x.DbContext
                                                   .Set<CpaGlobalIdentifier>()
                                                   .SingleOrDefault(_ => linked1.Item2 == _.CaseId);

                                         var l2 = x.DbContext
                                                   .Set<CpaGlobalIdentifier>()
                                                   .SingleOrDefault(_ => linked2.Item2 == _.CaseId);

                                         var u = x.DbContext
                                                  .Set<CpaGlobalIdentifier>()
                                                  .Count(_ => notLinked.Contains(_.CaseId));

                                         return new
                                                {
                                                    linked1 = l1,
                                                    linked2 = l2,
                                                    notLinked = u
                                                };
                                     });

            Assert.AreEqual(linked.First().Item1, results.linked1.InnographyId, "Should set Innography ID to the US Patent case due to High Match");
            Assert.True(results.linked1.IsActive, "Should set US Patent case linkage as Active");

            Assert.AreEqual(linked.Last().Item1, results.linked2.InnographyId, "Should set Innography ID to the JP case due to High Match");
            Assert.True(results.linked2.IsActive, "Should set JP case linkage as Active");

            Assert.AreEqual(0, results.notLinked, "Should not set innography on low, medium confidence matches.");

            Assert.AreEqual(4, numberOfCasesProcessed, "Should processed four cases in the batch.");
        }
    }
}