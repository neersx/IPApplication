using System.Linq;
using System.Security.RightsManagement;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.TaxCode
{
    class TaxCodePageObject : PageObject
    {
        public TaxCodePageObject(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            TaxRate = new TaxRateTopic(driver);
        }
        public NgWebElement AddButton => Driver.FindElement(By.CssSelector("ipx-add-button > div > button"));
        public NgWebElement TaxCode => Driver.FindElement(By.XPath("(//ipx-text-field[@name='taxCode']/div/input)"));
        public NgWebElement TaxCodeDescription => Driver.FindElement(By.XPath("(//ipx-text-field[@name='description']/div/textarea)"));
        public NgWebElement SaveTaxCodeButton => Driver.FindElement(By.XPath("//ipx-save-button[@name='saveTaxCode']/button"));
        public NgWebElement DeleteButton => Driver.FindElement(By.Id("delete"));
        public NgWebElement Delete => Driver.FindElement(By.Name("delete"));
        public NgWebElement SuccessMessage => Driver.FindElement(By.ClassName("flash_alert"));
        public NgWebElement BackButton => Driver.FindElement(By.CssSelector("ipx-level-up-button > a"));
        public NgWebElement AlertMessage => Driver.FindElement(By.CssSelector("#alertModal .modal-body p"));
        public NgWebElement AlertOkButton => Driver.FindElement(By.CssSelector("#alertModal .modal-footer button.btn"));
        public AngularKendoGrid ResultGrid => new AngularKendoGrid(Driver, "searchResults");
        public NgWebElement BulkMenuDeleteButton => Driver.FindElement(By.Id("bulkaction_a123_deleteAll"));
        public NgWebElement BulkMenuSelectAllButton => Driver.FindElement(By.Id("a123_selectall"));
        public NgWebElement SaveButton => Driver.FindElement(By.CssSelector("div.action-buttons ipx-save-button > button"));
        public DatePicker EffectiveDate => new(Driver, "effectiveDate");
        public NgWebElement TaxRateEntry => Driver.FindElement(By.XPath("//ipx-numeric[@name='rate']/div/kendo-numerictextbox/span/input"));
        public NgWebElement DeleteRow => Driver.FindElement(By.XPath("(//ipx-icon-button[@name='deleteRow']/div/button)"));
        public TaxRateTopic TaxRate { get; set; }
        public AngularKendoGrid Grid => new AngularKendoGrid(Driver, "taxRateResults");
        public void SelectPickListItem(int gridRowIndex, string pickListName, string searchText)
        {
            var picklist = new AngularPicklist(Driver, Grid.EditableRow(gridRowIndex)).ByName(pickListName);
            picklist.Clear();
            picklist.Typeahead.Clear();
            picklist.Typeahead.SendKeys(searchText);
            picklist.Blur();
        }
    }
    class TaxRateTopic : Topic
    {
        public TaxRateTopic(NgWebDriver driver) : base(driver, "Rates")
        {
        }
        public AngularKendoGrid TaxRateGrid => new AngularKendoGrid(Driver, "taxRateResults");
    }
}