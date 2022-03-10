using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class SearchOptions
    {
        readonly NgWebDriver _driver;

        public SearchOptions(NgWebDriver driver)
        {
            _driver = driver;
        }

        public NgWebElement SearchButton => _driver.FindElement(By.Id("search-options-search-btn"));

        public NgWebElement ResetButton => _driver.FindElement(By.Id("search-options-clear-btn"));
    }
}