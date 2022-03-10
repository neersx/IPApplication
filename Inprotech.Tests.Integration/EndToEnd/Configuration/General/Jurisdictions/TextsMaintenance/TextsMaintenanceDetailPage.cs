using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.TextsMaintenance
{
    internal class TextsMaintenanceDetailPage : DetailPage
    {
        TextsTopic _textsTopic;
        public TextsMaintenanceDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public TextsTopic TextsTopic => _textsTopic ?? (_textsTopic = new TextsTopic(Driver));
    }

    public class TextsTopic : Topic
    {
        const string TopicKey = "texts";

        public TextsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            Grid = new KendoGrid(Driver, "textsGrid");
            TextTypePickList = new PickList(Driver).ByName("ip-kendo-grid[data-id='textsGrid']", "textType");
            PropertyTypePickList = new PickList(Driver).ByName("ip-kendo-grid[data-id='textsGrid']", "propertyType");
        }

        public KendoGrid Grid { get; }
        public PickList TextTypePickList { get; }
        public PickList PropertyTypePickList { get; }

        public PickList TextTypePickListByRow(NgWebElement row)
        {
            return new PickList(Driver, row).ByName("ip-kendo-grid[data-id='textsGrid']", "textType");
        }

        public PickList PropertyTypePickListByRow(NgWebElement row)
        {
            return new PickList(Driver, row).ByName("ip-kendo-grid[data-id='textsGrid']", "propertyType");
        }

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

        public int GridRowsCount => Grid.Rows.Count;
    }
}
