using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Queries;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseNavigation : IntegrationTest
    {
        const string XmlCriteria = "<Search><Filtering><csw_ListCase><FilterCriteriaGroup><FilterCriteria ID=\"1\"><CaseReference Operator=\"2\">123</CaseReference></FilterCriteria></FilterCriteriaGroup></csw_ListCase></Filtering></Search>";

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ViewCaseSearchResults(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/search-result?queryContext=2");

            var searchPageObject = new SearchPageObject(driver);
            var grid = searchPageObject.ResultGrid;
            var totalRecords = searchPageObject.CaseSearchTotalRecords;

            grid.Rows.First().FindElements(By.TagName("a"))?.First().ClickWithTimeout();

            var caseViewPage = new NewCaseViewDetail(driver);
            var pageNav = caseViewPage.AngularPageNav;
            var navControl = pageNav.NavControl;

            Assert.IsTrue(navControl.Displayed, "Ensure the navigation controls are displayed");
            Assert.AreEqual("1", pageNav.Current(), "Displays the first record number");
            Assert.AreEqual(totalRecords, pageNav.Total(), "Displays the number of total records");

            caseViewPage.AngularPageNav.NextPage();
            pageNav = caseViewPage.AngularPageNav;
            Assert.AreEqual("2", pageNav.Current(), "Displays the next record number");
            Assert.AreEqual(totalRecords, pageNav.Total(), "Displays the number of total records");

            caseViewPage.LevelUpButton.ClickWithTimeout();
            //Assert.True(grid.RowIsHighlighted(1), "Expected previously viewed case to be highlighted.");

            if (int.Parse(totalRecords) <= 50)
                return;

            grid.PageNext();
            grid.Rows.First().FindElements(By.TagName("a"))?.First().ClickWithTimeout();
            caseViewPage = new NewCaseViewDetail(driver);
            pageNav = caseViewPage.AngularPageNav;
            Assert.IsTrue(pageNav.NavControl.Displayed, "Ensure the navigation controls are displayed");
            Assert.AreEqual("51", pageNav.Current(), "Displays the first record number");
            Assert.AreEqual(totalRecords, pageNav.Total(), "Displays the number of total records");

            caseViewPage.AngularPageNav.NextPage();
            pageNav = caseViewPage.AngularPageNav;
            Assert.AreEqual("52", pageNav.Current(), "Displays the next record number");
            Assert.AreEqual(totalRecords, pageNav.Total(), "Displays the number of total records");

            caseViewPage.LevelUpButton.ClickWithTimeout();
            //Assert.True(grid.RowIsHighlighted(1), "Expected previously viewed case to be highlighted.");
            Assert.AreEqual("2", grid.CurrentPage(), "Expected the search results to be on next page");

            grid.Rows.First().FindElements(By.TagName("a"))?.First().ClickWithTimeout();
            caseViewPage = new NewCaseViewDetail(driver);
            pageNav = caseViewPage.AngularPageNav;
            Assert.AreEqual("51", pageNav.Current(), "Displays the first record number");
            Assert.AreEqual(totalRecords, pageNav.Total(), "Displays the number of total records");

            caseViewPage.AngularPageNav.PrePage();
            pageNav = caseViewPage.AngularPageNav;
            Assert.AreEqual("50", pageNav.Current(), "Displays the first record number");
            Assert.AreEqual(totalRecords, pageNav.Total(), "Displays the number of total records");

            caseViewPage.LevelUpButton.ClickWithTimeout();
            //Assert.True(grid.RowIsHighlighted(49), "Previously viewed case in correct page is highlighted.");
            Assert.AreEqual("1", grid.CurrentPage(), "Expected the search results to be on next page");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void NavigatingCaseSearchResultsWithSameCaseReference(BrowserType browserType)
        {

            var data = DbSetup.Do(setup =>
            {
                var filter = setup.Insert(new QueryFilter() { ProcedureName = "csw_ListCase", XmlFilterCriteria = XmlCriteria });
                var presentation = setup.Insert(new QueryPresentation() { ContextId = 2});
                var query = setup.Insert(new Query(){Name = "testSavedSearch", ContextId = 2, FilterId = filter.Id, PresentationId = presentation.Id});
                setup.Insert(new QueryContent { ColumnId = -77, ContextId = 2, DisplaySequence = 1, PresentationId = presentation.Id});
                setup.Insert(new QueryContent { ColumnId = -121, ContextId = 2, DisplaySequence = 2, PresentationId = presentation.Id});

                return new
                {
                   SavedSearch = query
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/case/search");
            var searchPage = new CaseSearchPageObject(driver);
            searchPage.CaseSearchMenuItem().WithJs().Click();
            Assert.IsTrue(searchPage.CaseSubMenu.Displayed);

            var caseHref = $"#/search-result?queryContext=2&queryKey={data.SavedSearch.Id}";
            searchPage.SavedSearchSubMenu(caseHref).WithJs().Click();

            var searchPageObject = new SearchPageObject(driver);
            var grid = searchPageObject.ResultGrid;

            var caseRef = grid.CellText(0, 0);
            Assert.AreEqual(grid.CellText(0,0),grid.CellText(1,0));
            grid.Rows.First().FindElements(By.TagName("a"))?.First().ClickWithTimeout();

            var caseViewPage = new NewCaseViewDetail(driver);
            var pageNav = caseViewPage.AngularPageNav;
            var navControl = pageNav.NavControl;

            Assert.IsTrue(navControl.Displayed, "Ensure the navigation controls are displayed");
            Assert.AreEqual("1", pageNav.Current(), "Displays the first record number");
            var a = caseViewPage.PageTitle();
            Assert.True(caseViewPage.PageTitle().EndsWith(caseRef));
            
            caseViewPage.AngularPageNav.NextPage();
            pageNav = caseViewPage.AngularPageNav;
            Assert.AreEqual("2", pageNav.Current(), "Displays the next record number");
            Assert.True(caseViewPage.PageTitle().EndsWith(caseRef));
        }
    }
}
