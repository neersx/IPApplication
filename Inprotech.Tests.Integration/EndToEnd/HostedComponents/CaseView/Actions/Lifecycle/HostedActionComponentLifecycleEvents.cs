using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.Actions.Lifecycle
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class HostedActionComponentLifecycleEvents : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            var setup = new CaseDetailsActionsDbSetup();

            _currentIsImmediately = setup.IsPoliceImmediately;
            _eventLinksToWorkflowWizard = setup.EventLinksToWorkflowWizard;
            setup.EnsureEventLogDoesNotExist();
        }

        [TearDown]
        public void TearDown()
        {
            var setup = new CaseDetailsActionsDbSetup();

            setup.IsPoliceImmediately = _currentIsImmediately;
            setup.EventLinksToWorkflowWizard = _eventLinksToWorkflowWizard;

            setup.RevertEventLog();
            setup.EnsureEventLogDoesNotExist();
        }

        bool _currentIsImmediately;
        bool _eventLinksToWorkflowWizard;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedActionComponentLifecycle(BrowserType browserType)
        {
            var setup = new CaseDetailsActionsDbSetup();
            var data = setup.ActionsSetup();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case View Actions";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(data.CaseIrn);
            driver.WaitForAngular();

            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);
            driver.WaitForAngular();

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var actions = new ActionTopic(driver);
                Assert.True(actions.ActionGrid.Cell(0, "Police Action").FindElements(By.TagName("a")).Any(), "First row shows policing icon");
                Assert.True(actions.ActionGrid.Cell(1, "Police Action").FindElements(By.TagName("a")).Any(), "Second row shows policing icon");
                actions.ActionGrid.Cell(0, "Police Action").FindElement(By.TagName("a")).Click();
                driver.WaitForAngular();

                var policingPopup = new CommonPopups(driver);
                policingPopup.ConfirmModal.PrimaryButton.Click();
                driver.WaitForAngular();
            });

            AssertRequestsIsPoliceImmediately(page);
            page.CallOnRequestDataResponse(new HostedTestPageObject.DataReceivedMessage<bool>("isPoliceImmediately", true));
            driver.WaitForAngular();
            page.WaitForNavigationAction("StartPolicing");
            page.WaitForNavigationAction("StopPolicing");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedActionComponentFeatures(BrowserType browserType)
        {
            var setup = new CaseDetailsActionsDbSetup();
            var data = setup.ActionsSetup();
            setup.EnsureEventLogDoesNotExist();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test");
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case View Actions";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(data.CaseIrn);
            driver.WaitForAngular();

            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);
            driver.WaitForAngular();

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            setup.EventLinksToWorkflowWizard = true;

            TestEventLinkToWorkflowWizard(driver, page, data);

            setup.EventLinksToWorkflowWizard = false;

            TestEventDoesNotLinkToWorkflowWizard(driver);

            driver.DoWithinFrame(() =>
            {
                var actions = new ActionTopic(driver);
                Assert.True(actions.EventsGrid.HeaderColumnsFields.Contains("attachmentCount"), "Attachment field column should be visible in hosted if subject security");

            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AttachmentsColumnAndFunctionality(BrowserType browserType)
        {
            var setup = new CaseDetailsActionsDbSetup();
            var data = setup.ActionsSetup();
            var user = new Users()
                       .WithLicense(LicensedModule.CasesAndNames)
                       .WithSubjectPermission(ApplicationSubject.Attachments)
                       .Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test", user.Username, user.Password);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case View Actions";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(data.CaseIrn);
            driver.WaitForAngular();

            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);
            driver.WaitForAngular();

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var actions = new ActionTopic(driver);
                Assert.True(actions.EventsGrid.HeaderColumnsFields.Contains("attachmentCount"), "Attachment field column should be visible in hosted if subject security");

                actions.EventsGrid.Cell(0, 3).FindElement(By.TagName("ipx-icon")).Click();
            });

            var argsForAttachmentFromEvent = page.NavigationMessages.Last(_ => string.IsNullOrWhiteSpace(_.Action));
            Assert.AreEqual(argsForAttachmentFromEvent.Args, new[] { "CaseEventAttachments", data.CaseId.ToString(), data.OpenAction.Va.ActionId, data.OpenAction.events[0].EventNo.ToString(), data.OpenAction.events[0].Cycle.ToString() });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EventHistoryColumnAndFunctionality(BrowserType browserType)
        {
            var setup = new CaseDetailsActionsDbSetup();
            setup.EnsureLogExists();
            var data = setup.ActionsSetup();
            var user = new Users()
                       .WithLicense(LicensedModule.CasesAndNames)
                       .WithSubjectPermission(ApplicationSubject.Attachments)
                       .Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test", user.Username, user.Password);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case View Actions";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(data.CaseIrn);
            driver.WaitForAngular();

            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);
            driver.WaitForAngular();

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var actions = new ActionTopic(driver);
                Assert.True(actions.EventsGrid.HeaderColumnsFields.Contains("hasEventHistory"), "Event History Column Should be visible");

                actions.EventsGrid.Cell(0, 4).FindElement(By.TagName("a")).Click();
            });

            var argsForAttachmentFromEvent = page.NavigationMessages.Last(_ => string.IsNullOrWhiteSpace(_.Action));
            Assert.AreEqual(argsForAttachmentFromEvent.Args, new[] { "EventHistory", data.CaseId.ToString(), data.OpenAction.events[0].EventNo.ToString(), data.OpenAction.events[0].Cycle.ToString(), data.Criteria.Id.ToString() });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EventHistoryDoesNotShowIfNoTable(BrowserType browserType)
        {
            var setup = new CaseDetailsActionsDbSetup();
            var data = setup.ActionsSetup();
            var user = new Users()
                       .WithLicense(LicensedModule.CasesAndNames)
                       .WithSubjectPermission(ApplicationSubject.Attachments)
                       .Create();
            setup.EnsureEventLogDoesNotExist();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test", user.Username, user.Password);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case View Actions";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(data.CaseIrn);
            driver.WaitForAngular();

            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);
            driver.WaitForAngular();

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var actions = new ActionTopic(driver);
                Assert.False(actions.EventsGrid.HeaderColumnsFields.Contains("hasEventHistory"), "Event History Column Should be visible");
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AttachmentsColumnNotVisibleIfNoSubjectPermission(BrowserType browserType)
        {
            var setup = new CaseDetailsActionsDbSetup();
            var data = setup.ActionsSetup();

            var user = new Users()
                       .WithSubjectPermission(ApplicationSubject.Attachments, SubjectDeny.Select)
                       .WithLicense(LicensedModule.CasesAndNames)
                       .Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test", user.Username, user.Password);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case View Actions";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(data.CaseIrn);
            driver.WaitForAngular();

            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);
            driver.WaitForAngular();

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var actions = new ActionTopic(driver);
                Assert.False(actions.EventsGrid.HeaderColumnsFields.Contains("attachmentCount"), "Attachment field column should not be visible in hosted and no subject security");
            });
        }

        static void TestEventLinkToWorkflowWizard(NgWebDriver driver, HostedTestPageObject page, (int CaseId, string CaseIrn, Importance MaxImportanceLevel, (ValidAction Va, CaseEvent[] events) OpenAction, (ValidAction Va, CaseEvent[] events) OpenActionWithMultipleEvents, (ValidAction Va, CaseEvent[] events) Closed, (ValidAction Va, CaseEvent[] events) Potential, Criteria Criteria, ValidEvent validEvent, CaseEvent caseEvent, Case @case) data)
        {
            driver.DoWithinFrame(() =>
            {
                var actions = new ActionTopic(driver);

                actions.ActionGrid.ClickRow(1);

                var eventWithWfwLink = actions.EventsGrid.Cell(0, 4);
                var eventWithoutWfwLink = actions.EventsGrid.Cell(1, 4);

                Assert.NotNull(eventWithWfwLink.FindElement(By.TagName("a")), "should be a hyperlink");
                Assert.Throws<NoSuchElementException>(() => { eventWithoutWfwLink.FindElement(By.TagName("a")); }, "should not be a hyperlink as no details dates setup");

                eventWithWfwLink.FindElement(By.TagName("a")).Click();
            });

            page.WaitForNavigationAction(null);

            var argsForWorkflowWizardFromEvent = page.NavigationMessages.Last(_ => string.IsNullOrWhiteSpace(_.Action));
            var @event = data.OpenActionWithMultipleEvents.events.ElementAt(0);
            var selectedAction = data.OpenActionWithMultipleEvents.Va.ActionId;

            Assert.AreEqual(argsForWorkflowWizardFromEvent.Args, new[] { "WorkflowWizardFromEvent", data.CaseId.ToString(), @event.EventNo.ToString(), @event.Cycle.ToString(), selectedAction });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EventNotesColumnAndFunctionality(BrowserType browserType)
        {
            var setup = new CaseDetailsActionsDbSetup();
            var data = setup.ActionsSetup();
            var user = new Users()
                       .WithLicense(LicensedModule.CasesAndNames)
                       .WithSubjectPermission(ApplicationSubject.Attachments)
                       .WithPermission(ApplicationTask.AnnotateDueDates)
                       .Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test", user.Username, user.Password);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case View Actions";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(data.CaseIrn);
            driver.WaitForAngular();

            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);
            driver.WaitForAngular();

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var actions = new ActionTopic(driver);
                Assert.True(actions.EventsGrid.HeaderColumnsFields.Contains("hasNotes"), "Has notes field column should be visible in hosted");
                actions.EventsGrid.OpenTaskMenuFor(0);
                actions.ContextMenu.MaintainEventNote();
            });

            var argsForAttachmentFromEvent = page.NavigationMessages.Last(_ => string.IsNullOrWhiteSpace(_.Action));
            Assert.AreEqual(argsForAttachmentFromEvent.Args, new[] { "EventNotes", data.CaseId.ToString(), data.OpenAction.events[0].EventNo.ToString(), data.OpenAction.events[0].Cycle.ToString() });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EventNotesColumnIsReadOnlyIfNoPermission(BrowserType browserType)
        {
            var setup = new CaseDetailsActionsDbSetup();
            var data = setup.ActionsSetup();
            var user = new Users()
                       .WithLicense(LicensedModule.CasesAndNames)
                       .WithSubjectPermission(ApplicationSubject.Attachments)
                       .WithPermission(ApplicationTask.AnnotateDueDates, Deny.Modify | Deny.Create | Deny.Delete)
                       .Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/hosted-test", user.Username, user.Password);
            var page = new HostedTestPageObject(driver);
            page.ComponentDropdown.Text = "Hosted Case View Actions";
            driver.WaitForAngular();

            page.CasePicklist.SelectItem(data.CaseIrn);
            driver.WaitForAngular();

            page.ProgramPicklist.SelectItem(KnownCasePrograms.CaseEntry);
            driver.WaitForAngular();

            page.CaseSubmitButton.Click();
            driver.WaitForAngular();

            page.WaitForLifeCycleAction("onInit");
            page.WaitForLifeCycleAction("onViewInit");

            driver.DoWithinFrame(() =>
            {
                var actions = new ActionTopic(driver);
                Assert.True(actions.EventsGrid.HeaderColumnsFields.Contains("hasNotes"), "Has notes field column should be visible in hosted");

                Assert.AreEqual(0, actions.EventsGrid.Cell(0, 1).FindElements(By.TagName("a")).Count());
            });
        }

        static void TestEventDoesNotLinkToWorkflowWizard(NgWebDriver driver)
        {
            driver.DoWithinFrame(() =>
            {
                var actions = new ActionTopic(driver);

                actions.ActionGrid.ClickRow(0);

                actions.ActionGrid.ClickRow(1);

                Assert.Throws<NoSuchElementException>(() => { actions.EventsGrid.Cell(0, 3).FindElement(By.TagName("a")); }, "should not be a hyperlink because site control prevents it");
                Assert.Throws<NoSuchElementException>(() => { actions.EventsGrid.Cell(1, 3).FindElement(By.TagName("a")); }, "should not be a hyperlink because site control prevents it");
            });
        }

        static void AssertRequestsIsPoliceImmediately(HostedTestPageObject page)
        {
            var requestMessage = page.LifeCycleMessages.Last();
            Assert.AreEqual("isPoliceImmediately", requestMessage.Payload);
            Assert.AreEqual("onRequestData", requestMessage.Action);
        }
    }
}