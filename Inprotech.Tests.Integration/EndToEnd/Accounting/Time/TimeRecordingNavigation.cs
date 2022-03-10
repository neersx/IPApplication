using System;
using System.Collections.Generic;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingNavigation : TimeRecordingReadOnly
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void TimeRecordingEntryPointAndColumnsSelection(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);

            var page = new TimeRecordingPage(driver);
            TimeGridHelper.TestColumnSelection(page.Timesheet, page.ColumnSelector, driver,
                                               new Dictionary<string, string>
                                               {
                                                   {"totalUnits", "Units"},
                                                   {"chargeOutRate", "Charge Rate"},
                                                   {"localDiscount", "Local Discount"},
                                                   {"foreignDiscount", "Foreign Discount"}
                                               });
            
            var columnSelector = page.ColumnSelector;
            columnSelector.ColumnMenuButtonClick();
            columnSelector.ToggleGridColumn("totalUnits");
            columnSelector.ToggleGridColumn("name");
            columnSelector.ColumnMenuButtonClick();
            Assert.True(page.Timesheet.HeaderColumnsFields.Contains("totalUnits"), "Units Column is displayed");

            var menu = new MenuItems(driver);
            menu.TogglElement.Click();

            var timeRecording = menu.TimeRecording;
            timeRecording.FindElement(By.TagName("a")).WithJs().Click();

            var newWindow = driver.SwitchTo().Window(driver.WindowHandles[1]);
            Assert.IsTrue(newWindow.Url.Contains("#/accounting/time"), "Expected time recording to open in new window or tab");

            page = new TimeRecordingPage(driver);
            Assert.False(page.Timesheet.HeaderColumnsFields.Contains("name"), "Name Column is not displayed as per local saved setting");
            Assert.Contains("totalUnits", page.Timesheet.HeaderColumnsFields, "Units Column is displayed as per local saved setting");

            columnSelector.ColumnMenuButtonClick();
            columnSelector.ResetButton.WithJs().Click();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ChangingTimeEntryDates(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            var selectedDate = page.SelectedDate;
            var today = DateTime.Now.Date;
            Assert.AreEqual(today, DateTime.Parse(selectedDate.Value), $"Expected selected date of {selectedDate.Value} to be {today}");

            var entriesList = page.Timesheet;
            entriesList.ToggleDetailsRow(0);
            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            var narrative = details.NarrativeText;
            Assert.True(narrative.Value().StartsWith("short-narrative"), "Expected current date entries to be displayed");
            entriesList.ToggleDetailsRow(0);

            page.NextButton.ClickWithTimeout();
            entriesList.ToggleDetailsRow(0);
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            narrative = details.NarrativeText;
            Assert.True(narrative.Value().StartsWith("tomorrow"), "Expected next date entries to be displayed after clicking Next");
            entriesList.ToggleDetailsRow(0);
            Assert.True(page.TotalHours.Displayed, "Expected Total Hours to be displayed when there are no chargeable entries");
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Id("totalValue")), "Expected Total Value to be hidden when there are no chargeable entries");
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.Id("totalChargeable")), "Expected Chargeable Totals to be hidden when there are no chargeable entries");
            Assert.AreEqual(1, entriesList.Rows.Count, $"Expected 1 record displayed for the date, but was {entriesList.Rows.Count}");

            page.TodayButton.ClickWithTimeout();
            entriesList.ToggleDetailsRow(0);
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            narrative = details.NarrativeText;
            Assert.True(narrative.Value().StartsWith("short-narrative"), "Expected current date entries to be displayed after clicking Today");
            entriesList.ToggleDetailsRow(0);

            page.PreviousButton.ClickWithTimeout();
            entriesList.ToggleDetailsRow(0);
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            narrative = details.NarrativeText;
            Assert.True(narrative.Value().StartsWith("yesterday"), "Expected previous date entries to be displayed after clicking Previous");
            entriesList.ToggleDetailsRow(0);
            Assert.AreEqual(today.AddDays(-1), DateTime.Parse(selectedDate.Value), $"Expected selected date of {selectedDate.Value} to be {today.AddDays(-1)}");
            Assert.AreEqual(1, entriesList.Rows.Count, $"Expected 1 record displayed for the date, but was {entriesList.Rows.Count}");

            page.PreviousButton.ClickWithTimeout();
            Assert.AreEqual(today.AddDays(-2), DateTime.Parse(selectedDate.Value), $"Expected selected date of {selectedDate.Value} to be {today.AddDays(-2)}");
            Assert.AreEqual(1, entriesList.Rows.Count, $"Expected 1 record displayed for the date, but was {entriesList.Rows.Count}");

            page.NextButton.ClickWithTimeout();
            Assert.AreEqual(today.AddDays(-1), DateTime.Parse(selectedDate.Value), $"Expected selected date of {selectedDate.Value} to be {today.AddDays(-1)}");
            Assert.AreEqual(1, entriesList.Rows.Count, $"Expected 1 record displayed for the date, but was {entriesList.Rows.Count}");

            page.NextButton.ClickWithTimeout();
            Assert.AreEqual(today, DateTime.Parse(selectedDate.Value), $"Expected selected date of {selectedDate.Value} to be {today}");
            Assert.AreEqual(7, entriesList.Rows.Count, $"Expected 1 record displayed for the date, but was {entriesList.Rows.Count}");

            page.NextButton.ClickWithTimeout();
            Assert.AreEqual(today.AddDays(1), DateTime.Parse(selectedDate.Value), $"Expected selected date of {selectedDate.Value} to be {today.AddDays(1)}");
            Assert.AreEqual(1, entriesList.Rows.Count, $"Expected 1 record displayed for the date, but was {entriesList.Rows.Count}");

            page.TodayButton.ClickWithTimeout();
            entriesList.ToggleDetailsRow(0);
            details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            narrative = details.NarrativeText;
            Assert.True(narrative.Value().StartsWith("short-narrative"), "Expected current date entries to be displayed again after clicking Today");
            entriesList.ToggleDetailsRow(0);
        }
        
    }
}