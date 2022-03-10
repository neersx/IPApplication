using System;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [SplitWipMultiDebtor]
    [Category(Categories.E2E)]
    [TestFixture]
    public class MultiDebtorTimers : IntegrationTest
    {
        TimeRecordingData _dbData;
        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup(true, true, withMultiDebtorEnabled: true, withEntriesToday: false);
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void StartTimer(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            page.StartTimerLink.Click();

            var timerRow = new TimeRecordingPage.TimerRow(driver);

            timerRow.CaseRef.EnterAndSelect(_dbData.Case.Irn);
            var wipWarningDialog = new WipWarningsModal(driver);
            wipWarningDialog.Proceed();
            
            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            var activityPicker = editableRow.Activity;
            activityPicker.SendKeys(Keys.ArrowDown);
            activityPicker.SendKeys(Keys.ArrowDown);
            activityPicker.SendKeys(Keys.Enter);

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().ClickWithTimeout();

            timerRow = new TimeRecordingPage.TimerRow(driver);
            var elapsedTime = DateTime.Now.TimeOfDay;
            var currentTime = DateTime.Now.TimeOfDay;
            while (elapsedTime < currentTime.Add(TimeSpan.FromMinutes(1)))
            {
                elapsedTime = DateTime.Now.TimeOfDay;
            }
            timerRow.StopButton.WithJs().Click();

            entriesList.ToggleDetailsRow(0);
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.AreEqual(string.Empty, details.ChargeRate, $"Expected charge rate to be blank but was '{details.ChargeRate}'.");
            Assert.True(details.MultiDebtorChargeRate.Displayed, "Expected icon for different charge rates is displayed");
            Assert.True(details.LocalValue.Contains("12.00"), $"Expected local value to display aggregate but was '{details.LocalValue}'.");
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

            driver.WaitForAngularWithTimeout();

            entriesList.Add();

            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            var currentTime = DateTime.Now.TimeOfDay;
            var startTime = currentTime.Subtract(TimeSpan.FromMinutes(30));
            editableRow.StartTime.SetValue($"{startTime.Hours}:{startTime.Minutes}"); 
            editableRow.Duration.SetValue("00:01");

            editableRow.CaseRef.EnterAndSelect(_dbData.Case.Irn);
            var wipWarningDialog = new WipWarningsModal(driver);
            wipWarningDialog.Proceed();

            editableRow.Activity.EnterAndSelect(_dbData.NewActivity.WipCode);
            driver.WaitForAngular();

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().ClickWithTimeout();

            driver.WaitForAngular();

            entriesList = page.Timesheet;
            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.Continue();
            editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            editableRow.Duration.SetValue("00:01");
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.AreEqual(string.Empty, details.ChargeRate, $"Expected charge rate to be blank but was '{details.ChargeRate}'.");
            Assert.True(details.LocalValue.Contains("12.00"), $"Expected local value to display aggregate but was '{details.LocalValue}'.");
            Assert.AreEqual("00:02", details.AccumulatedDuration, $"Expected Accumulated Duration to be 00:02 but was '{details.AccumulatedDuration}'");
            details.SaveButton().ClickWithTimeout();

            entriesList = page.Timesheet;
            entriesList.OpenTaskMenuFor(0);
            page.ContextMenu.ContinueAsTimer();

            var timerRow = new TimeRecordingPage.TimerRow(driver);
            var elapsedTime = DateTime.Now.TimeOfDay;
            currentTime = DateTime.Now.TimeOfDay;
            while (elapsedTime < currentTime.Add(TimeSpan.FromMinutes(1)))
            {
                elapsedTime = DateTime.Now.TimeOfDay;
            }
            timerRow.StopButton.WithJs().Click();

            entriesList.ToggleDetailsRow(0);
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.AreEqual(string.Empty, details.ChargeRate, $"Expected charge rate to be blank but was '{details.ChargeRate}'.");
            Assert.True(details.MultiDebtorChargeRate.Displayed, "Expected icon for different charge rates is displayed");
            Assert.True(details.LocalValue.Contains("12.00"), $"Expected local value to display aggregate but was '{details.LocalValue}'.");
            Assert.AreEqual("00:03", details.AccumulatedDuration, $"Expected Accumulated Duration to be 00:03 but was '{details.AccumulatedDuration}'");

            page.SearchButton.Click();
            new TimeSearchPage(driver).VerifyInSearchResults(1);
        }
    }
}