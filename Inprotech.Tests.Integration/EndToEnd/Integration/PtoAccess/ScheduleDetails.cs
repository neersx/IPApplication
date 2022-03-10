using System;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using Newtonsoft.Json;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.PtoAccess
{
    [TestFixture]
    [Category(Categories.E2E)]
    [RebuildsIntegrationDatabase]
    public class ScheduleDetails : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ViewHistoryAndErrors(BrowserType browserType)
        {
            var users = new Users();

            var user = users
                .WithPermission(ApplicationTask.ScheduleUsptoTsdrDataDownload)
                .WithPermission(ApplicationTask.ScheduleEpoDataDownload)
                .WithPermission(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)
                .Create();

            Schedule schedule = null;

            IntegrationDbSetup.Do(x =>
                                  {
                                      schedule = x.Insert(new Schedule
                                                          {
                                                              CreatedBy = user.Id,
                                                              Name = RandomString.Next(20),
                                                              CreatedOn = DateTime.Parse("2001-01-01"),
                                                              DataSourceType = DataSourceType.UsptoPrivatePair,
                                                              RunOnDays = "Mon",
                                                              StartTime = DateTime.Now.TimeOfDay,
                                                              NextRun = DateTime.Parse("2050-01-01"),
                                                              DownloadType = DownloadType.All,
                                                              ExtendedSettings = ScheduleSettings(new
                                                                                                  {
                                                                                                      CustomerNumbers = "12345",
                                                                                                      Certificates = 1,
                                                                                                      CertificateName = Fixture.String(20),
                                                                                                      DaysWithinLast = 3
                                                                                                  })
                                                          });

                                      x.Insert(new ScheduleExecution(Guid.NewGuid(), schedule, DateTime.Parse("2002-02-02"))
                                               {
                                                   CorrelationId = "12345",
                                                   CasesIncluded = 20,
                                                   CasesProcessed = 20,
                                                   DocumentsIncluded = 20,
                                                   DocumentsProcessed = 20,
                                                   Finished = DateTime.Parse("2002-02-02"),
                                                   IsTidiedUp = true,
                                                   Status = ScheduleExecutionStatus.Complete
                                               });

                                      x.Insert(new ScheduleExecution(Guid.NewGuid(), schedule, DateTime.Parse("2003-03-03"))
                                               {
                                                   CorrelationId = "12345",
                                                   CasesIncluded = 20,
                                                   CasesProcessed = 0,
                                                   DocumentsIncluded = 5,
                                                   DocumentsProcessed = 3,
                                                   Finished = DateTime.Parse("2003-03-03"),
                                                   IsTidiedUp = true,
                                                   Status = ScheduleExecutionStatus.Failed
                                               });
                                  });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/integration/ptoaccess/schedule?id={schedule.Id}", user.Username, user.Password);

            driver.With<ScheduleDetailsPageObject>(page =>
                                                   {
                                                       Assert.AreEqual(2, page.RecentHistory.Grid.Rows.Count, "Should display 2 previous executions for the schedule");
                                                       Assert.AreEqual("0/20", page.RecentHistory.Grid.Cell(0,4).Text);
                                                       Assert.AreEqual("3/5", page.RecentHistory.Grid.Cell(0,5).Text);
                                                       Assert.AreEqual("12345", page.RecentHistory.Grid.Cell(0,6).Text);

                                                       Assert.AreEqual("Complete", page.RecentHistory.Grid.Cell(1,0).Text);
                                                       Assert.AreEqual("20/20", page.RecentHistory.Grid.Cell(1,4).Text);
                                                       Assert.AreEqual("20/20", page.RecentHistory.Grid.Cell(1,5).Text);
                                                       Assert.AreEqual("12345", page.RecentHistory.Grid.Cell(1,6).Text);
                                                       page.RecentHistory.OpenFailedExecutionDetails();
                                                       
                                                       Assert.True(page.RecentHistory.ErrorDetails.InlineAlert.Displayed, "Should display Error Details modal");
                                                   });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ViewRecoverableDocumentsAndCases(BrowserType browserType)
        {
            var users = new Users();

            var user = users
                .WithPermission(ApplicationTask.ScheduleUsptoTsdrDataDownload)
                .WithPermission(ApplicationTask.ScheduleEpoDataDownload)
                .WithPermission(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)
                .Create();

            Schedule schedule = null;

            IntegrationDbSetup.Do(x =>
                                  {
                                      schedule = x.Insert(new Schedule
                                                          {
                                                              CreatedBy = user.Id,
                                                              Name = RandomString.Next(20),
                                                              CreatedOn = DateTime.Parse("2001-01-01"),
                                                              DataSourceType = DataSourceType.UsptoPrivatePair,
                                                              RunOnDays = "Mon",
                                                              StartTime = DateTime.Now.TimeOfDay,
                                                              NextRun = DateTime.Parse("2050-01-01"),
                                                              DownloadType = DownloadType.All,
                                                              ExtendedSettings = ScheduleSettings(new
                                                                                                  {
                                                                                                      CustomerNumbers = "12345",
                                                                                                      Certificates = 1,
                                                                                                      CertificateName = Fixture.String(20),
                                                                                                      DaysWithinLast = 3
                                                                                                  })
                                                          });
                                      var firstExecution = x.Insert(new ScheduleExecution(Guid.NewGuid(), schedule, DateTime.Parse("2002-02-02"))
                                               {
                                                   CorrelationId = "12345",
                                                   CasesIncluded = 20,
                                                   CasesProcessed = 20,
                                                   DocumentsIncluded = 20,
                                                   DocumentsProcessed = 20,
                                                   Finished = DateTime.Parse("2002-02-02"),
                                                   IsTidiedUp = true,
                                                   Status = ScheduleExecutionStatus.Complete
                                               });

                                      x.Insert(new ScheduleRecoverable(firstExecution, new Document()
                                      {
                                          ApplicationNumber = "application1",
                                          RegistrationNumber = "registration1",
                                          PublicationNumber = "publication1",
                                          Reference = Guid.NewGuid(),
                                          DocumentObjectId = "test",
                                          FileWrapperDocumentCode = "test",
                                          MailRoomDate = DateTime.Parse("2003-01-03"),
                                          CreatedOn = DateTime.Parse("2003-02-03"),
                                          DocumentCategory = "category",
                                          DocumentDescription = "description",
                                          Errors = "errors",
                                          UpdatedOn = DateTime.Parse("2003-03-03"),
                                          Status = DocumentDownloadStatus.Failed
                                      },  DateTime.Parse("2003-04-03")));
                                      x.Insert(new ScheduleRecoverable(firstExecution, new Document()
                                      {
                                          ApplicationNumber = "application2",
                                          RegistrationNumber = "registration2",
                                          PublicationNumber = "publication2",
                                          Reference = Guid.NewGuid(),
                                          DocumentObjectId = "test2",
                                          FileWrapperDocumentCode = "test2",
                                          MailRoomDate = DateTime.Parse("2003-01-04"),
                                          CreatedOn = DateTime.Parse("2003-02-04"),
                                          DocumentCategory = "category2",
                                          DocumentDescription = "description2",
                                          Errors = "errors2",
                                          UpdatedOn = DateTime.Parse("2003-03-04"),
                                          Status = DocumentDownloadStatus.Failed
                                      },  DateTime.Parse("2003-04-04")));
                                      x.Insert(new ScheduleExecution(Guid.NewGuid(), schedule, DateTime.Parse("2003-03-03"))
                                               {
                                                   CorrelationId = "12345",
                                                   CasesIncluded = 20,
                                                   CasesProcessed = 0,
                                                   DocumentsIncluded = 5,
                                                   DocumentsProcessed = 3,
                                                   Finished = DateTime.Parse("2003-03-03"),
                                                   IsTidiedUp = true,
                                                   Status = ScheduleExecutionStatus.Failed
                                               });
                                  });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/integration/ptoaccess/schedule?id={schedule.Id}", user.Username, user.Password);

            driver.With<ScheduleDetailsPageObject>(page =>
                                                   {
                                                       Assert.True(page.RecoverableCasesAlert.Displayed, "Showing recoverable cases alert");
                                                       Assert.True(page.RecoverableCasesAlert.Text.Contains("2 case(s)"));
                                                       Assert.True(page.RecoverableCasesAlert.Text.Contains("2 document(s)"));

                                                       page.RecoverableCasesCountLink.ClickWithTimeout();
                                                       driver.WaitForAngular();
                                                       Assert.True(page.RecoverableCases.Modal.Displayed);

                                                       page.RecoverableCases.Close();

                                                       page.RecoverableDocumentsCountLink.ClickWithTimeout();
                                                       driver.WaitForAngular();
                                                       Assert.True(page.RecoverableDocuments.Modal.Displayed);

                                                       page.RecoverableDocuments.Close();
                                                   });
        }

        static string ScheduleSettings(dynamic props)
        {
            return JsonConvert.SerializeObject(props, Formatting.None);
        }
    }
}