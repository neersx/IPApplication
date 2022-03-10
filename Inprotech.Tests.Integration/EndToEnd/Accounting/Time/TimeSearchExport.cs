using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TimeSearchExport : TimeSearchBase
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        public void ExportSearchResultsToPdf(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var downloadsFolder = KnownFolders.GetPath(KnownFolder.Downloads);
            ExportHelper.DeleteFilesFromDirectory(downloadsFolder, new[] {"TimeSearchResults.pdf", "TimeSearchResults.docx", "TimeSearchResults.xlsx"});

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            page.SearchButton.Click();

            var search = new TimeSearchPage(driver);

            search.IsPosted.Click();
            search.FromDate.GoToDate(-1);
            search.ToDate.GoToDate(1);

            search.SearchButton.ClickWithTimeout();

            search.SearchResults.ActionMenu.OpenOrClose();
            search.ExportToPdf.Click();
            new CommonPopups(driver).WaitForFlashAlert();

            if (browserType != BrowserType.Chrome) return;

            var pdf = ExportHelper.GetDownloadedFile(driver, "TimeSearchResults.pdf");
            Assert.AreEqual($"{downloadsFolder}\\TimeSearchResults.pdf", pdf);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        public void ExportSearchResultsToExcel(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var downloadsFolder = KnownFolders.GetPath(KnownFolder.Downloads);
            ExportHelper.DeleteFilesFromDirectory(downloadsFolder, new[] {"TimeSearchResults.pdf", "TimeSearchResults.docx", "TimeSearchResults.xlsx"});

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            page.SearchButton.Click();

            var search = new TimeSearchPage(driver);

            search.IsPosted.Click();
            search.FromDate.GoToDate(-1);
            search.ToDate.GoToDate(1);

            search.SearchButton.ClickWithTimeout();

            search.SearchResults.ActionMenu.OpenOrClose();
            search.ExportToExcel.Click();
            new CommonPopups(driver).WaitForFlashAlert();

            if (browserType != BrowserType.Chrome) return;

            var file = ExportHelper.GetDownloadedFile(driver, "TimeSearchResults.xlsx");
            Assert.AreEqual($"{downloadsFolder}\\TimeSearchResults.xlsx", file);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        public void ExportSearchResultsToWord(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var downloadsFolder = KnownFolders.GetPath(KnownFolder.Downloads);
            ExportHelper.DeleteFilesFromDirectory(downloadsFolder, new[] {"TimeSearchResults.pdf", "TimeSearchResults.docx", "TimeSearchResults.xlsx"});

            SignIn(driver, "/#/accounting/time", DbData.User.Username, DbData.User.Password);
            var page = new TimeRecordingPage(driver);
            page.SearchButton.Click();

            var search = new TimeSearchPage(driver);

            search.IsPosted.Click();
            search.FromDate.GoToDate(-1);
            search.ToDate.GoToDate(1);

            search.SearchButton.ClickWithTimeout();

            search.SearchResults.ActionMenu.OpenOrClose();
            search.ExportToWord.Click();
            new CommonPopups(driver).WaitForFlashAlert();

            if (browserType != BrowserType.Chrome) return;

            var file = ExportHelper.GetDownloadedFile(driver, "TimeSearchResults.docx");
            Assert.AreEqual($"{downloadsFolder}\\TimeSearchResults.docx", file);
        }
    }
}