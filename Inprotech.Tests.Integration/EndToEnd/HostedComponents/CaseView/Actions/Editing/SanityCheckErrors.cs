using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.DataValidation;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.HostedComponents.CaseView.Actions.Editing
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SanityCheckErrors : HostedActionComponentEditing
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedActionComponentSanityCheckErrorsPresent(BrowserType browserType)
        {
            TurnOffDataValidations();
            var setup = new CaseDetailsActionsDbSetup();
            var data = setup.ActionsSetup();

            var dv = new DataValidation();
            DbSetup.Do(db =>
            {
                dv.InUseFlag = true;
                dv.FunctionalArea = "C";
                dv.DisplayMessage = "TEST";
                dv.RuleDescription = "TEST";
                dv.Notes = "TEST";
                dv.PropertyType = data.@case.PropertyTypeId;
                dv.CaseType = data.@case.TypeId;
                dv.IsWarning = false;
                dv.CanOverrideRoleId = 5;
                db.DbContext.Set<DataValidation>().Add(dv);
                db.DbContext.SaveChanges();
            });
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
                var datePicker = rowOne.EventDatepickers;
                datePicker.Input.Clear();
                datePicker.Open();
                datePicker.NextMonth();
                datePicker.GoToDate("1");
                var alertPopup = new CommonPopups(driver);
                alertPopup.InfoModal.Ok();

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
            page.WaitForLifeCycleAction("SanityCheckResults");

            var sanityCheckResult = page.LifeCycleMessages.Last();
            var payload = sanityCheckResult.Payload.ToObject<HostedTestPageObject.SanityCheckPayload[]>();
            Assert.AreEqual("TEST", payload[0].DisplayMessage);
            page.CallOnRequestDataResponse(new HostedTestPageObject.DataReceivedMessage<bool>("sanityCheckClosed", false));
            driver.DoWithinFrame(() =>
            {
                var pageObject = new HostedTopicPageObject(driver);
                Assert.False(pageObject.SaveButton.IsDisabled(), "Does not successfully save if sanity check errors present");
                Assert.False(pageObject.RevertButton.IsDisabled(), "Does not successfully save if sanity check errors present");
                pageObject.SaveButton.Click();
            });

            AssertRequestsIsPoliceImmediately(page);
            page.CallOnRequestDataResponse(new HostedTestPageObject.DataReceivedMessage<bool>("isPoliceImmediately", true));
            page.WaitForLifeCycleAction("SanityCheckResults");
            page.CallOnRequestDataResponse(new HostedTestPageObject.DataReceivedMessage<bool>("sanityCheckClosed", true));

            AssertRequestsIsPoliceImmediately(page);
            page.CallOnRequestDataResponse(new HostedTestPageObject.DataReceivedMessage<bool>("isPoliceImmediately", true));

            driver.DoWithinFrame(() =>
            {
                var pageObject = new HostedTopicPageObject(driver);
                Assert.True(pageObject.SaveButton.IsDisabled(), "Successfully save if sanity check force sent as true");
                Assert.True(pageObject.RevertButton.IsDisabled(), "Successfully save if sanity check force sent as true");
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TestHostedActionComponentSanityCheckOnlyWarningsPresent(BrowserType browserType)
        {
            TurnOffDataValidations();
            var setup = new CaseDetailsActionsDbSetup();
            var data = setup.ActionsSetup();

            var dv = new DataValidation();
            DbSetup.Do(db =>
            {
                dv.InUseFlag = true;
                dv.FunctionalArea = "C";
                dv.DisplayMessage = "TEST";
                dv.RuleDescription = "TEST";
                dv.Notes = "TEST";
                dv.PropertyType = data.@case.PropertyTypeId;
                dv.CaseType = data.@case.TypeId;
                dv.IsWarning = true;
                db.DbContext.Set<DataValidation>().Add(dv);
                db.DbContext.SaveChanges();
            });
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
                var datePicker = rowOne.EventDatepickers;
                datePicker.Input.Clear();
                datePicker.Open();
                datePicker.NextMonth();
                datePicker.GoToDate("1");
                var alertPopup = new CommonPopups(driver);
                alertPopup.InfoModal.Ok();

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
            page.WaitForLifeCycleAction("SanityCheckResults");

            var sanityCheckResult = page.LifeCycleMessages.Last();
            var payload = sanityCheckResult.Payload.ToObject<HostedTestPageObject.SanityCheckPayload[]>();
            Assert.AreEqual("TEST", payload[0].DisplayMessage);
            driver.DoWithinFrame(() =>
            {
                var pageObject = new HostedTopicPageObject(driver);
                Assert.True(pageObject.SaveButton.IsDisabled(), "Saved Successfully if sanity check only warnings");
                Assert.True(pageObject.RevertButton.IsDisabled(), "Saved Successfully if sanity check only warnings");
            });
        }
    }
}