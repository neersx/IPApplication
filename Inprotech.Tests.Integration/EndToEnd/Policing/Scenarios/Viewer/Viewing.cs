using System;
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

namespace Inprotech.Tests.Integration.EndToEnd.Policing.Scenarios.Viewer
{
    [TestFixture]
    [Category(Categories.E2E)]
    [TestType(TestTypes.Scenario)]
    public class PolicingViewing : IntegrationTest
    {
        TestUser _loginUser;

        [SetUp]
        public void CreatePoliceViewUser()
        {
            _loginUser = new Users()
                .WithPermission(ApplicationTask.ViewPolicingDashboard)
                .Create();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ViewPolicingItems(BrowserType browserType)
        {
            ViewerDbSetup.Data data;
            string irn;
            using (var setup = new ViewerDbSetup().WithPolicingServerOff())
            {
                var collegues = setup.OtherUsers.Create();

                data = setup.WithWorkflowData();
                var @case = setup.GetCase("teste2e_!@#$%^");
                irn = @case.Irn;
                setup.EnqueueFor(collegues.John, "waiting-to-start", "open-action", @case, null, data.Event.Id);
                setup.EnqueueFor(collegues.Mary, "on-hold", "due-date-changed", @case);
                setup.EnqueueFor(collegues.John, "in-progress", "due-date-changed", @case);
                setup.EnqueueFor(collegues.Mary, "in-progress", "open-action", @case);

                var item = setup.Insert(new PolicingRequest(@case.Id)
                {
                    OnHold = KnownValues.StringToHoldFlag["in-error"],
                    TypeOfRequest = (short)KnownValues.StringToTypeOfRequest["open-action"],
                    IsSystemGenerated = 1,
                    Name = "E2E Test " + RandomString.Next(6),
                    DateEntered = Helpers.UniqueDateTime(),
                    SequenceNo = 1
                });

                setup.CreateErrorFor(item);
            }

            var splittedIrn = irn.Split(new [] {"teste2e"}, StringSplitOptions.None);
            var caseRefUrl = Helpers.GetCaseRefLink(splittedIrn[0] + "teste2e" + "_!%40%23%24%25%5Eirn");

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/policing-dashboard", _loginUser.Username, _loginUser.Password);

            driver.With<DashboardPageObject>((dashboard, popups) =>
                                                        {
                                                            Assert.IsNull(dashboard.MaintainSavedRequestLink(),"Maintain Saved resquest link should be absent");
                                                            Assert.IsNull(dashboard.PolicingStatus.ChangeStatusButton(), "Policing button should be absent");
                                                            Assert.IsEmpty(dashboard.RequestGrid.Cell(0, 0).FindElements(By.TagName("a")), "Request grid should not have link for Request name");

                                                            Assert.IsNotNull(dashboard.ViewAllLogsLink(), "View all request logs link should be present");
                                                            Assert.IsNotNull(dashboard.ViewErrorLog(), "Error log link should be present");
                                                            Assert.IsNull(dashboard.ExchangeIntegrationLink(), "Exchange Integration link should not be visible");

                                                            dashboard.Summary.Total.Link().WithJs().Click();
                                                        });

            driver.With<QueuePageObject>((queue, popups) =>
                                                    {
                                                        //Filter on case ref

                                                        queue.QueueGrid.CaseReferenceFilter.Open();
                                                        queue.QueueGrid.CaseReferenceFilter.SelectOption(irn);
                                                        queue.QueueGrid.CaseReferenceFilter.Filter();

                                                        Assert.LessOrEqual(5, queue.QueueGrid.MasterRows.Count);

                                                        var currentCaseRefLink = queue.QueueGrid.MasterCell(0, 4).FindElements(By.TagName("a")).FirstOrDefault();
                                                        Assert.IsNotNull(currentCaseRefLink);
                                                        currentCaseRefLink.TestIeOnlyUrl(caseRefUrl);

                                                        var eventText = queue.QueueGrid.MasterCellText(0, 6);
                                                        Assert.IsTrue(eventText.Contains(data.Event.Id.ToString()), "Policing Queue contains record with specific event no");

                                                        //Event is not hyperlink
                                                        Assert.AreEqual(0, queue.QueueGrid.MasterCell(0, 6).FindElements(By.TagName("a")).Count);

                                                        //No other operation is possible
                                                        Assert.IsTrue(queue.ActionMenu.IsNotAvailable(), "Queue administration menu should not available");

                                                        queue.BackToDashboardLink().WithJs().Click();
                                                    });

            driver.With<DashboardPageObject>((dashboard, popups) =>
                                                        {
                                                            //Navigate to error log page
                                                            dashboard.ViewErrorLog().WithJs().Click();

                                                            const string errorLogUrl = "#/policing-error-log";
                                                            var currentUrl = driver.WithJs().GetUrl();
                                                            Assert.IsTrue(currentUrl.Contains(errorLogUrl), "Navigates to error log page");
                                                        });

            driver.With<ErrorLogPageObject>((errorLog, popups) =>
                                                       {
                                                           //Only view is possible on error log
                                                           Assert.True(errorLog.ErrorLogGrid.ActionMenu.IsNotAvailable(), "Error log administration menu should not be available");
                                                       });
        }
    }
}