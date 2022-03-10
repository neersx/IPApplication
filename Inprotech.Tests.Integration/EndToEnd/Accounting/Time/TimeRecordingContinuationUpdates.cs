using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingContinuationUpdates : TimeRecordingContinuationBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ChangeEntryDate(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);

            var page = new TimeRecordingPage(driver);

            var entriesCount = page.Timesheet.MasterRows.Count;

            page.ChangeEntryDate(1, "2000", 5);

            var newCount = page.Timesheet.MasterRows.Count;
            Assert.AreEqual(entriesCount - 2, newCount, "Expected entries to be refreshed after save.");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AdjustUnits(BrowserType browserType)
        {
            TimeRecordingDbHelper.EnableUnitsAdjustmentForContinuedEntries(false);
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;

            var columnSelector = page.ColumnSelector;
            columnSelector.ColumnMenuButtonClick();
            columnSelector.ToggleGridColumn("totalUnits");
            columnSelector.ColumnMenuButtonClick();

            entriesList.OpenTaskMenuFor(1);
            page.ContextMenu.Edit();
            driver.WaitForAngular();

            var editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 1);
            Assert.False(editableRow.Units.Input.Enabled, "Expected Units to be disabled for Continued Entries");

            TimeRecordingDbHelper.EnableUnitsAdjustmentForContinuedEntries(true);

            ReloadPage(driver);
            page = new TimeRecordingPage(driver);
            entriesList = page.Timesheet;

            entriesList.OpenTaskMenuFor(1);
            page.ContextMenu.Edit();
            driver.WaitForAngular();

            editableRow = new TimeRecordingPage.EditableRow(driver, entriesList, 1);
            Assert.True(editableRow.Units.Input.Enabled, "Expected Units to be enabled for Continued Entries");

            var originalUnits = editableRow.Units.Input.WithJs().GetValue();
            editableRow.Units.Input.Clear();
            editableRow.Units.Input.SendKeys((int.Parse(originalUnits) - 1).ToString());

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            Assert.False(details.SaveButton().Enabled, "Expected Save button to be disabled when Units is invalid");

            editableRow.Units.Input.Clear();
            editableRow.Units.Input.SendKeys((int.Parse(originalUnits) + 2).ToString());
            editableRow.Units.Input.SendKeys(Keys.Tab);
            driver.WaitForAngular();
            Assert.True(details.SaveButton().Enabled, "Expected Save button to be enabled when Units is valid");

            details.SaveButton().WithJs().Click();

            driver.WaitForAngular();
            columnSelector = page.ColumnSelector;
            columnSelector.ColumnMenuButtonClick();
            columnSelector.ResetButton.WithJs().Click();
        }
    }
}