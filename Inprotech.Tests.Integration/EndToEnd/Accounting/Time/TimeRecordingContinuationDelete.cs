using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeRecordingContinuationDelete : TimeRecordingContinuationBase
    {

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteTimeEntry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            var totalEntries = page.Timesheet.MasterRows.Count;

            entriesList.OpenTaskMenuFor(1);
            page.ContextMenu.Continue();
            driver.WaitForAngular();

            var continuedEntryEditRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            continuedEntryEditRow.Duration.SetValue("1");

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().WithJs().Click();
            driver.WaitForAngularWithTimeout();

            var continuedEntries = page.Timesheet.ColumnValues(9, 8, true).Count(_ => _ == DbData.ContinuedActivity.Description);
            Assert.AreEqual(3, continuedEntries, "All the entries belonging to the continued chain have same activity");

            page.DeleteEntry(4);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(totalEntries, entriesList.MasterRows.Count, "Expected row to be deleted");
            var continuedColumn = page.Timesheet.MasterCell(0, 2);
            Assert.NotNull(continuedColumn.FindElement(By.CssSelector("ipx-inline-dialog > span.inline-dialog > span.cpa-icon-clock-o")), "Continued icon remains on continued entry");
            continuedEntries = page.Timesheet.ColumnValues(9, 8, true).Count(_ => _ == DbData.ContinuedActivity.Description);
            Assert.AreEqual(2, continuedEntries, "Expected one entry within continued chain to be deleted");

            page.DeleteEntry(2);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(totalEntries - 1, page.Timesheet.MasterRows.Count, "Expected row to be deleted");
            continuedColumn = page.Timesheet.MasterCell(0, 2);
            Assert.Throws<NoSuchElementException>(() => continuedColumn.FindElement(By.CssSelector("ipx-inline-dialog > span.inline-dialog > span.cpa-icon-clock-o")), "Continued icon is removed from continued entry");
            continuedEntries = page.Timesheet.ColumnValues(9, 8, true).Count(_ => _ == DbData.ContinuedActivity.Description);
            Assert.AreEqual(1, continuedEntries, "Expected last entry within continued chain to retain details");

            page.DeleteEntry(0);
            Assert.AreEqual(totalEntries - 2, page.Timesheet.MasterRows.Count, "Expected row to be deleted");
            continuedEntries = page.Timesheet.ColumnValues(9, 8, true).Count(_ => _ == DbData.ContinuedActivity.Description);
            Assert.AreEqual(0, continuedEntries, "Expected all continued entries to have been deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteContinuedChain(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            var totalEntries = page.Timesheet.MasterRows.Count;
            entriesList.OpenTaskMenuFor(1);
            page.ContextMenu.Continue();
            driver.WaitForAngular();
            var continuedEntryEditRow = new TimeRecordingPage.EditableRow(driver, entriesList, 0);
            continuedEntryEditRow.Duration.SetValue("1");

            var details = new TimeRecordingPage.DetailSection(driver, entriesList, 0);
            details.SaveButton().WithJs().Click();
            driver.WaitForAngularWithTimeout();

            page.DeleteEntry(2, true);
            Assert.AreEqual(totalEntries - 2, page.Timesheet.MasterRows.Count, "Expected row to be deleted");
            var continuedEntries = page.Timesheet.ColumnValues(9, 8, true).Count(_ => _ == DbData.ContinuedActivity.Description);
            Assert.AreEqual(0, continuedEntries, "Expected all continued entries to have been deleted");
        }
    }
}