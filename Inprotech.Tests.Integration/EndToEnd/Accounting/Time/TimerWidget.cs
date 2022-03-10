using System;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimerWidget : IntegrationTest
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
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void StartTimers(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            var portalTab = SignIn(driver, String.Empty, _dbData.User.Username, _dbData.User.Password);
            var timerStartTime = string.Empty;
            var activity = string.Empty;

            var timesheetTab = OpenAnotherTab(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password, browserType);
            driver.With<TimeRecordingPage>(page =>
            {
                var timerRow = TimerHelpers.StartTimer(page);
                timerStartTime = timerRow.StartTime;
            });

            driver.SwitchTo().Window(portalTab);
            driver.With<TimeRecordingWidget>(widget =>
            {
                Assert2.WaitTrue(5, 500, () => widget.TimerIcon.Displayed, "Timer is displayed");
                Assert.True(widget.TimerIcon.Displayed);
            });

            driver.SwitchTo().Window(timesheetTab);
            driver.With<TimeRecordingPage>(page =>
            {
                var entriesList = page.Timesheet;
                var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
                var detailSection = new TimeRecordingPage.DetailSection(driver, entriesList, 0);

                editableRow.CaseRef.EnterAndSelect(_dbData.Case.Irn);
                var wipWarningsModal = new WipWarningsModal(driver);
                wipWarningsModal.Proceed();

                editableRow.Activity.EnterAndSelect("NEWWIP");
                activity = editableRow.Activity.InputValue;
                driver.WaitForAngular();

                detailSection.SaveButton().Click();
            });

            driver.SwitchTo().Window(portalTab);
            driver.WaitForAngularWithTimeout(500, 5);
            driver.With<TimeRecordingWidget>(widget =>
            {
                if (browserType == BrowserType.Chrome)
                {
                    widget.CheckTooltipValues(timerStartTime, _dbData.Case.Irn, null, activity);
                }

                widget.StopButton.Click();
            });

            driver.SwitchTo().Window(timesheetTab);
            ReloadPage(driver);
            driver.With<TimeRecordingPage>(page => { Assert.False(TimerHelpers.IsTimerRunning(driver)); });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ResetAndStopStartedTimer(BrowserType browserType)
        {
            var timer = TimeRecordingDbHelper.StartTimer(_dbData.StaffName.Id, _dbData.Case.Id);

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, String.Empty, _dbData.User.Username, _dbData.User.Password);

            driver.With<TimeRecordingWidget>(widget =>
            {
                Assert2.WaitTrue(5, 500, () => widget.TimerIcon.Displayed, "Timer is displayed");
                Assert.True(widget.TimerIcon.Displayed);

                widget.TimerIcon.Click();
                driver.WaitForAngular();
            });

            var timerWidgetPopup = new TimerWidgetPopup(driver);
            Assert.NotNull(timerWidgetPopup, "The timer basic details widget popup is displayed");

            timerWidgetPopup.Reset();
            new DriverWait(driver).ForTrue(()=> timerWidgetPopup.ClockTimeSpan.Text.Contains(":02"));
            timerWidgetPopup.Reset();
            driver.With<TimeRecordingWidget>(widget =>
            {
                driver.Wait().ForTrue(() => widget.FindElement(By.Id("clockTimeSpan")).Text.EndsWith(":05"));
                Assert.IsTrue(widget.FindElement(By.Id("clockTimeSpan")).Text.EndsWith(":05"), "Timer widget is reset");
            });

            timerWidgetPopup.Activity.EnterAndSelect("NEWWIP");
            timerWidgetPopup.Notes.Input.SendKeys("New Notes!");
            timerWidgetPopup.Stop();

            driver.With<TimeRecordingWidget>(widget => { Assert.False(widget.IsDisplayed, "Widget is not hidden, since timer is stopped"); });

            TimeRecordingDbHelper.CheckValues(timer.EntryNo, "NEWWIP");
        }
    }
}