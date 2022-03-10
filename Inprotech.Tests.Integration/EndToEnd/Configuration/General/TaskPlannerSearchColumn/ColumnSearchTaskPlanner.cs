using Inprotech.Tests.Integration.EndToEnd.Configuration.General.CaseSearchColumn;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.TaskPlannerSearchColumn
{
    [Category(Categories.E2E)]
    [TestFixture]
    internal class ColumnSearchTaskPlanner : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void SearchListOfColumnsAvailableForInternalCaseSearch(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/search/columns?queryContextKey=970");
            var page = new ColumnSearchPageObject(driver);

            var grid = page.ResultGrid;
            Assert.AreEqual(28, grid.Rows.Count, "28 Task Planner Search Columns");
        }
    }
}