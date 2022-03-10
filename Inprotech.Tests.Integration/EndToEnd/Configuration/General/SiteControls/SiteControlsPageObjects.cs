using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.SiteControls
{
    class SiteControlsPageObjects : DetailPage
    {
        public Summary SummaryGrid;

        public SiteControlsPageObjects(NgWebDriver driver) : base(driver)
        {
            SearchOptions = new SearchOptions(driver);
            SearchByName = new RadioButtonOrCheckbox(driver, "search-options-name");
            SearchByDescription = new RadioButtonOrCheckbox(driver, "search-options-description");
            SearchByValue = new RadioButtonOrCheckbox(driver, "search-options-value");
            SearchField = new TextInput(driver).ByCssSelector("[ng-model='vm.searchCriteria.text']");
            FromRelease = new SelectElement(driver.FindElement(By.CssSelector("[ng-model='vm.searchCriteria.release']")));
            Components = new PickList(driver).ByName("components");
            Tags = new PickList(driver).ByName("tags");
            SummaryGrid = new Summary(driver);
        }

        public SearchOptions SearchOptions { get; set; }
        public RadioButtonOrCheckbox SearchByName { get; set; }
        public RadioButtonOrCheckbox SearchByDescription { get; set; }
        public RadioButtonOrCheckbox SearchByValue { get; set; }
        public TextInput SearchField { get; set; }
        public SelectElement FromRelease { get; set; }
        public PickList Components { get; set; }
        public PickList Tags { get; set; }

        public class Summary : KendoGrid
        {
            readonly NgWebDriver _driver;

            public Summary(NgWebDriver driver) : base(driver, "searchResults")
            {
                _driver = driver;
            }

            public void ExpandRow(int rowNumber)
            {
                Cell(rowNumber, 0).FindElement(By.CssSelector("a")).TryClick();
            }

            public SummaryDetail SummaryDetail(int rowNumber)
            {
                var detailRow = DetailRows[rowNumber];
                return new SummaryDetail(_driver, detailRow);
            }
        }
    }

    class SummaryDetail : PageObject
    {
        public TextInput Notes;
        public TextInput SettingValue;
        public NgWebElement Tags;

        public SummaryDetail(NgWebDriver driver, NgWebElement detailRow) : base(driver, detailRow)
        {
            SettingValue = new TextInput(driver, detailRow).ByName("value");
            Tags = detailRow.FindElement(By.CssSelector("ipt-typeahead-multi-select"));
            Notes = new TextInput(driver, detailRow).ByName("notes");
        }

        public void AddTag(string tag)
        {
            Tags.FindElement(By.TagName("input")).SendKeys(tag);
        }

        public string GetTags()
        {
            return Tags.Text;
        }

        public bool HasError()
        {
            return FindElement(By.CssSelector(".cpa-icon-exclamation-triangle")).Displayed;
        }
    }
}