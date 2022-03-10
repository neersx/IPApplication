using System;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;
using Keys = OpenQA.Selenium.Keys;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ContinueTimers : IntegrationTest
    {
        TimeRecordingData _dbData;

        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup(withEntriesToday: false, withStartTime: true);
            TimeRecordingDbHelper.SetupFunctionSecurity(new[]
            {
                FunctionSecurityPrivilege.CanRead,
                FunctionSecurityPrivilege.CanInsert,
                FunctionSecurityPrivilege.CanPost,
                FunctionSecurityPrivilege.CanUpdate
            }, _dbData.User.NameId);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ContinueAsTimer(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);
            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            page.PreviousButton.ClickWithTimeout();
            entriesList.OpenTaskMenuFor(0);
            Assert.IsNull(page.ContextMenu.ContinueAsTimerMenu, "Expected Continue As Timer task to be disabled on other date");

            page.TodayButton.ClickWithTimeout();
            page.AddButton.ClickWithTimeout();
            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);

            editableRow.CaseRef.EnterAndSelect("e2eirn");
            var wipWarningsModal = new WipWarningsModal(driver);
            wipWarningsModal.Proceed();
            editableRow.Activity.EnterAndSelect("e2e");

            var timeNow = DateTime.Now.AddMinutes(-5);
            if (timeNow.DayOfYear != DateTime.Now.DayOfYear)
            {
                return; // Don't run test, if its run during last 5 minutes of the day
            }

            var dateToEnter = $"{(timeNow.Hour < 10 ? "0" + timeNow.Hour : timeNow.Hour.ToString())}:{(timeNow.Minute < 10 ? "0" + timeNow.Minute : timeNow.Minute.ToString())}";
            editableRow.StartTime.SetValue(dateToEnter);
            editableRow.StartTime.Input.SendKeys(Keys.Tab);

            dateToEnter = $"{(timeNow.Hour < 10 ? "0" + timeNow.Hour : timeNow.Hour.ToString())}:{(timeNow.Minute < 10 ? "0" + timeNow.AddMinutes(1).Minute : timeNow.AddMinutes(1).Minute.ToString())}";
            editableRow.FinishTime.SetValue(dateToEnter);
            editableRow.FinishTime.Input.SendKeys(Keys.Tab);    

            driver.WaitForAngularWithTimeout();

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().WithJs().Click();

            driver.WaitForAngularWithTimeout();

            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.ContinueAsTimer();
            driver.WaitForAngular();

            var timerRow = new TimeRecordingPage.TimerRow(page.Driver);
            TimerHelpers.CheckTimerRunning(timerRow);
            Assert.AreEqual(_dbData.Case.Irn, entriesList.CellText(0, "Case Ref."), "Expected Case to be copied to continued row");
            Assert.IsTrue(entriesList.CellText(0, "Activity").StartsWith("E2E"), "Expected Activity to be copied to continued row");

            timerRow.OpenTaskMenu();
            page.ContextMenu.Edit();

            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.True(details.SaveButton().Displayed, "Expected Save button to be available");
            Assert.True(details.ClearButton().Displayed, "Expected Reset button to be available");
            Assert.True(details.DeleteTimer().Displayed, "Expected Delete Timer button to be available");

            editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            Assert.True(editableRow.CaseRef.Enabled, "Expected case typeahead to be disabled");
            Assert.AreEqual(_dbData.Case.Irn, editableRow.CaseRef.GetText(), "Expected case to be defaulted");
            Assert.True(editableRow.Name.Enabled, "Expected name typeahead to be disabled");
            Assert.True(editableRow.Activity.Enabled, "Expected activity typeahead to be disabled");
            Assert.True(editableRow.Activity.GetText().StartsWith("E2E"), "Expected Activity to be defaulted");

            entriesList = page.Timesheet;
            timerRow = new TimeRecordingPage.TimerRow(page.Driver);
            timerRow.StopButton.WithJs().Click();
            Assert.AreEqual(2, entriesList.MasterRows.Count, "Expected a new row to be added");
            Assert.NotNull(page.ContinuationIcon(0), "Expected Continuation icon to be displayed");

            Assert.AreEqual(_dbData.Case.Irn, entriesList.CellText(1, "Case Ref."), "Expected Case to be retained on parent row");
            Assert.IsTrue(entriesList.CellText(1, "Activity").StartsWith("E2E"), "Expected Activity to be retained on parent row");
            Assert.IsEmpty(entriesList.CellText(1, "Local Value"), "Expected value to be cleared on parent row");
            Assert.IsEmpty(entriesList.CellText(1, "Duration"), "Expected duration to be cleared on parent row");
            Assert.IsNotEmpty(entriesList.CellText(1, "Start"), "Expected Start to be retained on parent row");
            Assert.IsNotEmpty(entriesList.CellText(1, "Finish"), "Expected Finish to be retained on parent row");

            page.SearchButton.Click();
            new TimeSearchPage(driver).VerifyInSearchResults(1);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ContinueAsTimerAndReset(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);
            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            page.AddButton.ClickWithTimeout();
            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);

            editableRow.CaseRef.EnterAndSelect("e2eirn");
            var wipWarningsModal = new WipWarningsModal(driver);
            wipWarningsModal.Proceed();
            editableRow.Activity.EnterAndSelect("e2e");

            var timeNow = DateTime.Now.AddMinutes(-5);
            if (timeNow.DayOfYear != DateTime.Now.DayOfYear)
            {
                return; // Don't run test, if its run during last 5 minutes of the day
            }

            var dateToEnter = $"{(timeNow.Hour < 10 ? "0" + timeNow.Hour : timeNow.Hour.ToString())}:{(timeNow.Minute < 10 ? "0" + timeNow.Minute : timeNow.Minute.ToString())}";
            editableRow.StartTime.SetValue(dateToEnter);
            editableRow.StartTime.Input.SendKeys(Keys.Tab);

            dateToEnter = $"{(timeNow.Hour < 10 ? "0" + timeNow.Hour : timeNow.Hour.ToString())}:{(timeNow.Minute < 10 ? "0" + timeNow.AddMinutes(1).Minute : timeNow.AddMinutes(1).Minute.ToString())}";
            editableRow.FinishTime.SetValue(dateToEnter);
            editableRow.FinishTime.Input.SendKeys(Keys.Tab);    

            driver.WaitForAngularWithTimeout();

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().WithJs().Click();

            driver.WaitForAngularWithTimeout();

            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.ContinueAsTimer();
            driver.WaitForAngular();

            var timerRow = new TimeRecordingPage.TimerRow(page.Driver);
            TimerHelpers.CheckTimerRunning(timerRow);
            Assert.AreEqual(_dbData.Case.Irn, entriesList.CellText(0, "Case Ref."), "Expected Case to be copied to continued row");
            Assert.IsTrue(entriesList.CellText(0, "Activity").StartsWith("E2E"), "Expected Activity to be copied to continued row");

            driver.Wait().ForTrue(() => timerRow.ElapsedTime.Contains("00:00:1"));
            timerRow.ResetButton.ClickWithTimeout();

            driver.Wait().ForTrue(() => timerRow.ElapsedTime.Contains("00:00:1"));
            timerRow.ResetButton.ClickWithTimeout();
            driver.With<TimeRecordingWidget>(widget =>
            {
                driver.Wait().ForTrue(() => widget.FindElement(By.Id("clockTimeSpan")).Text.EndsWith(":05"));
                Assert.IsTrue(widget.FindElement(By.Id("clockTimeSpan")).Text.EndsWith(":05"), "Timer widget is reset");
            });
            timerRow.StopButton.WithJs().Click();

            entriesList = page.Timesheet;
            Assert.AreEqual(2, entriesList.MasterRows.Count, "Expected a new row to be added");
            Assert.NotNull(page.ContinuationIcon(0), "Expected Continuation icon to be displayed");
            Assert.AreEqual(_dbData.Case.Irn, entriesList.CellText(1, "Case Ref."), "Expected Case to be retained on parent row");
            Assert.IsTrue(entriesList.CellText(1, "Activity").StartsWith("E2E"), "Expected Activity to be retained on parent row");
            Assert.IsEmpty(entriesList.CellText(1, "Local Value"), "Expected value to be cleared on parent row");
            Assert.IsEmpty(entriesList.CellText(1, "Duration"), "Expected duration to be cleared on parent row");
            Assert.IsNotEmpty(entriesList.CellText(1, "Start"), "Expected Start to be retained on parent row");
            Assert.IsNotEmpty(entriesList.CellText(1, "Finish"), "Expected Finish to be retained on parent row");
        }
    }
}