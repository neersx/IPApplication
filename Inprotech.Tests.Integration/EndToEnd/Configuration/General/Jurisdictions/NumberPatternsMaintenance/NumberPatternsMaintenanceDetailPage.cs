using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.NumberPatternsMaintenance
{
    internal class NumberPatternsMaintenanceDetailPage : DetailPage
    {
        NumberPatternsTopic _numberPatternsTopic;
        public NumberPatternsMaintenanceDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public NumberPatternsTopic NumberPatternsTopic => _numberPatternsTopic ?? (_numberPatternsTopic = new NumberPatternsTopic(Driver));
    }

    public class NumberPatternsTopic : Topic
    {
        const string TopicKey = "validNumbers";

        public NumberPatternsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            Grid = new KendoGrid(Driver, "validNumbersGrid");            
        }

        public KendoGrid Grid { get; }

        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("search-options-criteria"));
        }

        public NgWebElement SearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("search-options-search-btn"));
        }

        public NgWebElement AddButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-click='vm.onAddClick()']"));
        }

        public void BulkMenu(NgWebDriver driver)
        {
            driver.FindElement(By.Name("list-ul")).Click();
        }

        public void SelectPageOnly(NgWebDriver driver)
        {
            driver.FindElement(By.Id("jurisdictionMenu_selectpage")).WithJs().Click();
        }

        public void EditButton(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_jurisdictionMenu_edit")).WithJs().Click();
        }
        public NgWebElement SaveButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("floppy-o"));
        }

        public NgWebElement ApplyButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("check"));
        }

        public NgWebElement CloseButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("times"));
        }

        public NgWebElement PatternTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("pattern")).FindElement(By.TagName("input"));
        }

        public NgWebElement ErrorMessageTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("displayMessage")).FindElement(By.TagName("textarea"));
        }

        public NgWebElement ValidFromTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("validFrom")).FindElement(By.TagName("input"));
        }

        public NgWebElement DisplayWarningOnlyCheckBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("warningFlag")).FindElement(By.TagName("input"));
        }

        public NgWebElement TestPatternButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("validate"));
        }

        public NgWebElement RegexNumberPatternTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("regexPattern")).FindElement(By.TagName("input"));
        }

        public NgWebElement EnterTestNumberPatternTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("testPatternNumber")).FindElement(By.TagName("input"));
        }

        public NgWebElement RunTestButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("runTest"));
        }

        public int GridRowsCount => Grid.Rows.Count;
    }
}
