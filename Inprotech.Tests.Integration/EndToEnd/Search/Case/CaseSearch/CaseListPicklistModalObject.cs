using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.CaseSearch
{
    public class CaseListPicklistModalObject : PageObject
    {
        public CaseListPicklistModalObject(NgWebDriver driver) : base(driver)
        {
        }

        public AngularKendoGrid ResultGrid => new AngularKendoGrid(Driver, "picklistResults");
        public NgWebElement ModalTitle => Driver.FindElement(By.CssSelector("div.modal-header h2.modal-title"));
        public NgWebElement ButtonAddCaseList => Driver.FindElement(By.CssSelector("button.btn.plus-circle span.cpa-icon-plus-circle"));
        public AngularPicklist CaseList => new AngularPicklist(Driver).ByName("case");
        
        public NgWebElement SearchField => Driver.FindElement(By.CssSelector("ipx-picklist-search-field .input-wrap input[type=text]"));

        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector("ipx-icon-button[buttonicon=search]"));

        public NgWebElement DeleteButton => Driver.FindElement(By.XPath("//button[text()='Delete']"));
        public NgWebElement MessageDiv => Driver.FindElement(By.ClassName("flash_alert"));
        public NgWebElement CloseButton => Driver.FindElements(By.Name("times")).Last();
    }
    
    public class ManageCaseListModalObject : PageObject
    {
        public ManageCaseListModalObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement ModalTitle => Driver.FindElement(By.CssSelector("div.modal-header h2.modal-title"));
        public NgWebElement TextCaseListName => Driver.FindElement(By.CssSelector("ipx-text-field[name='caseListName'] input"));
        public NgWebElement TextDescription => Driver.FindElement(By.CssSelector("ipx-text-field[name='description'] input"));
        public AngularPicklist PrimeCase => new AngularPicklist(Driver).ByName("primeCase");
        public NgWebElement ButtonSaveCaseList => Driver.FindElement(By.CssSelector("ipx-save-button[name='saveButton'] button.btn-save"));
        public NgWebElement CheckboxAddAnother => Driver.FindElement(By.CssSelector("ipx-checkbox[name='addAnother'] input[type='checkbox']"));
        public NgWebElement ButtonClose => Driver.FindElement(By.CssSelector("ipx-close-button button"));
        public NgWebElement AddCaseButton => Driver.FindElement(By.CssSelector(".cpa.cpa-icon-plus-circle"));
        public AngularKendoGrid CaseListGrid => new AngularKendoGrid(Driver, "grdCaseList");
        public NgWebElement CloseButton => Driver.FindElements(By.Name("times")).Last();
        
    }

    public class CasesModalObject : PageObject
    {
        public CasesModalObject(NgWebDriver driver) : base(driver)
        {
        }

        public AngularKendoGrid ResultGrid => new AngularKendoGrid(Driver, "picklistResults");
      
        public NgWebElement ApplyButton => Driver.FindElement(By.Name("check"));
   
        public NgWebElement SearchField => Driver.FindElement(By.CssSelector("ipx-picklist-search-field .input-wrap input[type=text]"));

        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector("ipx-icon-button[buttonicon=search]"));
    }
}
