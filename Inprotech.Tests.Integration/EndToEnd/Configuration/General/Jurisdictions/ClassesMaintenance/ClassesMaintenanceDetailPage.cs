using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.ClassesMaintenance
{
    internal class ClassesMaintenanceDetailPage : DetailPage
    {
        ClassesTopic _classesTopic;
        public ClassesMaintenanceDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public ClassesTopic ClassesTopic => _classesTopic ?? (_classesTopic = new ClassesTopic(Driver));
    }

    public class ClassesTopic : Topic
    {
        const string TopicKey = "classes";

        public ClassesTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            Grid = new KendoGrid(Driver, "localClasses");
            ClassItemLanguagePickList = new PickList(driver).ByName(string.Empty, "language");
        }

        public KendoGrid Grid { get; }

        public PickList ClassItemLanguagePickList { get; set; }

        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("search-options-criteria"));
        }

        public NgWebElement SearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("search-options-search-btn"));
        }

        public NgWebElement ClassItemTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("ip-search-field input"));
        }

        public NgWebElement ClassItemPicklistSearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("ip-search-field span.cpa-icon.cpa-icon-search"));
        }

        public void LevelUp()
        {
            Driver.FindElement(By.CssSelector("ip-sticky-header div.page-title ip-level-up-button span")).Click();
        }

        public NgWebElement AddButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-click='vm.onAddClick()']"));
        }

        public NgWebElement AddClassItemButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[data-ng-click='vm.changeToAddView()']"));
        }

        public NgWebElement ItemClassTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("class")).FindElement(By.TagName("input"));
        }

        public NgWebElement ItemSubClassTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("subclass")).FindElement(By.TagName("input"));
        }

        public NgWebElement ItemNumberTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("itemno")).FindElement(By.TagName("input"));
        }

        public NgWebElement ItemDescriptionTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("itemdescription")).FindElement(By.TagName("textarea"));
        }

        public NgWebElement ClassItemPicklistSaveButton(NgWebDriver driver)
        {
            return driver.FindElement(By.XPath("//div[@class='modal-header-controls']//button//span[@name='floppy-o']"));
        }

        public NgWebElement ClassItemPicklistCloseButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[data-ng-click='vm.abandon()']"));
        }

        public NgWebElement EditIcon(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("pencil-square-o"));
        }

        public NgWebElement DeleteIcon(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("trash"));
        }

        public NgWebElement AddAnotherCheckBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.isAddAnother']")).FindElement(By.TagName("input"));
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

        public NgWebElement ClassTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("class")).FindElement(By.TagName("input"));
        }

        public NgWebElement SubClassTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("subclass")).FindElement(By.TagName("input"));
        }

        public NgWebElement ClassHeadingTextArea(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("classheading")).FindElement(By.TagName("textarea"));
        }

        public NgWebElement EffectiveDatePicker(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("effectivedate")).FindElement(By.TagName("input"));
        }

        public NgWebElement NotesTextArea(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("notes")).FindElement(By.TagName("textarea"));
        }

        public NgWebElement ApplyButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("check"));
        }

        public int GridRowsCount => Grid.Rows.Count;
    }

}
