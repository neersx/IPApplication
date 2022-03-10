using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Queries;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.CaseSearchColumn
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SearchListOfColumnsAvailable : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _columnSearchDbSetup = new ColumnSearchCaseDbSetup();
            _scenario = _columnSearchDbSetup.Prepare();
        }

        ColumnSearchCaseDbSetup _columnSearchDbSetup;
        ColumnSearchCaseDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void SearchListOfColumnsAvailableForInternalCaseSearch(BrowserType browserType)
        {
            DbSetup.Do(x =>
            {
                var userColumnQueryDataItem = x.DbContext.Set<QueryDataItem>().Single(_ => _.ProcedureItemId == "Text" && _.ProcedureName == "csw_ListCase");
                var e2EColumn1 = new QueryColumn {DataItemId = userColumnQueryDataItem.DataItemId, ColumnLabel = "e2e column 1", Description = "e2e description 1"};
                var e2EColumn2 = new QueryColumn {DataItemId = userColumnQueryDataItem.DataItemId, ColumnLabel = "e2e column 2", Description = "e2e description 2"};
                x.Insert(e2EColumn1);
                x.Insert(e2EColumn2);

                var queryContextDisplayUrl = new QueryContextColumn {ColumnId = e2EColumn1.ColumnId, ContextId = (int) QueryContext.CaseSearch};
                var queryContextDisplayName = new QueryContextColumn {ColumnId = e2EColumn2.ColumnId, ContextId = (int) QueryContext.CaseSearch};
                x.Insert(queryContextDisplayUrl);
                x.Insert(queryContextDisplayName);
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/search");
            var page = new ColumnSearchPageObject(driver);
            page.SearchField.SendKeys("Case Search Columns");
            page.SearchButton.ClickWithTimeout();
            page.ConfigurationSearchLink.ClickWithTimeout();
            Assert.IsTrue(page.InternalRadioButton.Displayed);
            Assert.IsTrue(page.ExternalRadioButton.Displayed);
            Assert.IsTrue(page.CaseSearchHeader.Displayed);
            page.SearchField.SendKeys("e2e");
            page.ColumnSearchButton.Click();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            var grid = page.ResultGrid;
            Assert.AreEqual(2, grid.Rows.Count, "2 record is returned by search");
        }
    }
}