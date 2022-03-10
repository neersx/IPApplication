using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;
using static Inprotech.Tests.Integration.EndToEnd.Accounting.Time.TimeRecordingPage;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class Timers : IntegrationTest
    {
        TimeRecordingData _dbData;

        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup(withEntriesToday: false, withStartTime: true, showSecondsPreference: true);
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
        [TestCase(BrowserType.FireFox)]
        public void StartTimers(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            page.StaffName.EnterAndSelect("Func");
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Id("btnStartTimer")), "Expected Start Timer button to be hidden for other staff");
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Id("lnkStartTimer")), "Expected Start Timer link to be hidden for other staff");

            ReloadPage(driver);

            page = new TimeRecordingPage(driver);
            page.PreviousButton.ClickWithTimeout();
            Assert.True(page.StartTimerButton.IsDisabled(), "Expected adding of Timers to be disabled");
            Assert.True(page.StartTimerLink.IsDisabled(), "Expected adding of Timers to be disabled");

            page.TodayButton.ClickWithTimeout();
            var entriesList = page.Timesheet;
            var totalEntries = entriesList.MasterRows.Count;
            var timerRow = TimerHelpers.StartTimer(page);

            var editableRow = new EditableRow(driver, entriesList, 0);
            editableRow.CaseRef.EnterAndSelect("e2eirn");
            var wipWarningsModal = new WipWarningsModal(driver);
            wipWarningsModal.Proceed();
            editableRow.Activity.EnterAndSelect("e2e");
            timerRow.StopButton.WithJs().Click();
            
            Assert.AreEqual(totalEntries + 1, entriesList.Rows.Count, "Expected a new row to be added");
            timerRow = TimerHelpers.StartTimer(page);
            timerRow.ResetButton.WithJs().Click();
            var elapsedTime = entriesList.Cell(0, 6).WithJs().GetInnerText();
            var currentTime = DateTime.Now.TimeOfDay;
            while (string.IsNullOrEmpty(elapsedTime) && DateTime.Now.TimeOfDay < currentTime.Add(TimeSpan.FromSeconds(5)))
            {
                elapsedTime = entriesList.Cell(0, 6).WithJs().GetInnerText();
            }
            Assert.True(elapsedTime?.StartsWith("00:00:0"), $"Expected Elapsed Time to be reset but was {elapsedTime}");
            var newStartTime = entriesList.Cell(0, 4).WithJs().GetInnerText();

            timerRow = new TimerRow(driver);
            driver.Wait().ForTrue(() => timerRow.ElapsedTime.Contains("00:00:1"));
            timerRow.StopButton.WithJs().Click();
            Assert.AreEqual(totalEntries + 2, entriesList.Rows.Count, "Expected another new row to be added");
            var actualStartTime = entriesList.Cell(0, 4).WithJs().GetInnerText();
            Assert.AreEqual(newStartTime, actualStartTime, $"Expected Start Time to be {newStartTime} but is {actualStartTime}");
            var stoppedDuration = entriesList.CellText(0, "Duration");
            Assert.IsTrue(stoppedDuration.StartsWith("00:00:1"), $"Expected newly stopped timer to have the correct duration but was {stoppedDuration}");

            page.StartTimerLink.Click();
            editableRow = new EditableRow(driver, entriesList, 0);
            editableRow.CaseRef.EnterAndSelect("e2eirn");
            wipWarningsModal = new WipWarningsModal(driver);
            wipWarningsModal.Proceed();
            editableRow.Activity.EnterAndSelect("e2e");

            TimerHelpers.StartTimer(page);
            Assert.AreEqual(1, page.FindElements(By.CssSelector("div.timerSpinner")).Count(), "Expect only one timer to be running");
            
            var details = new DetailSection(driver, page.Timesheet, 0);
            details.ClearButton().Click();

            ReloadPage(driver);

            page = new TimeRecordingPage(driver);
            Assert.AreEqual(1, page.FindElements(By.CssSelector("div.timerSpinner")).Count(), "Expect only one timer to be running");
            timerRow = new TimerRow(driver);
            TimerHelpers.CheckTimerRunning(timerRow);

            timerRow = new TimerRow(page.Driver);
            driver.Wait().ForTrue(() => timerRow.ElapsedTime.Contains("00:00:1"));
            actualStartTime = entriesList.CellText(0, "Start");
            TimerHelpers.StartTimer(page);

            entriesList = page.Timesheet;
            var duration = entriesList.CellText(2, "Duration");
            var newStart = entriesList.CellText(2, "Start");
            Assert.AreEqual(actualStartTime, newStart, $"Expected newly stopped timer to have the correct start time but was {newStart}");
            Assert.IsTrue(duration.StartsWith("00:00:1"), $"Expected newly stopped timer to have the correct duration but was {duration}");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ClearAndDeleteTimers(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            var totalEntries = entriesList.MasterRows.Count;
            TimerHelpers.StartTimer(page);
            
            var editableRow = new EditableRow(driver, entriesList, 0);
            editableRow.CaseRef.EnterAndSelect("e2eirn");

            var wipWarningsModal = new WipWarningsModal(driver);
            wipWarningsModal.Proceed();

            editableRow.Activity.EnterAndSelect("e2e");

            var details = new DetailSection(driver, entriesList, 0);
            details.NarrativeText.SendKeys(Fixture.AlphaNumericString(50));
            details.Notes.SendKeys(Fixture.AlphaNumericString(50));
            details.ClearButton().Click();

            var timerRow = new TimerRow(driver);
            var elapsedTime = timerRow.ElapsedTime;
            var currentTime = DateTime.Now.TimeOfDay;
            while (string.IsNullOrEmpty(elapsedTime) && DateTime.Now.TimeOfDay < currentTime.Add(TimeSpan.FromSeconds(5)))
            {
                elapsedTime = timerRow.ElapsedTime;
            }
            Assert.True(elapsedTime.StartsWith("00:00:0"), $"Expected Elapsed Time to be reset but was {elapsedTime}");
            Assert.AreEqual(string.Empty, editableRow.CaseRef.InputValue, "Expected Case Reference to be cleared");
            Assert.AreEqual(string.Empty, editableRow.Activity.InputValue, "Expected Activity to be cleared");
            Assert.AreEqual(string.Empty, details.NarrativeText.WithJs().GetInnerText(), "Expected Narrative to be cleared");
            Assert.AreEqual(string.Empty, details.Notes.WithJs().GetInnerText(), "Expected Notes to be cleared");

            timerRow.StopButton.WithJs().Click();
            Assert.AreEqual(totalEntries + 1, entriesList.Rows.Count, "Expected a new row to be added");

            TimerHelpers.StartTimer(page);
            details = new DetailSection(driver, entriesList, 0);
            details.NarrativeText.SendKeys(Fixture.AlphaNumericString(50));
            details.Notes.SendKeys(Fixture.AlphaNumericString(50));
            details.DeleteTimer().Click();

            var confirmDeleteDialog = new AngularConfirmDeleteModal(driver);
            confirmDeleteDialog.Delete.ClickWithTimeout();

            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(totalEntries + 1, page.Timesheet.MasterRows.Count, "Expected row to be deleted");

            TimerHelpers.StartTimer(page);
            details = new DetailSection(driver, entriesList, 0);
            details.NarrativeText.SendKeys(Fixture.AlphaNumericString(50));
            details.Notes.SendKeys(Fixture.AlphaNumericString(50));
            page.DeleteEntry(0);

            // Deleting a timer without making changes
            TimerHelpers.StartTimer(page);
            page.DeleteEntry(0);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void EditRunningTimers(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            var timerRow = TimerHelpers.StartTimer(page);
            var editableRow = new EditableRow(driver, entriesList, 0);
            timerRow.OpenTaskMenu();
            Assert.True(page.ContextMenu.EditMenu.Disabled(), "Expected Edit task to be disabled when already in edit mode");

            editableRow.CaseRef.EnterAndSelect("e2eirn");

            var wipWarningsModal = new WipWarningsModal(driver);
            wipWarningsModal.Proceed();

            editableRow.Activity.EnterAndSelect("e2e");
            var details = new DetailSection(driver, entriesList, 0);   
            var narrativeText = Fixture.AlphaNumericString(50);
            var notes = Fixture.AlphaNumericString(50);
            details.NarrativeText.Click();
            details.NarrativeText.SendKeys(narrativeText);
            details.Notes.SendKeys(notes);
            details.SaveButton().ClickWithTimeout();

            timerRow = new TimerRow(driver);
            TimerHelpers.CheckTimerRunning(timerRow);

            ReloadPage(driver);

            timerRow = new TimerRow(driver);
            TimerHelpers.CheckTimerRunning(timerRow);
            timerRow.OpenTaskMenu();
            Assert.False(page.ContextMenu.EditMenu.Disabled(), "Expected Edit task to be enabled for timer row");

            entriesList.ToggleDetailsRow(0);
            details = new DetailSection(driver, entriesList, 0);
            Assert.AreEqual(narrativeText, details.NarrativeText.WithJs().GetValue(), "Expected updated Narrative to have been saved");
            Assert.AreEqual(notes, details.Notes.WithJs().GetValue(), "Expected updated Notes to have been saved");
        }
    }

    public static class TimerHelpers
    {        
        public static TimerRow StartTimer(TimeRecordingPage page)
        {
            page.StartTimerButton.Click();
            var timerRow = new TimerRow(page.Driver);
            CheckTimerRunning(timerRow);

            return timerRow;
        }

        public static void CheckTimerRunning(TimerRow timerRow)
        {
            Assert.True(timerRow.FindElement(By.CssSelector("div.timerSpinner")).Displayed, "Expected spinner icon to be displayed");
            Assert.True(timerRow.StartTime.Length > 0, "Expected Start Time to be set");
            Assert.AreEqual(string.Empty, timerRow.FinishTime, "Expected Finish Time to be blank");
            Assert.True(timerRow.StopButton.Displayed, "Expected Stop button to be displayed");
            Assert.True(timerRow.ResetButton.Displayed, "Expected Reset button to be displayed");
        }

        public static bool IsTimerRunning(NgWebDriver driver)
        {
            return driver.FindElements(By.CssSelector("div.timerSpinner")).Count > 0;
        }
    }
}
