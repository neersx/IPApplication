using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail
{
    public static class CriteriaHelper
    {
        public static void GoToMaintenancePage(NgWebDriver driver, int criteriaId, int childCriteria)
        {
            var radio = driver.FindElement(By.CssSelector("label[for='search-by-criteria']"));
            radio.WithJs().Click();

            var searchOptions = new SearchOptions(driver);
            var searchResults = new KendoGrid(driver, "searchResults");
            var criteriaPl = new PickList(driver).ByName("ip-search-by-criteria", "criteria");
            criteriaPl.SendKeys(criteriaId.ToString()).Blur();
            criteriaPl.SendKeys(childCriteria.ToString()).Blur();
            searchOptions.SearchButton.ClickWithTimeout();

            searchResults.LockedCell(0, 3).FindElement(By.TagName("a")).ClickWithTimeout();
        }
    }
}