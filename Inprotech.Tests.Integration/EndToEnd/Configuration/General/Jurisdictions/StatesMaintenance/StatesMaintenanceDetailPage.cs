using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.StatesMaintenance
{
    class StatesMaintenanceDetailPage : DetailPage
    {
        StatesTopic _statesTopic;
        public StatesMaintenanceDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public StatesTopic StatesTopic => _statesTopic ?? (_statesTopic = new StatesTopic(Driver));
    }

    public class StatesTopic : Topic
    {
        const string TopicKey = "states";

        public StatesTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            Grid = new KendoGrid(Driver, "statesGrid");
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

        public void LevelUp()
        {
            Driver.FindElement(By.CssSelector("ip-sticky-header div.page-title ip-level-up-button span")).Click();
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

        public NgWebElement StateTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("stateCode")).FindElement(By.TagName("input"));
        }

        public NgWebElement StateNameTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("stateName")).FindElement(By.TagName("input"));
        }

        public int GridRowsCount => Grid.Rows.Count;
    }

}
