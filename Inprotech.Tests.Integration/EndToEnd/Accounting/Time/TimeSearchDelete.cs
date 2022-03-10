using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeSearchDelete : TimeSearchBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        public void SelectAllAndDelete(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            var popups = new CommonPopups(driver);
            page.SearchButton.Click();
            var search = new TimeSearchPage(driver);
            search.FromDate.GoToDate(-1);
            search.ToDate.GoToDate(0);
            search.SearchButton.ClickWithTimeout();
            search.SearchResults.ActionMenu.OpenOrClose();
            search.SearchResults.ActionMenu.SelectAll();
            search.Delete.Click();
            var confirmDeleteDialog = new AngularConfirmDeleteModal(driver);
            confirmDeleteDialog.Delete.ClickWithTimeout();

            popups.WaitForFlashAlert();
            driver.WaitForAngular();

            Assert.AreEqual(1, search.SearchResults.Rows.Count, "All rows except posted are deleted");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        public void SelectItemsAndDelete(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            var popups = new CommonPopups(driver);

            page.SearchButton.Click();
            var search = new TimeSearchPage(driver);

            search.FromDate.GoToDate(-1);
            search.ToDate.GoToDate(0);
            search.SearchButton.ClickWithTimeout();

            var uiCountBeforeDelete = search.SearchResults.Rows.Count;
            var dbCountBeforeDelete = CurrentDiaryCountForUser;

            search.SearchResults.SelectRow(0);
            search.SearchResults.SelectRow(1);
            search.SearchResults.ActionMenu.OpenOrClose();
            search.Delete.Click();
            var confirmDeleteDialog = new AngularConfirmDeleteModal(driver);
            confirmDeleteDialog.Delete.ClickWithTimeout();

            popups.WaitForFlashAlert();
            driver.WaitForAngular();

            Assert.AreEqual(uiCountBeforeDelete - 2, search.SearchResults.Rows.Count, "The two selected rows are deleted");
            Assert.AreEqual(dbCountBeforeDelete - 3, CurrentDiaryCountForUser, "All the entries in the continued chain are deleted");
        }
    }
}