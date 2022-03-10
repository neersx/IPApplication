using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Policing.PageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Policing.Scenarios.Administrator
{
    [TestFixture]
    [Category(Categories.E2E)]
    [TestType(TestTypes.Scenario)]
    public class Administration : IntegrationTest
    {
        TestUser _loginUser;

        [SetUp]
        public void CreatePoliceAdminUser()
        {
            _loginUser = new Users()
                .WithPermission(ApplicationTask.PolicingAdministration)
                .WithPermission(ApplicationTask.MaintainPolicingRequest)
                .WithPermission(ApplicationTask.MaintainWorkflowRules)
                .Create();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AdministeringSpecificPolicingItem(BrowserType browserType)
        {
            AdministratorDbSetup.Data data;
            string irn;
            using (var setup = new AdministratorDbSetup().WithPolicingServerOff())
            {
                var collegues = setup.OtherUsers.Create();

                data = setup.WithWorkflowData();
                var case1 = setup.GetCase("test-ref1");
                irn = case1.Irn;
                setup.EnqueueFor(collegues.John, "waiting-to-start", "open-action", case1, null, data.Event.Id, data.Criteria.Id);
                setup.EnqueueFor(collegues.Mary, "waiting-to-start", "due-date-changed", setup.GetCase("test-ref2"));
                setup.EnqueueFor(collegues.John, "waiting-to-start", "due-date-changed", setup.GetCase("test-ref3"));
                setup.EnqueueFor(collegues.Mary, "waiting-to-start", "open-action", setup.GetCase("test-ref4"));
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/policing-dashboard", _loginUser.Username, _loginUser.Password);

            driver.With<DashboardPageObject>((dashboard, popups) =>
                                             {
                                                 var totalCount = dashboard.Summary.Total.Value();
                                                 Assert.LessOrEqual(4, totalCount, "Total number of policing items are 4 or more");

                                                 dashboard.Summary.Total.Link().WithJs().Click();
                                                 
                                                 var currentUrl = driver.WithJs().GetUrl();

                                                 Assert.IsTrue(currentUrl.Contains("#/policing-queue/all"), "Navigates to the total queue page");
                                             });

            driver.With<QueuePageObject>((queue, popups) =>
                                         {
                                             //Filter on case ref

                                             queue.QueueGrid.CaseReferenceFilter.Open();

                                             queue.QueueGrid.CaseReferenceFilter.SelectOption(irn);

                                             queue.QueueGrid.CaseReferenceFilter.Filter();

                                             Assert.AreEqual(1, queue.QueueGrid.MasterRows.Count);

                                             var eventText = queue.QueueGrid.MasterCellText(0, 7);
                                             Assert.IsTrue(eventText.Contains(data.Event.Id.ToString()), "Policing Queue contains record with specific event no");

                                             var eventLink = queue.QueueGrid.MasterCell(0, 7).FindElements(By.TagName("a")).FirstOrDefault();
                                             Assert.IsNotNull(eventLink, "Event is displayed as link");

                                             eventLink.WithJs().Click();
                                             var eventControlUrl = $"#/configuration/rules/workflows/{data.Criteria.Id}/eventcontrol/{data.Event.Id}";
                                             var currentUrl = driver.WithJs().GetUrl();
                                             Assert.IsTrue(currentUrl.Contains(eventControlUrl), "clicking event link should navigate to event control detail screen");

                                             driver.Navigate().Back();
                                         });

            driver.With<QueuePageObject>((queue, popups) =>
                                         {
                                             queue.QueueGrid.CaseReferenceFilter.Open();

                                             queue.QueueGrid.CaseReferenceFilter.SelectOption(irn);

                                             queue.QueueGrid.CaseReferenceFilter.Filter();
                                             // Hold 1 item

                                             queue.QueueGrid.SelectIpCheckbox(0);

                                             queue.ActionMenu.OpenOrClose();

                                             queue.ActionMenu.HoldOption().Click();

                                             Assert.NotNull(popups.FlashAlert(), "Flash alter for status change is displayed");
                                         });

            driver.With<QueuePageObject>((queue, popups) =>
                                         {
                                             // View on hold items
                                             queue.Summary.OnHold.Link().WithJs().Click();

                                             var currentUrl = driver.WithJs().GetUrl();

                                             Assert.IsTrue(currentUrl.Contains("#/policing-queue/on-hold"), "Navigates to on hold queue page");

                                             Assert.LessOrEqual(1, queue.QueueGrid.MasterRows.Count, "On hold records are displayed");
                                         });

            driver.With<QueuePageObject>((queue, popups) =>
                                         {
                                             var onHoldRecordsCount = queue.QueueGrid.MasterRows.Count;

                                             //Release on hold records
                                             queue.QueueGrid.SelectFirstItem();

                                             queue.ActionMenu.OpenOrClose();

                                             queue.ActionMenu.ReleaseOption().WithJs().Click();

                                             Assert.GreaterOrEqual(onHoldRecordsCount, queue.QueueGrid.MasterRows.Count, "No records in on hold queue");
                                         });

            driver.With<QueuePageObject>((queue, popups) =>
                                         {
                                             //Check record in progressing
                                             queue.Summary.Progressing.Link().WithJs().Click();

                                             var currentUrl = driver.WithJs().GetUrl();

                                             Assert.IsTrue(currentUrl.Contains("#/policing-queue/progressing"), "Navigates to progressing queue page");

                                             Assert.LessOrEqual(4, queue.QueueGrid.MasterRows.Count, "progressing records are displayed");
                                         });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PolicingServerStatusIsAccessible(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/policing-dashboard", _loginUser.Username, _loginUser.Password);

            driver.With<DashboardPageObject>((dashboard, popups) =>
                                             {
                                                 var changeStatusButton = dashboard.PolicingStatus.ChangeStatusButton();
                                                 Assert.IsTrue(changeStatusButton != null, "Server status button should be visible only if Policing Administration security right is given");

                                                 changeStatusButton.WithJs().Click();
                                                 Assert2.WaitTrue(10, 500, () => !dashboard.PolicingStatus.IsCheckingStatus, "should switch from checking status");
                                             });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CreatePolicingRequestAndRun(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            
            SignIn(driver, "/#/policing-dashboard", _loginUser.Username, _loginUser.Password);

            driver.With<DashboardPageObject>((dashboard, popups) => { dashboard.MaintainSavedRequestLink().WithJs().Click(); });

            var title = "1A new title" + RandomString.Next(6);

            driver.With<SavedRequestsPageObject>((saveRequests, popups) =>
                                                 {
                                                     saveRequests.Add().ClickWithTimeout();

                                                     //add new request
                                                     saveRequests.MaintenanceModal.Title().SendKeys(title);
                                                     saveRequests.MaintenanceModal.StartDate().Enter(DateTime.Today);
                                                     saveRequests.MaintenanceModal.ForDays().SendKeys("3");
                                                     saveRequests.MaintenanceModal.Save.ClickWithTimeout();

                                                     Assert.NotNull(popups.FlashAlert());

                                                     //run request
                                                     saveRequests.MaintenanceModal.RunNow.Click();
                                                     saveRequests.RunNowConfirmationModal.Proceed().ClickWithTimeout();
                                                     driver.WaitForAngularWithTimeout();

                                                     //navigate to dashboard
                                                     saveRequests.MaintenanceModal.Discard.Click();
                                                     saveRequests.LevelUpButton.ClickWithTimeout();
                                                 });
            driver.Navigate().Refresh();
            driver.With<DashboardPageObject>((dashboard, popups) =>
                                             {
                                                 var recentRequestNames = dashboard.RequestGrid.ColumnValues(0, 10);
                                                 Assert.IsTrue(recentRequestNames.Contains(title));
                                             });
        }
    }
}