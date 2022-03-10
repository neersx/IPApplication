using System.Drawing;
using System.Linq;
using System.Threading;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Queries;
using NUnit.Framework;
using OpenQA.Selenium;
using Image = InprotechKaizen.Model.Cases.Image;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SearchResult : IntegrationTest
    {
        TestUser _loginUser;

        [SetUp]
        public void CreateAdminUser()
        {
            _loginUser = new Users()
                         .WithPermission(ApplicationTask.AdvancedCaseSearch)
                         .Create();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void DisplayImageInSearchResult(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var casePrefix = Fixture.AlphaNumericString(3);
                var case1 = new CaseBuilder(setup.DbContext).Create(casePrefix + "1");

                var imageType = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.ImageTypeForCaseHeader).IntegerValue;
                var png1 = Fixture.Image(50, 50, Color.Red);
                var image1 = setup.InsertWithNewId(new Image { ImageData = png1 });
                setup.Insert(new CaseImage(case1, image1.Id, 0, imageType.GetValueOrDefault(1201)));

                setup.Insert(new QueryContent { ColumnId = -18, ContextId = 2, DisplaySequence = 0, PresentationId = -2 });

                return new
                {
                    CasePrefix = casePrefix,
                    CaseIrns = new[] { case1.Irn }
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/search-result?queryContext=2&q={data.CasePrefix}");

            var searchPageObject = new SearchPageObject(driver);

            var grid = searchPageObject.ResultGrid;
            var caseImage1 = grid.Cell(0, 2).FindElement(By.CssSelector("img.case-image-thumbnail"));
            Assert.IsTrue(caseImage1.Displayed, "Thumbnail shows for case1");

            driver.Hover(caseImage1);

            //var imageTooltip = driver.FindElement(By.XPath("//div[@role='tooltip']//ipx-case-image//img"));
            //Assert.IsTrue(imageTooltip.Displayed, "Expanded image displays on hover");

            searchPageObject.TogglePreviewSwitch.Click();
            grid.ClickRow(0);

            Thread.Sleep(1000);

            var previewImage = driver.FindElement(By.CssSelector("article img.case-image-thumbnail"));
            Assert.IsTrue(previewImage.Displayed, "Preview image displayed");
            driver.Hover(previewImage);

            Thread.Sleep(1000);
            //var previewTooltip = driver.FindElements(By.XPath("//div[@role='tooltip']//ipx-case-image//img")).Last();

            //Assert.IsTrue(previewTooltip.Displayed, "Case Preview Tooltip is displayed");
        }

        static dynamic GetCasesData()
        {
            var data = DbSetup.Do(setup =>
            {
                var casePrefix = Fixture.AlphaNumericString(3);
                var case1 = new CaseBuilder(setup.DbContext).Create(casePrefix + "1");
                var case2 = new CaseBuilder(setup.DbContext).Create(casePrefix + "2");
                return new
                {
                    CasePrefix = casePrefix,
                    CaseIrns = new[] { case1.Irn, case2.Irn }
                };
            });
            return data;
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void DoNotDisplayBulkMenuWhenProfileNotExist(BrowserType browserType)
        {
            var data = GetCasesData();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/search-result?queryContext=2&q={data.CasePrefix}", _loginUser.Username, _loginUser.Password);
            var grid = new AngularKendoGrid(driver, "searchResults", "a123");
            grid.ActionMenu.OpenOrClose();
            Assert.Null(grid.ActionMenu.Option("open-with-program"));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ExportCaseSearchLargeData(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var setting = x.DbContext.Set<SettingValues>().Single(_ => _.SettingId == 34);
                setting.IntegerValue = 1;
                x.DbContext.SaveChanges();
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search");

            var searchPage = new CaseSearchPageObject(driver);
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");
            searchPage.CaseSearchButton.ClickWithTimeout();
            var grid = new AngularKendoGrid(driver, "searchResults", "a123");
            grid.ActionMenu.OpenOrClose();
            searchPage.ExportToPdf.Click();
            new CommonPopups(driver).WaitForFlashAlert();
            var notificationCount = searchPage.NotificationButton.Count == 0 ? 0 : searchPage.NotificationTextCount;
            searchPage.NotificationCount(notificationCount);
            searchPage.NotificationButton.First().Click();
            Assert.AreEqual("CaseList.pdf", searchPage.ExportToPdfMessage.Text);

            DbSetup.Do(x =>
            {
                var setting = x.DbContext.Set<SettingValues>().Single(_ => _.SettingId == 34);
                setting.IntegerValue = 15;
                x.DbContext.SaveChanges();
            });
        }

        [TestCase(BrowserType.Chrome)]
        public void ExportCaseSearchSingleData(BrowserType browserType)
        {
            var data = GetCasesData();
            var downloadsFolder = KnownFolders.GetPath(KnownFolder.Downloads);

            ExportHelper.DeleteFilesFromDirectory(downloadsFolder, new[] { "CaseList.pdf" });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/search-result?queryContext=2&q={data.CasePrefix}");

            var searchPage = new CaseSearchPageObject(driver);
            var grid = new AngularKendoGrid(driver, "searchResults", "a123");
            grid.ActionMenu.OpenOrClose();
            searchPage.ExportToPdf.Click();
            new CommonPopups(driver).WaitForFlashAlert();
            var pdf = ExportHelper.GetDownloadedFile(driver, "CaseList.pdf");
            Assert.AreEqual($"{downloadsFolder}\\CaseList.pdf", pdf);

        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void VerifyRefreshButtonFunctionalityOnCaseSearchPage(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search");
            InprotechKaizen.Model.Cases.Case case1 = null, case2 = null, case3 = null;

            DbSetup.Do(x =>
            {
                var au = x.DbContext.Set<Country>().Single(_ => _.Id == "AU");
                var af = x.DbContext.Set<Country>().Single(_ => _.Id == "AF");
                var ar = x.DbContext.Set<Country>().Single(_ => _.Id == "AR");
                case1 = new CaseBuilder(x.DbContext).Create("e2e1", true, country: au);
                case2 = new CaseBuilder(x.DbContext).Create("e2e2", true, country: af);
                case3 = new CaseBuilder(x.DbContext).Create("e2e3", true, country: ar);
            });
            var page = new SearchPageObject(driver);
            var grid = page.ResultGrid;
            page.QuickSearchInput().SendKeys("e2e");
            page.QuickSearchInput().SendKeys(Keys.Enter);
            Assert.AreEqual(3, grid.Rows.Count);
            page.CountryFilter.Click();
            page.CountryLabel.ClickWithTimeout();
            page.FilterButton.ClickWithTimeout();
            Assert.AreEqual(1, grid.Rows.Count);
            page.RefreshButton.ClickWithTimeout();
            Assert.AreEqual(3, grid.Rows.Count);
        }

    }
}
