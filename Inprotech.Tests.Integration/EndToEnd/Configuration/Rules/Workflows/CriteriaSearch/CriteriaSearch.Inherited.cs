using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaSearch
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CriteriaSearchInherited : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SearchByCriteriaToCheckInherited(BrowserType browserType)
        {
            CriteriaSearchDbSetup.Result dataFixture;
            using (var setup = new CriteriaSearchDbSetup())
            {
                dataFixture = setup.Setup();
            }

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-criteria").Click();

            var searchResults = new KendoGrid(driver, "searchResults");
            var searchOptions = new SearchOptions(driver);
            var pl = new PickList(driver).ByName("ip-search-by-criteria", "criteria");

            pl.Typeahead.WithJs().ScrollIntoView();

            pl.EnterAndSelect(dataFixture.InheritedCriteriaNo.ToString());
            searchOptions.SearchButton.ClickWithTimeout();
            Assert.AreEqual(1, searchResults.LockedCell(0, 1).FindElements(By.TagName("ip-inheritance-icon")).Count);
        }
    }
}