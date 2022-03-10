using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.RecordalTypes
{
    public class RecordalTypesPageObject : PageObject
    {
        public RecordalTypesPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public AngularKendoGrid RecordalTypeGrid => new AngularKendoGrid(Driver, "recordalTypeGrid");
        public AngularKendoGrid RecordalElementsGrid => new AngularKendoGrid(Driver, "recordalElementsGrid");
        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.searchCriteria.text']"));
        }

        public NgWebElement RecordalTypeNavigationLink => Driver.FindElement(By.XPath("//tbody/tr[1]/td[2]/a[1]"));

        public NgWebElement SearchTextBoxInRecordalType(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("recordalType")).FindElement(By.TagName("input"));
        }

        public NgWebElement SearchButton => Driver.FindElement(By.XPath("//span[@class='cpa-icon cpa-icon-search']"));
        public NgWebElement ApplyButton => Driver.FindElement(By.XPath("/html/body/modal-container[2]/div/div/ipx-recordal-element/div[1]/div/ipx-apply-button"));
        public NgWebElement ClearSearchButton => Driver.FindElement(By.XPath("//span[@class='cpa-icon cpa-icon-eraser']"));
        public NgWebElement ButtonAddElement => Driver.FindElement(By.XPath("//*[@id=\"recordalElementsGrid\"]/kendo-grid/kendo-grid-toolbar/ipx-add-button"));

        public NgWebElement Modal => Driver.Wait().ForVisible(By.CssSelector(".modal-dialog"));   
        public NgWebElement AlertModal => Driver.Wait().ForVisible(By.CssSelector(".modal-alert"));
        public NgWebElement AlertModalHeader => Driver.Wait().ForVisible(By.CssSelector(".modal-title"));
        public NgWebElement AlertModalButtonOk => Driver.Wait().ForVisible(By.Name("cancel"));
        public NgWebElement CancelButton => Driver.FindElement(By.CssSelector(".modal-dialog .btn-discard"));
        public NgWebElement SaveButton => Driver.FindElements(By.CssSelector(".btn-save")).Last();
        public AngularTextField RecordalType => new AngularTextField(Driver, "recordalType");
        public AngularTextField TextRecordalType => new AngularTextField(Driver, "recordalTypeTxt");
        public AngularPicklist RequestEvent => new AngularPicklist(Driver).ByName("requestEvent");
        public AngularDropdown Element => new AngularDropdown(Driver).ByName("element");
        public AngularDropdown Attribute => new AngularDropdown(Driver).ByName("attribute");
        public AngularTextField ElementLabel => new AngularTextField(Driver, "elementLabel");
        public AngularPicklist NameType => new AngularPicklist(Driver).ByName("nameType");
    }
}
