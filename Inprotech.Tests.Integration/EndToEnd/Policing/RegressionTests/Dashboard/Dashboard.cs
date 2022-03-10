using System;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Policing;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.Dashboard
{
    [TestFixture]
    [Category(Categories.E2E)]
    [TestType(TestTypes.Regression)]
    public class Dashboard : IntegrationTest
    {
        TestUser _loginUser;

        [SetUp]
        public void CreatePoliceAdminUser()
        {
            _loginUser = new Users()
                .WithPermission(ApplicationTask.PolicingAdministration)
                .Create();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckStatusAndNumbers(BrowserType browserType)
        {
            const int autoRefreshSeconds = 2;

            var originalTotal = 0;

            var driver = BrowserProvider.Get(browserType);

            using (var setup = new DashboardDbSetup().WithPolicingServerOff())
            {
                setup.EnqueueFor("waiting-to-start", "open-action", setup.GetCase("test-ref1"));
                setup.EnqueueFor("on-hold", "due-date-changed", setup.GetCase("test-ref2"));
                setup.EnqueueFor("in-progress", "due-date-changed", setup.GetCase("test-ref2"));

                var queue1 = setup.EnqueueFor("in-error", "open-action", setup.GetCase("test-ref4"));
                setup.CreateErrorFor(queue1);

                setup.EnqueueFor("waiting-to-start", "open-action", setup.GetCase("test-ref1"));
                setup.EnqueueFor("on-hold", "due-date-changed", setup.GetCase("test-ref2"));
                setup.EnqueueFor("on-hold", "due-date-changed", setup.GetCase("test-ref5"));

                var queue2 = setup.EnqueueFor("in-error", "due-date-changed", setup.GetCase("test-ref3"));
                setup.CreateErrorFor(queue2);

                var queue3 = setup.EnqueueFor("in-error", "open-action", setup.GetCase("test-ref4"));
                setup.CreateErrorFor(queue3);
            }

            SignIn(driver, "/#/policing-dashboard?rinterval=" + autoRefreshSeconds, _loginUser.Username, _loginUser.Password);

            driver.With<DashboardPageObject>((dashboard, popups) =>
                                             {
                                                 driver.Wait().ForTrue(() => dashboard.PolicingStatus.IsStopped);
                                                 Assert.IsTrue(dashboard.PolicingStatus.IsStopped, "Ensure policing server is in stopped state currently");

                                                 var summary = DashboardDbSetup.RawSummaryFromSql();

                                                 originalTotal = summary.Total;

                                                 //Verify Summary numbers displayed
                                                 Assert.AreEqual(summary.Total, dashboard.Summary.Total.Value(), "summary should show correct Total");
                                                 Assert.AreEqual(summary.Progressing, dashboard.Summary.Progressing.Value(), "summary should show correct Progressing");
                                                 Assert.AreEqual(summary.RequiresAttention, dashboard.Summary.RequiresAttention.Value(), "summary should show correct Blocked");
                                                 Assert.AreEqual(summary.OnHold, dashboard.Summary.OnHold.Value(), "summary should show correct OnHold");

                                                 Assert.IsTrue(dashboard.CurrentStatusChart().Displayed, "status graph should be loaded by default");

                                                 Assert.Contains(dashboard.PolicingStatus.Message().Text, new[]
                                                                                                          {
                                                                                                              "Checking Status",
                                                                                                              "Policing Running",
                                                                                                              "Policing Stopped"
                                                                                                          }, "one of valid policing statuses should be displayed");

                                             });

            driver.With<DashboardPageObject>((dashboard, popups) =>
                                             {
                                                 using (var setup = new DashboardDbSetup().WithPolicingServerOff())
                                                 {
                                                     // add new item
                                                     setup.EnqueueFor("waiting-to-start", "open-action", setup.GetCase("test-ref4"));
                                                 }

                                                 driver.Wait().ForTrue(() =>
                                                                       {
                                                                           var total = new DashboardPageObject(driver).Summary.Total.Value();
                                                                           return total > originalTotal;
                                                                       }, 20000, 100);

                                                 var summary = DashboardDbSetup.RawSummaryFromSql();

                                                 Assert.AreEqual(summary.Total, dashboard.Summary.Total.Value(), "summary should show updated Total");
                                                 Assert.AreEqual(summary.Progressing, dashboard.Summary.Progressing.Value(), "summary should show updated Progressing");
                                             });
           
            driver.With<DashboardPageObject>((dashboard, popups) =>
                                             {
                                                 // Swap from stop to running
                                                 dashboard.PolicingStatus.ChangeStatusButton().WithJs().Click();
                                                 popups.ConfirmModal.Yes().WithJs().Click();

                                                 driver.Wait().ForTrue(() => dashboard.PolicingStatus.IsRunning, 20000, 100);
                                             });

            driver.With<DashboardPageObject>((dashboard, popups) =>
                                             {
                                                 // Swap from running to stop
                                                 dashboard.PolicingStatus.ChangeStatusButton().WithJs().Click();
                                                 popups.ConfirmModal.Yes().WithJs().Click();

                                                 driver.Wait().ForTrue(() => dashboard.PolicingStatus.IsStopped, 20000, 100);
                                             });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldDisplayGraphsWhenSelected(BrowserType browserType)
        {
            using (var setup = new DashboardDbSetup().WithPolicingServerOff())
                setup.EnsureLogExists();

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/policing-dashboard", _loginUser.Username, _loginUser.Password);

            driver.With<DashboardPageObject>((dashboard, popups) =>
                                             {
                                                 //Status charts are displayed on load
                                                 Assert.IsNotNull(dashboard.CurrentStatusChart(), "Status Chart should exists on load");
                                                 Assert.IsNotNull(dashboard.CurrentErrorStatusChart(), "Status Error Chart should exists on load");
                                                 Assert.IsNull(dashboard.RateChart());

                                                 //Display rate graph
                                                 driver.WithTimeout(2, () => dashboard.ChartSelection().SelectByIndex(1));
                                                 Assert.IsNull(dashboard.CurrentStatusChart(), "Status Chart should not exists when rate graph is selected");
                                                 Assert.IsNull(dashboard.CurrentErrorStatusChart(), "Status Error Chart shouldnot exists when rate graph is selected");
                                                 Assert.IsTrue(dashboard.RateChart().Displayed);
                                             });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ShouldDisplayWarningOnRateGraphWhenNoHistoricalDataAvailable(BrowserType browserType)
        {
            using (var setup = new DashboardDbSetup().WithPolicingServerOff())
                setup.EnsureLogDoesNotExists();

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/policing-dashboard", _loginUser.Username, _loginUser.Password);

            driver.With<DashboardPageObject>((dashboard, popups) =>
                                             {
                                                 driver.WithTimeout(2, () => dashboard.ChartSelection().SelectByIndex(1));
                                                 Assert.IsNull(dashboard.CurrentStatusChart(), "Status Chart should not exists when rate graph is selected");
                                                 Assert.IsTrue(dashboard.Warning().Displayed);
                                             });

            using (var setup = new DashboardDbSetup().WithPolicingServerOff())
                setup.RevertLog();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void RefreshRequestsSummaryGrid(BrowserType browserType)
        {
            const int topTwoOnly = 2;
            const int autoRefreshSeconds = 3;

            var firstLogEntry = Fixture.Prefix("request log") + RandomString.Next(5);
            var secondLogEntry = Fixture.Prefix("request log") + RandomString.Next(5);
            var driver = BrowserProvider.Get(browserType);

            using (var setup = new DashboardDbSetup().WithPolicingServerOff())
            {
                setup.Insert(new PolicingLog(Helpers.UniqueDateTime())
                             {
                                 PolicingName = firstLogEntry
                             });
            }

            SignIn(driver, "/#/policing-dashboard?rinterval=" + autoRefreshSeconds, _loginUser.Username, _loginUser.Password);

            driver.With<DashboardPageObject>((dashboard, popups) =>
                                             {
                                                 driver.Wait().ForTrue(() => dashboard.RequestGrid.Rows.Count > 0);

                                                 var texts = dashboard.RequestGrid.ColumnValues(0, topTwoOnly); // Cell 0 == PolicingName

                                                 var indexOfFirstEntry = Array.IndexOf(texts, firstLogEntry);
                                                 var indexOfSecondEntry = Array.IndexOf(texts, secondLogEntry);

                                                 Assert.Greater(indexOfFirstEntry, -1, "Policing Log 'test 1' inserted here exist (>-1)");
                                                 Assert.AreEqual(indexOfSecondEntry, -1, "Policing Log 'test 2' has not been inserted, so should have index of -1");

                                                 using (var setup = new DashboardDbSetup())
                                                 {
                                                     setup.Insert(new PolicingLog(Helpers.UniqueDateTime())
                                                                  {
                                                                      PolicingName = secondLogEntry
                                                                  });
                                                 }

                                                 var newPolicingLogTexts = new string[0];

                                                 driver.Wait().ForTrue(() =>
                                                                       {
                                                                           newPolicingLogTexts = new DashboardPageObject(driver).RequestGrid.ColumnValues(0, topTwoOnly); // Cell 0 == PolicingName
                                                                           return indexOfFirstEntry != Array.IndexOf(newPolicingLogTexts, firstLogEntry);
                                                                       }, 10000);

                                                 Assert.Greater(Array.IndexOf(newPolicingLogTexts, secondLogEntry), -1);
                                             });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void RecentPolicingRequestLogViewShouldOpenEntireLog(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var policingDashBoard = new DashboardPageObject(driver);

            using (var setup = new DashboardDbSetup().WithPolicingServerOff())
            {
                var request = setup.Insert(new PolicingRequest(null)
                {
                    DateEntered = Helpers.UniqueDateTime(DateTime.Today.AddDays(1)),
                    Name = "Request" + RandomString.Next(6)
                });
                setup.Insert(new PolicingLog
                {
                    StartDateTime = Helpers.UniqueDateTime(DateTime.Today.AddDays(1)),
                    FinishDateTime = Helpers.UniqueDateTime(),
                    PolicingName = request.Name
                });

            }

            SignIn(driver, "/#/policing-dashboard", _loginUser.Username, _loginUser.Password);

            policingDashBoard.ViewAllLogsLink().ClickWithTimeout();

            Assert.IsTrue(driver.Url.Contains("policing-request-log"), "clicking view entire log should navigate to policing request log page");
        }
    }
}