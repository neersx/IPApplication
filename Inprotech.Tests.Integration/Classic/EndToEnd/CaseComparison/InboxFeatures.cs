using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.Extensions;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Integration.PtoAccess;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using Newtonsoft.Json;
using NUnit.Framework;
using OpenQA.Selenium;
using Z.EntityFramework.Plus;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison
{
    [TestFixture]
    [Category(Categories.E2E)]
    [RebuildsIntegrationDatabase]
    public class InboxFeatures : IntegrationTest
    {
        [TearDown]
        public void CleanupFiles()
        {
            foreach (var file in _filesAdded)
                FileSetup.DeleteFile(file);
        }

        readonly List<string> _filesAdded = new List<string>();

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ViewCaseComparisonInReadOnly(BrowserType browserType)
        {
            /* this test works with IE, but takes 4 times as much time as other browsers, so it is ommitted */

            var map = new Dictionary<DataSourceType, string>
            {
                {DataSourceType.UsptoTsdr, "uspto.tsdr.e2e-status.xml"},
                {DataSourceType.UsptoPrivatePair, "uspto.privatepair.e2e.cpaxml.xml"},
                {DataSourceType.Epo, "epo.ops.cpaxml.xml"}
            };

            var sessionGuid = Guid.NewGuid();
            var setup = new CaseComparisonDbSetup();
            setup.BuildIntegrationEnvironment(DataSourceType.UsptoPrivatePair, sessionGuid);

            var sources = Enum.GetValues(typeof(DataSourceType))
                              .Cast<DataSourceType>()
                              .Except(new[] {DataSourceType.IpOneData, DataSourceType.File})
                              .ToArray();

            var numNotifications = sources.Length * 30;
            for (var i = 0; i < numNotifications; i++)
            {
                var source = (DataSourceType) (i % sources.Length);
                var applicationNumber = RandomString.Next(20);
                var publicationNumber = RandomString.Next(20);
                var registrationNumber = RandomString.Next(20);
                var @case = setup.BuildIntegrationCase(source, null, applicationNumber, publicationNumber, registrationNumber);
                if (i >= sources.Length * 10)
                {
                    @case.WithSuccessNotification($"{source}_{RandomString.Next(10)}");
                    if (i >= sources.Length * 20)
                    {
                        var inprotechCaseId = setup.BuildInprotechCase(source)
                                                   .WithOfficialNumber(KnownNumberTypes.Application, applicationNumber)
                                                   .Id;

                        @case.AssociateWith(inprotechCaseId)
                             .InStorage(sessionGuid, "cpa-xml.xml", out var fullPath);
                        CreateFileInStorage(map[source], "cpa-xml.xml", fullPath);
                    }
                }
                else
                {
                    @case.WithErrorNotification();
                }
            }

            var ken = new Users()
                      .WithPermission(ApplicationTask.ViewCaseDataComparison)
                      .WithPermission(ApplicationTask.SaveImportedCaseData, Deny.Modify)
                      .Create();

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/casecomparison/inbox", ken.Username, ken.Password);

            driver.With<InboxPageObject>(page =>
            {
                driver.WaitForAngular();
                Assert.AreEqual(50, page.Notifications.Count, $"Should return the first page of {numNotifications} notification.");

                Assert.AreEqual(sources.Length, page.Sources.Count, "Should display as many number of sources as there are data available");

                var currentNotifications = page.DisplayedNotifications().ToArray();

                Assert.IsNotEmpty(currentNotifications.Where(_ => _.Source == "USPTO TSDR"), "Should have USPTO TSDR notifications displayed");

                Assert.IsNotEmpty(currentNotifications.Where(_ => _.Source == "European Patent Office"), "Should have European Patent Office notifications displayed");

                Assert.IsNotEmpty(currentNotifications.Where(_ => _.Source == "USPTO Private PAIR"), "Should have USPTO Private PAIR notifications displayed");

                Assert.IsEmpty(currentNotifications.Where(_ => _.Title == "Error"), "Should not display any error notifications");

                Assert.IsTrue(page.CaseComparisonView.IsDisplayed(), "Should display case comparison view.");

                Assert.IsTrue(page.CaseComparisonView.OfficialNumbers.Displayed, "Should contain some official numbers");

                Assert.IsNotEmpty(page.CaseComparisonView.CaseNames, "Should contain some names");

                Assert.IsFalse(page.CaseComparisonView.UpdateCase.IsVisible(), "Should not have the 'Update Case' button as it is readonly");

                Assert.IsFalse(page.CaseComparisonView.MarkReviewed.IsVisible(), "Should not have the 'Mark Review' button as it is readonly");

                // Filter to UsptoPrivatePair Only

                page.ToggleFilter(DataSourceType.UsptoPrivatePair);
                driver.WaitForAngular();
            });

            driver.With<InboxPageObject>(page =>
            {
                Assert.AreEqual(20, page.Notifications.Count, "Should show all non-error notifications from the same source.");

                Assert.AreEqual(sources.Length, page.Sources.Count, "Should display as many number of sources as there are data available");

                var currentNotifications = page.DisplayedNotifications().ToArray();

                Assert.IsNotEmpty(currentNotifications.Where(_ => _.Source == "USPTO Private PAIR"), "Should have USPTO Private PAIR notifications displayed");

                Assert.IsEmpty(currentNotifications.Where(_ => _.Title == "Error"), "Should not display any error notifications");

                page.IncludeError.Click();
                driver.WaitForAngular();

                Assert.AreEqual(30, page.Notifications.Count, "Should show all notifications, including errors from the same source.");

                currentNotifications = page.DisplayedNotifications().ToArray();

                Assert.IsNotEmpty(currentNotifications.Where(_ => _.Title == "Error"), "Should not display any error notifications");

                // Select and display error

                var firstError = currentNotifications.First(_ => _.Title == "Error");

                page.Notifications[Array.IndexOf(currentNotifications, firstError)].Click();
                driver.WaitForAngular();
            });

            driver.With<InboxPageObject>(page =>
            {
                Assert.IsTrue(page.ErrorView.IsDisplayed(), "Should display error view.");

                page.ErrorView.DisplayErrorDetailsDialog(0);
                driver.WaitForAngular();

                Assert.IsTrue(page.ErrorView.ErrorDetailsDialog.Modal.Displayed, "Should display error details dialog");

                page.ErrorView.ErrorDetailsDialog.Close();
                driver.WaitForAngular();
            });

            IntegrationDbSetup.Do(x =>
            {
                // mark all notifications reviewed.
                x.IntegrationDbContext.Set<CaseNotification>()
                 .Update(_ => new CaseNotification
                 {
                     IsReviewed = true,
                     ReviewedBy = ken.Id
                 });
            });

            driver.With<InboxPageObject>(page =>
            {
                // unset filter

                page.ToggleFilter(DataSourceType.UsptoPrivatePair);
                driver.WaitForAngular();
                Assert.IsEmpty(page.Notifications, "Should not show any notifications as all have been marked reviewed.");

                page.IncludeReviewed.Click();
                driver.WaitForAngular();
                Assert.IsNotEmpty(page.Notifications, "Should now include reviewed notifications.");
            });
        }

        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ComparisonThroughCaseSearchResults(BrowserType browserType)
        {
            const DataSourceType dataSource = DataSourceType.UsptoTsdr;

            var sessionGuid = Guid.NewGuid();
            var setup = new CaseComparisonDbSetup();

            var applicationNumber = RandomString.Next(20);
            var publicationNumber = RandomString.Next(20);
            var registrationNumber = RandomString.Next(20);

            var inprotechCase = setup.BuildInprotechCase(dataSource)
                                     .WithOfficialNumber(KnownNumberTypes.Application, applicationNumber);

            setup.BuildIntegrationEnvironment(dataSource, sessionGuid)
                 .BuildIntegrationCase(dataSource, inprotechCase.Id, applicationNumber, publicationNumber, registrationNumber)
                 .WithSuccessNotification($"{dataSource}_{RandomString.Next(10)}")
                 .InStorage(sessionGuid, "cpa-xml.xml", out var fullPath);

            CreateFileInStorage("uspto.tsdr.e2e-status.xml", "cpa-xml.xml", fullPath);

            var ken = new Users()
                      .WithPermission(ApplicationTask.ViewCaseDataComparison)
                      .Create();

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/casecomparison/inbox?caselist={inprotechCase.Id}", ken.Username, ken.Password);

            driver.With<InboxPageObject>(page =>
            {
                Assert.AreEqual(1, page.Notifications.Count, "Should only have a single notification");

                Assert.IsTrue(page.CaseComparisonView.IsDisplayed(), "Should display the case by default");

                Assert.True(page.IncludeError.IsChecked, "Should include errors when coming from comparison");

                Assert.True(page.IncludeReviewed.IsChecked, "Should include reviewed when coming from comparison");
            });
        }

        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void ComparisonThroughScheduleDetailsPage(BrowserType browserType)
        {
            var users = new Users();

            const DataSourceType dataSource = DataSourceType.UsptoPrivatePair;
            var user = users
                       .WithPermission(ApplicationTask.ScheduleUsptoTsdrDataDownload)
                       .WithPermission(ApplicationTask.ScheduleEpoDataDownload)
                       .WithPermission(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)
                       .WithPermission(ApplicationTask.ViewCaseDataComparison)
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

                var execution1 = x.Insert(new ScheduleExecution(Guid.NewGuid(), schedule, DateTime.Parse("2002-02-02"))
                {
                    CorrelationId = "12345",
                    CasesIncluded = 1,
                    CasesProcessed = 1,
                    DocumentsIncluded = 20,
                    DocumentsProcessed = 20,
                    Finished = DateTime.Parse("2002-02-02"),
                    IsTidiedUp = true,
                    Status = ScheduleExecutionStatus.Complete
                });

                var sessionGuid = Guid.NewGuid();
                var setup = new CaseComparisonDbSetup();

                var applicationNumber = RandomString.Next(20);
                var publicationNumber = RandomString.Next(20);
                var registrationNumber = RandomString.Next(20);

                var inprotechCase = setup.BuildInprotechCase(dataSource)
                                         .WithOfficialNumber(KnownNumberTypes.Application, applicationNumber);
                var integrationCase = setup.BuildIntegrationEnvironment(dataSource, sessionGuid)
                                           .BuildIntegrationCase(dataSource, inprotechCase.Id, applicationNumber, publicationNumber, registrationNumber)
                                           .InStorage(sessionGuid, "cpa-xml.xml", out var fullPath);

                CreateFileInStorage("uspto.tsdr.e2e-status.xml", "cpa-xml.xml", fullPath);

                x.Insert(new CaseNotification
                {
                    Id = Fixture.Integer(),
                    Body = Fixture.String(10),
                    CaseId = integrationCase.Id,
                    CreatedOn = DateTime.Now,
                    UpdatedOn = DateTime.Now,
                    Type = CaseNotificateType.CaseUpdated
                });
                x.Insert(new ScheduleExecutionArtifact
                {
                    CaseId = integrationCase.Id,
                    ScheduleExecutionId = execution1.Id
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
                Assert.AreEqual("0/20", page.RecentHistory.Grid.Cell(0, 4).Text);
                Assert.AreEqual("3/5", page.RecentHistory.Grid.Cell(0, 5).Text);
                Assert.AreEqual("12345", page.RecentHistory.Grid.Cell(0, 6).Text);

                Assert.AreEqual("Complete", page.RecentHistory.Grid.Cell(1, 0).Text);
                Assert.AreEqual("1/1", page.RecentHistory.Grid.Cell(1, 4).Text);
                Assert.AreEqual("20/20", page.RecentHistory.Grid.Cell(1, 5).Text);
                Assert.AreEqual("12345", page.RecentHistory.Grid.Cell(1, 6).Text);
                page.RecentHistory.Grid.Cell(1, 4).FindElement(By.CssSelector("a")).ClickWithTimeout();
            });

            driver.With<InboxPageObject>(page =>
            {
                Assert.AreEqual(1, page.Notifications.Count, "Should only have a single notification");

                Assert.IsTrue(page.CaseComparisonView.IsDisplayed(), "Should display the case by default");

                Assert.True(page.IncludeError.IsChecked, "Should include errors when coming from comparison");

                Assert.True(page.IncludeReviewed.IsChecked, "Should include reviewed when coming from comparison");
            });
        }

        static string ScheduleSettings(dynamic props)
        {
            return JsonConvert.SerializeObject(props, Formatting.None);
        }

        void CreateFileInStorage(string file, string name, string fullPath)
        {
            var filePath = FileSetup.SendToStorage(file, name, fullPath.Replace(name, string.Empty));

            _filesAdded.Add(filePath);
        }
    }
}