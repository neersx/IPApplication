using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Names;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class PostFromTimeSearch : TimeSearchBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void SelectAllAndPost(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            page.SearchButton.Click();
            var search = new TimeSearchPage(driver);
            search.IsPosted.Click();
            search.FromDate.GoToDate(-1);
            search.ToDate.GoToDate(0);
            search.SearchButton.ClickWithTimeout();
            search.SearchResults.ActionMenu.OpenOrClose();
            search.SearchResults.ActionMenu.SelectAll();
            search.Post.Click();
            TaskBasicTestHelper.PostSelectedEntries(driver, DbData, new PostAllResultExpected {PostedEntryCount = 6, SelectedUserName = DbData.StaffName.FormattedWithDefaultStyle(), UnpostedEntryCount = 2});
        }

        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Chrome)]
        public void SelectItemsAndPost(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            page.SearchButton.Click();
            var search = new TimeSearchPage(driver);
            search.IsPosted.Click();
            search.FromDate.GoToDate(-1);
            search.ToDate.GoToDate(0);
            search.SearchButton.ClickWithTimeout();
            search.SearchResults.ActionMenu.OpenOrClose();
            search.SearchResults.ActionMenu.SelectAll();
            search.SearchResults.SelectRow(0);
            search.SearchResults.SelectRow(2);
            search.SearchResults.ActionMenu.OpenOrClose();
            search.Post.Click();
            TaskBasicTestHelper.PostSelectedEntries(driver, DbData, new PostAllResultExpected {PostedEntryCount = 4, SelectedUserName = DbData.StaffName.FormattedWithDefaultStyle(), UnpostedEntryCount = 2});

            search.IsPosted.Click();
            search.IsUnposted.Click();
            search.SearchButton.ClickWithTimeout();
            search.SearchResults.ActionMenu.OpenOrClose();
            search.SearchResults.ActionMenu.SelectAll();
            search.Post.Click();
            TaskBasicTestHelper.PostSelectedEntries(driver, DbData, new PostAllResultExpected {PostedEntryCount = 0, SelectedUserName = DbData.StaffName.FormattedWithDefaultStyle(), UnpostedEntryCount = null});
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        
        public void PostFutureDate(BrowserType browserType)
        {
            DbSetup.Do(db =>
            {
                var today = DateTime.Today.AddDays(1);
                var currentPeriod = db.DbContext.Set<Period>().SingleOrDefault(_ => _.StartDate <= today && _.EndDate >= today);
                if (currentPeriod == null) return;
                currentPeriod.PostingCommenced = currentPeriod.StartDate.AddDays(-1);
                db.DbContext.SaveChanges();
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            page.SearchButton.Click();
            var search = new TimeSearchPage(driver);
            search.IsPosted.Click();
            search.FromDate.GoToDate(-1);
            search.ToDate.GoToDate(1);
            search.SearchButton.ClickWithTimeout();
            search.SearchResults.ActionMenu.OpenOrClose();
            search.SearchResults.ActionMenu.SelectAll();
            search.Post.Click();

            var postTimePopup = new PostTimePopup(driver, "postTimeModal");
            Assert.False(postTimePopup.PostButton.IsDisabled());
            postTimePopup.PostButton.Click();

            var alert = new AlertModal(driver);
            Assert.IsNotNull(alert, "Expected future date error to be displayed");
            var message = alert.FindElement(By.CssSelector("div.modal-body > p")).Text;
            Assert.IsTrue(message.Contains("future"), $"Expected future date error message to be displayed but was: {message}");    
            alert.Ok();
        }
    }
}
