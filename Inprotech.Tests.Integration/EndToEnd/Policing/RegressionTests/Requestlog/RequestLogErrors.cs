using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Policing;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.Requestlog
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestType(TestTypes.Regression)]
    public class RequestLogErrorsTests : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void RequestLogErrors(BrowserType browserType)
        {
            string caseRefUrl;
            using (var setup = new RequestLogDbSetup())
            {
                var @case = setup.GetCase("test-ref1");
                caseRefUrl = Helpers.GetCaseRefLink(@case.Irn);
                var request = setup.Insert(new PolicingRequest(null)
                {
                    DateEntered = Helpers.UniqueDateTime(DateTime.Today.AddDays(1)),
                    Name = "Request" + RandomString.Next(6),
                    Case = @case
                });

                Enumerable.Range(0, 3).ToList().ForEach(x => setup.CreateErrorFor(request));
            }

            var driver = BrowserProvider.Get(browserType);
            var requestLog = new RequestLogPageObject(driver);

            SignIn(driver, "/#/policing-request-log");

            Assert.AreEqual(3, requestLog.ErrorGrid.Rows.Count, "There should be 3 error rows");

            var caseRefLinkElement = requestLog.ErrorGrid.Cell(1, 0).FindElement(By.TagName("a"));
            Assert.IsNotNull(caseRefLinkElement);
            var currentUrl = caseRefLinkElement.GetAttribute("href");
            Assert.IsTrue(currentUrl.Contains(caseRefUrl), $"Case Ref url is {currentUrl}");

            Assert.IsNull(requestLog.ViewAllErrorsLink, "If there are less than 5 errors, hyperlink should not be visible");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ViewAllErrors(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var requestLog = new RequestLogPageObject(driver);

            using (var setup = new RequestLogDbSetup())
            {
                var request = setup.Insert(new PolicingRequest(null)
                {
                    DateEntered = Helpers.UniqueDateTime(DateTime.Today.AddDays(1)),
                    Name = "Request" + RandomString.Next(6)
                });

                Enumerable.Range(0, 7).ToList().ForEach(x => setup.CreateErrorFor(request));
            }

            SignIn(driver, "/#/policing-request-log");

            Assert.LessOrEqual(1, requestLog.RequestGrid.MasterRows.Count, "There should be 1 row");

            Assert.AreEqual("View all 7 errors", requestLog.ViewAllErrorsLink.Text);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void FocusAndScrollToError(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            TestUser loginUser;
            using (var setup = new RequestLogDbSetup())
            {
                var todaysRequest1 = Helpers.UniqueDateTime();
                Enumerable.Range(0, 5)
                          .ToList()
                          .ForEach(x => setup.CreateError(todaysRequest1));

                Enumerable.Range(0, 7).ToList().ForEach(x =>
                {
                    var todaysRequest2 = Helpers.UniqueDateTime();
                    Enumerable.Range(0, 5)
                              .ToList()
                              .ForEach(x1 => setup.CreateError(todaysRequest2));
                });

                var todaysRequest3 = Helpers.UniqueDateTime();
                Enumerable.Range(0, 2)
                          .ToList()
                          .ForEach(x => setup.CreateError(todaysRequest3));

                var todaysRequest4 = Helpers.UniqueDateTime();
                Enumerable.Range(0, 5)
                          .ToList()
                          .ForEach(x => setup.CreateError(todaysRequest4));

                loginUser = setup.Users
                                 .WithPermission(ApplicationTask.ViewPolicingDashboard)
                                 .WithPermission(ApplicationTask.MaintainPolicingRequest)
                                 .Create();
            }

            SignIn(driver, "/#/policing-dashboard", loginUser.Username, loginUser.Password);

            var requestLogSummaryGrid = new DashboardPageObject(driver).RequestGrid;
            Assert.LessOrEqual(10, requestLogSummaryGrid.Rows.Count);

            var errorLink = requestLogSummaryGrid.Cell(0, 1).FindElement(By.TagName("a"));
            errorLink.WithJs().ScrollIntoView();
            errorLink.ClickWithTimeout();

            var requestLog = new RequestLogPageObject(driver);
            var requestGrid = requestLog.RequestGrid;

            Assert.LessOrEqual(1, requestGrid.MasterRows.Count(_ => _.GetAttribute("class").Contains("k-state-selected")),
                               "there should be only one focused row in the grid");
            Assert.AreEqual(true, requestGrid.MasterRows[0].GetAttribute("class").Contains("k-state-selected"),
                            "first row should be the focused row");
            Assert.AreEqual(true, requestGrid.MasterRows[0].WithJs().IsVisible(),
                            "it should scroll to top so make sure it is visible");

            requestLog.LevelUpButton.ClickWithTimeout();

            errorLink = requestLogSummaryGrid.Cell(1, 1).FindElement(By.TagName("a"));
            errorLink.WithJs().ScrollIntoView();
            errorLink.ClickWithTimeout();
            Assert.LessOrEqual(1, requestGrid.MasterRows.Count(_ => _.GetAttribute("class").Contains("k-state-selected")),
                               "there should be only one focused row in the grid");
            Assert.AreEqual(true, requestGrid.MasterRows[1].GetAttribute("class").Contains("k-state-selected"),
                            "second row should be the focused row");
            Assert.AreEqual(true, requestGrid.MasterRows[1].WithJs().IsVisible(),
                            "it should scroll to top so make sure it is visible");

            requestLog.LevelUpButton.ClickWithTimeout();

            errorLink = requestLogSummaryGrid.Cell(8, 1).FindElement(By.TagName("a"));
            errorLink.WithJs().ScrollIntoView();
            errorLink.ClickWithTimeout();
            Assert.LessOrEqual(1, requestGrid.MasterRows.Count(_ => _.GetAttribute("class").Contains("k-state-selected")),
                               "there should be only one focused row in the grid");
            Assert.AreEqual(true, requestGrid.MasterRows[8].GetAttribute("class").Contains("k-state-selected"),
                            "second row should be the focused row");
            Assert.AreEqual(true, requestGrid.MasterRows[8].WithJs().IsVisible(),
                            "it should scroll to top so make sure it is visible");

            requestLog.LevelUpButton.ClickWithTimeout();

            errorLink = requestLogSummaryGrid.Cell(9, 1).FindElement(By.TagName("a"));
            errorLink.WithJs().ScrollIntoView();
            errorLink.ClickWithTimeout();
            Assert.LessOrEqual(1, requestGrid.MasterRows.Count(_ => _.GetAttribute("class").Contains("k-state-selected")),
                               "there should be only one focused row in the grid");
            Assert.AreEqual(true, requestGrid.MasterRows[9].GetAttribute("class").Contains("k-state-selected"),
                            "first row should be the focused row");
            Assert.AreEqual(true, requestGrid.MasterRows[9].WithJs().IsVisible(),
                            "it should scroll to top so make sure it is visible");
        }
    }
}