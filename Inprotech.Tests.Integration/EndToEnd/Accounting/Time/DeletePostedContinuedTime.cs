using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class DeletePostedContinuedTime : DeletePostedTimeBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteSingleEntry(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            var totalEntries = page.Timesheet.MasterRows.Count;

            entriesList.OpenTaskMenuFor(1);
            page.ContextMenu.Post();

            var postTimePopup = new PostTimePopup(driver, "postTimeModal");
            postTimePopup.PostButton.Click();
            var postTimeFeedbackDlg = new PostFeedbackDlg(driver, "postTimeResDlg");
            postTimeFeedbackDlg.OkButton.WithJs().Click();

            page.DeleteEntry(3);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(totalEntries - 1, page.Timesheet.MasterRows.Count, "Expected row to be deleted");
            var continuedColumn = page.Timesheet.MasterCell(0, 2);
            Assert.Throws<NoSuchElementException>(() => continuedColumn.FindElement(By.CssSelector("ipx-inline-dialog > span.inline-dialog > span.cpa-icon-clock-o")), "Continued icon is removed from continued entry");
            var continuedEntries = page.Timesheet.ColumnValues(9, 8, true).Count(_ => _ == _dbData.ContinuedActivity.Description);
            Assert.AreEqual(1, continuedEntries, "Expected last entry within continued chain to retain details");
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteWholeChain(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var page = new TimeRecordingPage(driver);
            var entriesList = page.Timesheet;
            var totalEntries = page.Timesheet.MasterRows.Count;
            entriesList.OpenTaskMenuFor(1);
            page.ContextMenu.Post();

            var postTimePopup = new PostTimePopup(driver, "postTimeModal");
            postTimePopup.PostButton.Click();
            var postTimeFeedbackDlg = new PostFeedbackDlg(driver, "postTimeResDlg");
            postTimeFeedbackDlg.OkButton.WithJs().Click();

            page.DeleteEntry(1, true);
            Assert.AreEqual(totalEntries - 2, page.Timesheet.MasterRows.Count, "Expected row to be deleted");
            var continuedEntries = page.Timesheet.ColumnValues(9, 8, true).Count(_ => _ == _dbData.ContinuedActivity.Description);
            Assert.AreEqual(0, continuedEntries, "Expected all continued entries to have been deleted");
        }
    }
}