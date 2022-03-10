using Inprotech.Tests.Integration.EndToEnd.Portal;
using Inprotech.Tests.Integration.EndToEnd.Search;
using Inprotech.Tests.Integration.EndToEnd.Search.Case;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using NUnit.Framework;
using OpenQA.Selenium;
using System.Linq;
using System.Threading;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseViewNavigation : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void NavigateThroughCaseSearchResults(BrowserType browserType)
        {
            new CaseDetailsDbSetup().NavigationDataSetup();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#");
            var searchPage = new CaseSearchPageObject(driver);
            searchPage.CaseSearchMenuItem().WithJs().Click();
            Assert.IsTrue(searchPage.CaseSubMenu.Displayed);
            searchPage.CaseSearchBuilder().WithJs().Click();

            searchPage.References.NavigateTo();
            searchPage.References.CaseReference.SendKeys("e2e");
            searchPage.CaseSearchButton.Click();

            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;

            grid.Cell(1, 2).FindElements(By.TagName("a"))?.First().ClickWithTimeout();
            driver.WaitForAngularWithTimeout();

            var caseViewPage = new NewCaseViewDetail(driver);
            var summary = new SummaryTopic(driver);
            var irn = summary.FieldValue("irn");

            Assert.AreEqual("e2e2irn", irn, "Expected correct case to be displayed");
            //Assert.True(driver.Title.StartsWith(irn));

            caseViewPage.AngularPageNav.LastPage();
            irn = summary.FieldValue("irn");
            Assert.AreEqual("e2e3irn", irn, "Expected last case to be displayed");

            caseViewPage.LevelUpButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            Assert.True(grid.RowIsHighlighted(2), "Expected previously viewed case to be highlighted");

            searchResultPageObject.TogglePreviewSwitch.Click();
            Thread.Sleep(1000);

            var casePreview = new CasePreviewPageObject(driver);
            var header = casePreview.Header;
            Assert.IsTrue(header.Contains("e2e3irn"), "Expected highlighted row to display in Preview pane");

            grid.Cell(2, 2).FindElements(By.TagName("a"))?.First().ClickWithTimeout();

            caseViewPage.AngularPageNav.FirstPage();
            irn = summary.FieldValue("irn");
            Assert.AreEqual("e2e1irn", irn, "Expected first case to be displayed");

            caseViewPage.AngularPageNav.NextPage();
            irn = summary.FieldValue("irn");
            Assert.AreEqual("e2e2irn", irn, "Expected next (second) case to be displayed");

            caseViewPage.AngularPageNav.NextPage();
            irn = summary.FieldValue("irn");
            Assert.AreEqual("e2e3irn", irn, "Expected last case to be displayed");

            caseViewPage.AngularPageNav.PrePage();
            irn = summary.FieldValue("irn");
            Assert.AreEqual("e2e2irn", irn, "Expected previous (second) case to be displayed");

            caseViewPage.AngularPageNav.PrePage();
            irn = summary.FieldValue("irn");
            Assert.AreEqual("e2e1irn", irn, "Expected previous (first) case to be displayed");
        }
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyNextPrevWithMultiplePages(BrowserType browserType)
        {
            new CaseDetailsDbSetup().NavigationDataSetup();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/search-result?queryContext=2");
            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            grid.ChangePageSize(0);
            driver.WaitForGridLoader();
            grid.Cell(9, 2).FindElements(By.TagName("a"))?.First().ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            var caseViewPage = new NewCaseViewDetail(driver);
            Assert.AreEqual("10", caseViewPage.AngularPageNav.Current().Trim());
            var summary = new SummaryTopic(driver);
            var irnLastCaseOfFirstPage = summary.FieldValue("irn");
            caseViewPage.AngularPageNav.NextPage();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("11", caseViewPage.AngularPageNav.Current().Trim());
            caseViewPage.AngularPageNav.PrePage();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(irnLastCaseOfFirstPage, summary.FieldValue("irn"));
            Assert.AreEqual("10", caseViewPage.AngularPageNav.Current().Trim());
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void NavigateThroughRecentCases(BrowserType browserType)
        {
            var data = new CaseDetailsDbSetup().NavigationDataSetup();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");

            var portalPage = new PortalPage(driver);
            Assert.IsTrue(portalPage.RecentCasesWidget.Grid.Rows.Count > 0, "Recent Cases widget must be there and it must list some cases");

            driver.Visit($"{Env.RootUrl}/#/caseview/{data.Case1.Id}");
            driver.Visit($"{Env.RootUrl}/#/caseview/{data.Case2.Id}");
            driver.Visit($"{Env.RootUrl}/#/portal2");
            portalPage = new PortalPage(driver);

            var firstRow = portalPage.RecentCasesWidget.Grid.Rows[0];
            var lastRow = portalPage.RecentCasesWidget.Grid.Rows.Last();
            var lastIndex = portalPage.RecentCasesWidget.Grid.Rows.Count;

            Assert.IsTrue(firstRow.FindElements(By.TagName("a")).Any(), "There must be a link in the row");

            var firstCaseIrn = firstRow.FindElements(By.TagName("a")).First().Text;
            var lastCaseIrn = lastRow.FindElements(By.TagName("a")).First().Text;

            firstRow.FindElements(By.TagName("a")).First().ClickWithTimeout();
            driver.WaitForAngularWithTimeout();

            var caseViewPage = new NewCaseViewDetail(driver);
            var summary = new SummaryTopic(driver);
            var irn = summary.FieldValue("irn");

            Assert.AreEqual(firstCaseIrn, irn, "Expected correct case to be displayed");

            caseViewPage.AngularPageNav.LastPage();
            irn = summary.FieldValue("irn");
            Assert.AreEqual(lastCaseIrn, irn, "Expected last case to be displayed");

            caseViewPage.LevelUpButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();

            firstRow = portalPage.RecentCasesWidget.Grid.Rows[0];
            var secondRow = portalPage.RecentCasesWidget.Grid.Rows[1];
            firstCaseIrn = firstRow.FindElements(By.TagName("a")).First().Text;
            var secondCaseIrn = secondRow.FindElements(By.TagName("a")).First().Text;

            Assert.True(portalPage.RecentCasesWidget.Grid.RowIsHighlighted(lastIndex - 1), "Expected previously viewed case to be highlighted");
            firstRow = portalPage.RecentCasesWidget.Grid.Rows[0];
            firstRow.FindElements(By.TagName("a")).First().ClickWithTimeout();
            driver.WaitForAngularWithTimeout();

            caseViewPage.AngularPageNav.NextPage();
            irn = summary.FieldValue("irn");
            Assert.AreEqual(secondCaseIrn, irn, "Expected next case to be displayed");

            caseViewPage.AngularPageNav.FirstPage();
            irn = summary.FieldValue("irn");
            Assert.AreEqual(firstCaseIrn, irn, "Expected previous case to be displayed");

            var @case = (Case)data.Case1;
            driver.Visit(Env.RootUrl + $"/#/caseview/{@case.Id}", false, true);
            driver.WaitForAngularWithTimeout();
            driver.Visit(Env.RootUrl + "/#/portal2", false, true);
            driver.WaitForAngularWithTimeout();

            Assert.IsTrue(portalPage.RecentCasesWidget.Grid.ColumnValues(0, 20).Contains(@case.Irn), "Recently visited case should be in the list");
        }
    }
}