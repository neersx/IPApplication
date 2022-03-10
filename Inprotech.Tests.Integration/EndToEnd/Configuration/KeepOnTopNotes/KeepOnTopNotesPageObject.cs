using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.KeepOnTopNotes
{
    class KeepOnTopNotesPageObject : PageObject
    {
        public KeepOnTopNotesPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement FilterByCase(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("byCase")).FindElement(By.TagName("input"));
        }

        public NgWebElement FilterByName(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("byName")).FindElement(By.TagName("input"));
        }

        public AngularKendoGrid KotGrid => new AngularKendoGrid(Driver, "keepOnTopNotes");

        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.searchCriteria.text']"));
        }
        public NgWebElement SearchButton => Driver.FindElement(By.XPath("//span[@class='cpa-icon cpa-icon-search']"));

        public NgWebElement KotNavigationLink => Driver.FindElement(By.XPath("//tbody/tr[1]/td[2]/a[1]"));
        public NgWebElement ButtonAddKotTextType => Driver.FindElement(By.XPath("//span[contains(@class,'cpa-icon cpa-icon-plus-circle')]"));
        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));
        public NgWebElement ModalSave => Driver.FindElement(By.CssSelector(".modal-dialog .btn-save"));
        public NgWebElement ModalCancel => Driver.FindElement(By.CssSelector(".modal-dialog .btn-discard"));
        public AngularPicklist TextTypePicklist => new AngularPicklist(Driver).ByName("textType");
        public AngularPicklist CaseTypePicklist => new AngularPicklist(Driver).ByName("caseType");
        public AngularPicklist NameTypePicklist => new AngularPicklist(Driver).ByName("nameType");
        public AngularPicklist RolesPicklist => new AngularPicklist(Driver).ByName("roles");
        public AngularCheckbox HasProgramCheckbox => new AngularCheckbox(Driver).ByName("hasCaseProgram");
        public AngularCheckbox PendingCheckbox => new AngularCheckbox(Driver).ByName("pending");
        public DiscardChangesModal DiscardChangesModal => new DiscardChangesModal(Driver);
        public AngularPicklist ModuleSearchPicklist => new AngularPicklist(Driver).ByName("modules");
        public AngularPicklist StatusSearchPicklist => new AngularPicklist(Driver).ByName("status");
        public NgWebElement ClearSearchButton => Driver.FindElement(By.XPath("//span[@class='cpa-icon cpa-icon-eraser']"));
    }
}
