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

namespace Inprotech.Tests.Integration.EndToEnd.Policing.RegressionTests.Queue
{
    [TestFixture]
    [Category(Categories.E2E)]
    [TestType(TestTypes.Regression)]
    public class Queue : IntegrationTest
    {
        private TestUser _loginUser;

        [SetUp]
        public void CreatePoliceAdminUser()
        {
            _loginUser = new Users()
                .WithPermission(ApplicationTask.PolicingAdministration)
                .WithPermission(ApplicationTask.MaintainWorkflowRules)
                .Create();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void PolicingQueueItemDrillsDownToWorkflowRule(BrowserType browserType)
        {
            PolicingDbSetup.Data data;

            var driver = BrowserProvider.Get(browserType);

            using (var setup = new PolicingDbSetup().WithPolicingServerOff())
            {
                var dt = Helpers.UniqueDateTime();

                data = setup.WithWorkflowData();

                setup.Insert(new PolicingLog(dt));

                var @case = setup.GetCase();

                setup.Insert(
                             new PolicingRequest(@case.Id)
                             {
                                 Name = "E2E-" + RandomString.Next(6),
                                 DateEntered = dt,
                                 IsSystemGenerated = 1,
                                 Case = @case,
                                 EventNo = data.Event.Id,
                                 CriteriaNo = data.Criteria.Id,
                                 EventCycle = 1,
                                 OnHold = KnownValues.StringToHoldFlag["on-hold"],
                                 TypeOfRequest = (short) KnownValues.StringToTypeOfRequest["event-occurred"]
                             });

                setup.Insert(
                             new PolicingError(dt, 1)
                             {
                                 Case = @case,
                                 EventNo = data.Event.Id,
                                 CriteriaNo = data.Criteria.Id,
                                 CycleNo = 1
                             });

                setup.Users.WithPermission(ApplicationTask.MaintainWorkflowRules);
            }

            SignIn(driver, "/#/policing-dashboard", _loginUser.Username, _loginUser.Password);
            driver.With<DashboardPageObject>((dashboard, popup) => { dashboard.Summary.OnHold.Link().WithJs().Click(); });

            driver.With<QueuePageObject>((queue, popup) =>
                                         {
                                             // Queue items contains links to Workflow Event Control rule.

                                             var eventLink = queue.QueueGrid.Cell(0, 6).FindElement(By.TagName("a"));

                                             Assert.IsTrue(eventLink.Text.Contains(data.Event.Id.ToString()), "link text should include event number");

                                             eventLink.WithJs().Click();

                                             var eventControlUrl = $"#/configuration/rules/workflows/{data.Criteria.Id}/eventcontrol/{data.Event.Id}";

                                             var currentUrl = driver.WithJs().GetUrl();

                                             Assert.IsTrue(currentUrl.Contains(eventControlUrl), "clicking event link should navigate to event control detail screen");

                                             driver.Navigate().Back();
                                         });

            driver.With<QueuePageObject>((queue, popup) =>
                                         {
                                             // Queue items contains links to Workflow rule.

                                             var cell = queue.QueueGrid.Cell(0, 9);

                                             var criteriaNumberLink = cell.FindElement(By.TagName("a"));

                                             Assert.IsTrue(criteriaNumberLink.Text.Contains(data.Criteria.Id.ToString()), "link text should include criteria number");

                                             criteriaNumberLink.WithJs().Click();

                                             driver.WaitForAngularWithTimeout();

                                             var criteriaUrl = $"#/configuration/rules/workflows/{data.Criteria.Id}";

                                             var currentUrl = driver.WithJs().GetUrl();

                                             Assert.IsTrue(currentUrl.Contains(criteriaUrl), "clicking criteria link should navigate to criteria edit screen");
                                         });
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void DelayingProcessingOfPolicingItemInQueue(BrowserType browserType)
        {
            string irn;
            using (var setup = new PolicingDbSetup().WithPolicingServerOff())
            {
                var @case = setup.GetCase("test-ref1");

                irn = @case.Irn;

                setup.Insert(new PolicingRequest(@case.Id)
                             {
                                 OnHold = KnownValues.StringToHoldFlag["on-hold"],
                                 TypeOfRequest = (short) KnownValues.StringToTypeOfRequest["open-action"],
                                 IsSystemGenerated = 1,
                                 Name = "E2E Test " + RandomString.Next(6),
                                 DateEntered = Helpers.UniqueDateTime(),
                                 SequenceNo = 1
                             });
            }

            int initial;
            int result;
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/policing-queue/on-hold", _loginUser.Username, _loginUser.Password);

            driver.With<QueuePageObject>((queue, popup) =>
                                         {
                                             // Schedule next run on an item.

                                             initial = queue.QueueGrid.GetStatusCount("On Hold", "on-hold");

                                             queue.QueueGrid.SelectFirstItem();

                                             queue.ActionMenu.OpenOrClose();

                                             queue.ActionMenu.EditNextRun().WithJs().Click();

                                             queue.NextRunTimeModal.DatePicker().Enter("2050-01-01");

                                             queue.NextRunTimeModal.Save();

                                             driver.WaitForBlockUi();

                                             result = queue.QueueGrid.GetStatusCount("On Hold", "on-hold");

                                             Assert.AreEqual(1, initial - result, "The item has been released");

                                             queue.Summary.Progressing.Link().WithJs().Click();
                                         });

            driver.With<QueuePageObject>((queue, popup) =>
                                         {
                                             // next run appears on.

                                             queue.QueueGrid.CaseReferenceFilter.Open();

                                             queue.QueueGrid.CaseReferenceFilter.SelectOption(irn);

                                             queue.QueueGrid.CaseReferenceFilter.Filter();

                                             driver.WaitForBlockUi();

                                             Assert.IsTrue(queue.QueueGrid.MasterCellText(0, 10).Contains("01-Jan-2050"));
                                         });

            driver.With<QueuePageObject>((queue, popup) =>
                                         {
                                             // modify the date.
                                             queue.QueueGrid.SelectFirstItem();

                                             queue.ActionMenu.OpenOrClose();

                                             queue.ActionMenu.EditNextRun().WithJs().Click();

                                             Assert.AreEqual("01-Jan-2050", queue.NextRunTimeModal.DatePicker().Input.GetAttribute("value"));

                                             queue.NextRunTimeModal.DatePicker().Enter("2050-02-02", true);

                                             queue.NextRunTimeModal.Save();

                                             driver.WaitForBlockUi();

                                             var nextRun = queue.QueueGrid.MasterCellText(0, 10);

                                             Assert.IsTrue(nextRun.Contains("02-Feb-2050"), "The grid should contain '2 Feb 2050'");
                                         });
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void QueueAutomaticRefresh(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            using (var setup = new QueueDbSetup())
            {
                var colleages = setup.OtherUsers.Create();
                var queue = setup.EnqueueFor(colleages.John, "in-error", "open-action", setup.GetCase("test-ref1"));
                Enumerable.Range(0, 7).ToList().ForEach(x => { setup.CreateErrorFor(queue); });

                setup.EnqueueFor(colleages.John, "on-hold", "event-occurred", setup.GetCase("test-ref2"));
                setup.EnqueueFor(colleages.Mary, "waiting-to-start", "document-case-changes", setup.GetCase("test-ref3"));
                setup.EnqueueFor(colleages.Mary, "in-progress", "action-recalculation", setup.GetCase("test-ref4"));
            }

            SignIn(driver, "/#/policing-queue/all?rinterval=600", _loginUser.Username, _loginUser.Password);

            driver.With<QueuePageObject>((queue, popups) =>
                                         {
                                             Assert.True(queue.AutomaticRefreshSwitch.IsSelected());
                                             Assert.Null(popups.FlashAlert(), "There should not be any popups");

                                             queue.QueueGrid.SelectRow(0);
                                             driver.Wait().ForTrue(()=>!queue.AutomaticRefreshSwitch.IsSelected());

                                             queue.QueueGrid.SelectRow(0);
                                             driver.Wait().ForTrue(() => queue.AutomaticRefreshSwitch.IsSelected());

                                             queue.ViewAllErrorsLink().Click();
                                             driver.Wait().ForTrue(() => !queue.AutomaticRefreshSwitch.IsSelected());

                                             popups.Dismiss();
                                             driver.Wait().ForTrue(() => queue.AutomaticRefreshSwitch.IsSelected());

                                             queue.QueueGrid.CaseReferenceFilter.Open();
                                             driver.Wait().ForTrue(() => !queue.AutomaticRefreshSwitch.IsSelected());
                                             queue.QueueGrid.CaseReferenceFilter.Clear();
                                             driver.Wait().ForTrue(() => queue.AutomaticRefreshSwitch.IsSelected());

                                             //Does not work in IE
                                             queue.AutomaticRefreshSwitch.Toggle();
                                             driver.Wait().ForTrue(() => !queue.AutomaticRefreshSwitch.IsSelected());

                                             queue.QueueGrid.SelectRow(0);
                                             driver.Wait().ForTrue(() => !queue.AutomaticRefreshSwitch.IsSelected());

                                             queue.QueueGrid.SelectRow(0);
                                             driver.Wait().ForTrue(() => !queue.AutomaticRefreshSwitch.IsSelected());

                                             queue.ViewAllErrorsLink().Click();
                                             driver.Wait().ForTrue(() => !queue.AutomaticRefreshSwitch.IsSelected());

                                             driver.Wait().ForTrue(() => !queue.AutomaticRefreshSwitch.IsSelected());
                                         });
        }
    }
}