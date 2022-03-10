using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Policing;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.Scenarios.Administrator
{
    [TestFixture]
    [Category(Categories.E2E)]
    [TestType(TestTypes.Scenario)]
    public class Monitoring : IntegrationTest
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
        public void MonitoringForRequestRuns(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            using (var setup = new AdministratorDbSetup().WithPolicingServerOff())
            {
                var daily = setup.Insert(new PolicingRequest(null)
                                         {
                                             IsSystemGenerated = 0,
                                             Name = "Daily " + RandomString.Next(6),
                                             DateEntered = Helpers.UniqueDateTime(),
                                             SequenceNo = 1
                                         });
                setup.Insert(new PolicingLog(daily.DateEntered) {FinishDateTime = daily.DateEntered.AddMinutes(1), PolicingName = daily.Name});

                var special = setup.Insert(new PolicingRequest(null)
                                           {
                                               IsSystemGenerated = 0,
                                               Name = "Special " + RandomString.Next(6),
                                               DateEntered = Helpers.UniqueDateTime(),
                                               SequenceNo = 1
                                           });
                setup.CreateErrorFor(special);
            }

            SignIn(driver, "/#/policing-dashboard", _loginUser.Username, _loginUser.Password);

            driver.With<DashboardPageObject>((dashboard, popups) =>
                                             {
                                                 Assert.LessOrEqual(2, dashboard.RequestGrid.Rows.Count, "Request log available for two requests run");

                                                 Assert.IsTrue(dashboard.RequestGrid.CellText(1, 0).StartsWith("Daily"), "Log for Daily request is present");
                                                 Assert.IsTrue(dashboard.RequestGrid.CellText(1, 1).StartsWith("Completed"), "Daily request status is Completed");

                                                 Assert.IsTrue(dashboard.RequestGrid.CellText(0, 0).StartsWith("Special"), "Log for Special request is present");
                                                 Assert.IsTrue(dashboard.RequestGrid.CellText(0, 1).StartsWith("Error"), "Sepcial Request status is in Error");

                                                 var errorLink = dashboard.RequestGrid.Cell(0, 1).FindElements(By.TagName("a")).FirstOrDefault();
                                                 Assert.NotNull(errorLink, "Link is present for error");

                                                 errorLink.WithJs().Click();
                                             });

            driver.With<RequestLogPageObject>((requestlog, popups) =>
                                              {
                                                  var focusedRow = requestlog.RequestGrid.MasterRows.Where(_ => _.GetAttribute("class").Contains("k-state-selected")).ToArray();
                                                  Assert.AreEqual(1, focusedRow.Length, "there should be only one focused row in the grid");
                                              });
        }
    }
}