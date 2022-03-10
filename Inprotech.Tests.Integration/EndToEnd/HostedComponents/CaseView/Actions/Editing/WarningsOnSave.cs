using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.Actions.Editing
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class WarningsOnSave : HostedActionComponentEditing
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedTopicActionsWarningsOnSave(BrowserType browserType)
        {
            var setup = new CaseDetailsActionsDbSetup();
            var data = setup.ActionsSetup(true);

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
                var pageObject = new HostedTopicPageObject(driver);
                var actions = new ActionTopic(driver);
                actions.ActionGrid.ClickRow(1);
                driver.WaitForAngular();
                Assert.AreEqual(3, actions.EventsGrid.Rows.Count);
                actions.EventsGrid.OpenTaskMenuFor(0);
                actions.ContextMenu.Edit();
                var rowOne = new EditRow(driver, actions.EventsGrid.Rows[0]);
                var datePicker = rowOne.EventDatepickers;
                datePicker.Input.Clear();
                datePicker.Open();
                datePicker.NextMonth();
                datePicker.GoToDate("1");
                var alertPopup = new CommonPopups(driver);
                alertPopup.InfoModal.Ok();
                pageObject.SaveButton.Click();
            });

            AssertRequestsIsPoliceImmediately(page);
            page.CallOnRequestDataResponse(new HostedTestPageObject.DataReceivedMessage<bool>("isPoliceImmediately", false));
            driver.DoWithinFrame(() =>
            {
                var pageObject = new HostedTopicPageObject(driver);
                Assert.True(pageObject.SaveButton.IsDisabled());
                Assert.True(pageObject.RevertButton.IsDisabled());

                var actions = new ActionTopic(driver);
                var rowOne = new EditRow(driver, actions.EventsGrid.Rows[0]);
                Assert.True(rowOne.EventDatepickers.ErrorIcon != null);
                driver.WaitForAngular();
                actions.EventsGrid.OpenTaskMenuFor(0);
                actions.ContextMenu.Revert();
                driver.WaitForAngular();
                actions.EventsGrid.OpenTaskMenuFor(1);
                actions.ContextMenu.Edit();
                driver.WaitForAngular();
                var rowTwo = new EditRow(driver, actions.EventsGrid.Rows[1]);
                var datePicker = rowTwo.EventDatepickers;
                datePicker.Input.Clear();
                datePicker.Open();
                datePicker.NextMonth();
                datePicker.GoToDate("1");
                var alertPopup = new CommonPopups(driver);
                alertPopup.InfoModal.Ok();
                pageObject.SaveButton.Click();
            });

            AssertRequestsIsPoliceImmediately(page);
            page.CallOnRequestDataResponse(new HostedTestPageObject.DataReceivedMessage<bool>("isPoliceImmediately", false));
            driver.DoWithinFrame(() =>
            {
                var alertPopup2 = new CommonPopups(driver);
                alertPopup2.InfoModal.Confirm();
            });
        }
    }
}