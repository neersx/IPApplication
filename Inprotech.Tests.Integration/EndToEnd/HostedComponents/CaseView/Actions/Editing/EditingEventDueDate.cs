using System;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.Actions.Editing
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EditingEventDueDate : HostedActionComponentEditing
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedActionComponentEditingEventDateDueDate(BrowserType browserType)
        {
            TurnOffDataValidations();
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
            var today = DateTime.Today;
            var nextMonth = today.AddMonths(1);

            var nextMonthString = new DateTime(nextMonth.Year, nextMonth.Month, 1).ToString("dd-MMM-yyyy");
            driver.DoWithinFrame(() =>
            {
                var pageObject = new HostedTopicPageObject(driver);
                Assert.True(pageObject.SaveButton.IsDisabled());
                Assert.True(pageObject.RevertButton.IsDisabled());
                var actions = new ActionTopic(driver);
                actions.ActionGrid.ClickRow(1);
                driver.WaitForAngular();
                Assert.AreEqual(2, actions.EventsGrid.Rows.Count);
                actions.EventsGrid.OpenTaskMenuFor(1);
                actions.ContextMenu.Edit();
                var rowOne = new EditRow(driver, actions.EventsGrid.Rows[1]);
                Assert.False(string.IsNullOrWhiteSpace(actions.EventsGrid.Cell(0, 4).Text));
                var datePicker = rowOne.EventDatepickers;
                datePicker.Input.Clear();
                datePicker.Open();
                datePicker.NextMonth();
                datePicker.GoToDate("1");
                var alertPopup = new CommonPopups(driver);
                alertPopup.InfoModal.Ok();
                var dueDatePicker = rowOne.EventDueDatepickers;
                dueDatePicker.Input.Clear();
                dueDatePicker.Input.SendKeys("01-Jan-2000");

                Assert.False(pageObject.SaveButton.IsDisabled());
                Assert.False(pageObject.RevertButton.IsDisabled());
                actions.EventsGrid.OpenTaskMenuFor(1);
                Assert.True(actions.ContextMenu.RevertMenu.Displayed);
                Assert.NotNull(rowOne.EventDatepickers);
                driver.WaitForAngular();
                actions.IsAllEvents.Click();
                driver.WaitForAngular();
                rowOne = new EditRow(driver, actions.EventsGrid.Rows[3]);
                Assert.False(pageObject.SaveButton.IsDisabled());
                Assert.False(pageObject.RevertButton.IsDisabled());
                var value = rowOne.EventDatepickers.Input.Value();
                Assert.AreEqual(nextMonthString, value);
                pageObject.SaveButton.Click();
            });

            AssertRequestsIsPoliceImmediately(page);
            page.CallOnRequestDataResponse(new HostedTestPageObject.DataReceivedMessage<bool>("isPoliceImmediately", true));
            driver.DoWithinFrame(() =>
            {
                var pageObject = new HostedTopicPageObject(driver);
                Assert.True(pageObject.SaveButton.IsDisabled());
                Assert.True(pageObject.RevertButton.IsDisabled());
                driver.WaitForAngular();
                var actions = new ActionTopic(driver);
                Assert.AreEqual(nextMonthString, actions.EventsGrid.Cell(3, 5).Text);
            });
        }
    }
}