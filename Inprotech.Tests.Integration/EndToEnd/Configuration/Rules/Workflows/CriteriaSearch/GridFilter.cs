using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaSearch
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class GridFilter : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void FilterSearchResults(BrowserType browserType)
        {
            using (var setup = new CriteriaSearchDbSetup())
            {
                setup.Setup();
            }

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");

            var caseTypePl = new PickList(driver).ByName("ip-search-by-characteristics", "caseType");
            caseTypePl.SelectItem(CriteriaSearchDbSetup.CaseTypeDescription);

            var searchOptions = new SearchOptions(driver);
            searchOptions.SearchButton.ClickWithTimeout();
            driver.WaitForAngular();

            var jurisdictionFilter = new MultiSelectGridFilter(driver, "searchResults", "jurisdiction");
            var actionFilter = new MultiSelectGridFilter(driver, "searchResults", "action");

            jurisdictionFilter.Open();
            Assert.AreEqual(3, jurisdictionFilter.ItemCount);

            jurisdictionFilter.Search(CriteriaSearchDbSetup.InvalidJurisdictionDescription);
            WaitHelper.Wait(); // wait for filter to complete
            Assert.AreEqual(1, jurisdictionFilter.ItemCount);
            jurisdictionFilter.Dismiss();

            // search should reset the filters
            searchOptions.SearchButton.ClickWithTimeout();

            jurisdictionFilter.Open();
            Assert.AreEqual(3, jurisdictionFilter.ItemCount);

            // filtering
            jurisdictionFilter.SelectAll();
            jurisdictionFilter.SelectOption(CriteriaSearchDbSetup.InvalidJurisdictionDescription);
            jurisdictionFilter.Filter();
            WaitHelper.WaitForGridLoadComplete(driver);
            var grid = new KendoGrid(driver, "searchResults");
            Assert.AreEqual(CriteriaSearchDbSetup.CriteriaCount - 1, grid.Rows.Count);

            // multi-filter
            actionFilter.Open();
            actionFilter.SelectOption(CriteriaSearchDbSetup.ValidActionDescription);
            actionFilter.Filter();
            Assert.AreEqual(CriteriaSearchDbSetup.CriteriaCount - 2, grid.Rows.Count);

            // reset filters
            jurisdictionFilter.Open();
            jurisdictionFilter.Clear();
            Assert.AreEqual(CriteriaSearchDbSetup.CriteriaCount - 1, grid.Rows.Count);
            actionFilter.Open();
            actionFilter.Clear();
            Assert.AreEqual(CriteriaSearchDbSetup.CriteriaCount, grid.Rows.Count);

            // filter by empty value
            jurisdictionFilter.Open();
            jurisdictionFilter.SelectOption("(empty)");
            jurisdictionFilter.Filter();
            Assert.AreEqual(1, grid.Rows.Count);
        }
    }
}