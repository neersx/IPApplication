using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.DesignationStagesMaintenance
{
    class DesignationStagesMaintenanceDetailPage : DetailPage
    {
        DesignationStagesTopic _designationStagesTopic;

        public DesignationStagesMaintenanceDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DesignationStagesTopic DesignationStagesTopic => _designationStagesTopic ?? (_designationStagesTopic = new DesignationStagesTopic(Driver));

        public string DesignationStagesMaintenance()
        {
            return Driver.FindElement(By.CssSelector(".title-header h2")).Text;
        }
    }

    public class DesignationStagesTopic : Topic
    {
        const string TopicKey = "statusflags";

        public DesignationStagesTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            Grid = new KendoGrid(Driver, "statusFlagsGrid");
            //RegistrationStatusDropDown = new DropDown(Driver).ByName("ip-kendo-grid[data-id='statusFlagsGrid']", "registrationStatus");
            //CaseCreationCopyProfileDropDown = new DropDown(Driver).ByName("ip-kendo-grid[data-id='statusFlagsGrid']", "profileName");

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

        public void LevelUp()
        {
            Driver.FindElement(By.CssSelector("ip-sticky-header div.page-title ip-level-up-button span")).Click();
        }

        public NgWebElement DesignationStageTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='dataItem.name']")).FindElement(By.TagName("input"));
        }

        public NgWebElement RestrictRemovalCheckBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='dataItem.restrictRemoval']"));
        }

        public NgWebElement AllowNationalPhaseCheckBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='dataItem.allowNationalPhase']"));
        }

        public DropDown RegistrationStatusDropDown(NgWebDriver driver, NgWebElement row)
        {
            return new DropDown(Driver, row).ByName("ip-kendo-grid[id='statusFlagsGrid']", "registrationStatus");
        }

        public DropDown CaseCreationCopyProfileDropDown(NgWebDriver driver, NgWebElement row)
        {
            return new DropDown(driver, row).ByName("ip-kendo-grid[id='statusFlagsGrid']", "profileName");
        }

        public void DeleteButton(NgWebDriver driver)
        {
            driver.FindElement(By.Name("trash-o")).Click();
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
    }
}


