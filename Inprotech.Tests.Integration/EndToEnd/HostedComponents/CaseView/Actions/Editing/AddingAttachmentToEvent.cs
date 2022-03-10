using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.Actions.Editing
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class AddingAttachmentToEvent : HostedActionComponentEditing
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedActionComponentAddingAttachmentToEvent(BrowserType browserType)
        {
            var setup = new CaseDetailsActionsDbSetup();
            var data = setup.ActionsSetup();
            var user = new Users().WithPermission(ApplicationTask.MaintainCaseAttachments).WithPermission(ApplicationTask.MaintainCaseEvent).Create();

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
                var pageObject = new HostedTopicPageObject(driver);
                Assert.True(pageObject.SaveButton.IsDisabled());
                Assert.True(pageObject.RevertButton.IsDisabled());
                var actions = new ActionTopic(driver);
                actions.EventsGrid.OpenTaskMenuFor(1);
                actions.ContextMenu.AddAttachment();
            });

            var argsForAttachmentFromEvent = page.NavigationMessages.Last(_ => string.IsNullOrWhiteSpace(_.Action));
            Assert.AreEqual(argsForAttachmentFromEvent.Args, new[] {"OpenMaintainAttachment", data.CaseId.ToString(), string.Empty, string.Empty, data.OpenAction.Va.ActionId, data.OpenAction.events[1].EventNo.ToString(), data.OpenAction.events[1].Cycle.ToString()});
        }
    }
}