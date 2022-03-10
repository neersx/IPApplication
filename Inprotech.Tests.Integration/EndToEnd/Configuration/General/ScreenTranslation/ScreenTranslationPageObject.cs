using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ScreenTranslation
{
    public class ScreenTranslationPageObject : DetailPage
    {
        public ScreenTranslationPageObject(NgWebDriver driver) : base(driver)
        {
            SearchGrid = new Grid(Driver);
        }

        public SelectElement LanguageAndCultureDropdown => new SelectElement(Driver.FindElement(By.TagName("select")));

        public NgWebElement TextContainingInput => Driver.FindElement(By.CssSelector(".search-options input"));

        public SearchOptions SearchOptions => new SearchOptions(Driver);

        public Checkbox UntranslatedCheckbox => new Checkbox(Driver).ByModel("vm.searchCriteria.isRequiredTranslationsOnly");

        public NgWebElement ModalDiscard => Modal.FindElement(By.CssSelector(".btn-discard"));

        public Grid SearchGrid { get; set; }

        public class Grid : KendoGrid
        {
            readonly NgWebDriver _driver;

            public Grid(NgWebDriver driver) : base(driver, "searchResults")
            {
                _driver = driver;
            }

            public NgWebElement TranslationField(int rowNumber)
            {
                return Cell(rowNumber, 3).FindElement(By.TagName("textarea"));
            }
        }
    }
}
