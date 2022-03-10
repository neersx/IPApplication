using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.AttributesMaintenance
{
    internal class AttributesMaintenanceDetailPage : DetailPage
    {
        AttributesTopic _attributesTopic;
        public AttributesMaintenanceDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public AttributesTopic AttributesTopic => _attributesTopic ?? (_attributesTopic = new AttributesTopic(Driver));
    }

    public class AttributesTopic : Topic
    {
        const string TopicKey = "attributes";

        public AttributesTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            ReportPriorArtCheckBox = new Checkbox(driver).ByLabel("jurisdictions.maintenance.overview.priorArt");

            Grid = new KendoGrid(Driver, "attributesList");
            AttributeTypeDropDown = new DropDown(Driver).ByName("ip-kendo-grid[data-id='attributesList']", "jurisdictionAttributeType"); 
            AttributeValueDropDown = new DropDown(Driver).ByName("ip-kendo-grid[data-id='attributesList']", "jurisdictionAttribute"); 
        }

        public Checkbox ReportPriorArtCheckBox { get; set; }

        public KendoGrid Grid { get; }

        public DropDown AttributeTypeDropDown { get; }

        public DropDown AttributeValueDropDown { get; }

        public DropDown AttributeTypeDropDownByRow(NgWebElement row)
        {
            return new DropDown(Driver, row).ByName("ip-kendo-grid[data-id='attributesList']", "jurisdictionAttributeType");
        }

        public DropDown AttributeValueDropDownByRow(NgWebElement row)
        {
            return new DropDown(Driver, row).ByName("ip-kendo-grid[data-id='attributesList']", "jurisdictionAttribute");
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

