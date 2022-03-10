using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Search
{
    public class ConfigurationSearchPageObject : PageObject
    {
        public ConfigurationSearchPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public SearchOptions SearchOptions => new SearchOptions(Driver);

        public TextInput SearchField => new TextInput(Driver).ByCssSelector("[ng-model='vm.searchCriteria.text']");

        public PickList Components => new PickList(Driver).ByName("components");

        public PickList Tags => new PickList(Driver).ByName("tags");

        public ConfigurationItemsGrid ConfigurationItems => new ConfigurationItemsGrid(Driver, "searchResults");

    }

    public class ConfigurationItemsGrid : KendoGrid
    {
        public static class ColumnIndex
        {
            public const int Icon = 0;
            public const int Name = 1;
            public const int Tags = 4;
        }
        
        public ConfigurationItemsGrid(NgWebDriver driver, string name) : base(driver, name)
        {
        }
        
        public void OpenEditModal(int rowIndex)
        {
            Rows[rowIndex].FindElement(By.CssSelector("button[button-icon=pencil-square-o]")).Click();

            Driver.WaitForAngular();
        }

        public string GetTags(int rowIndex)
        {
            return CellText(rowIndex, ColumnIndex.Tags);
        }
    }

    public class ConfigurationItemMaintenanceModal : PageObject
    {
        public ConfigurationItemMaintenanceModal(NgWebDriver driver) : base(driver)
        {
        }

        public string Name => Driver.FindElement(By.Name("configuration-name")).Text;

        public string Description => Driver.FindElement(By.Name("configuration-description")).Text;

        public string Components => Driver.FindElement(By.Name("configuration-components")).Text;

        public PickList Tags => new PickList(Driver).ByName("tags");
        
        public ButtonInput Save => new ButtonInput(Driver).ByClassName("btn-save");
        
        public ButtonInput Discard => new ButtonInput(Driver).ByClassName("btn-discard");
    }
}