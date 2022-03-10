using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Search.WIPOverview
{
    public class BillSearchPageObject : PageObject
    {
        public BillSearchPageObject(NgWebDriver driver) : base(driver)
        {
        }
        public AngularKendoGrid ResultGrid => new(Driver, "searchResults");
        public AngularKendoGrid ResultCaseGrid => new(Driver, "caseGrid");
        public NgWebElement CaseRefOption => Driver.FindElement(By.XPath("//*[@id='searchResults']/kendo-grid/div/table/thead/tr/th[4]/span[1]"));
        public NgWebElement SingleBillButton => Driver.FindElement(By.Id("bulkaction_a123_create-single-bill"));
        public AngularPicklist RaisedByPickList => new AngularPicklist(Driver).ByName("raisedBy");
        public NgWebElement EntityDropDown => Driver.FindElement(By.CssSelector("ipx-dropdown[name='entity']"));
        public SelectElement EntitySelect => new(EntityDropDown.FindElement(By.TagName("select")));
        public NgWebElement EntityValueDropDown => Driver.FindElement(By.CssSelector("ipx-dropdown[name='entity']"));
        public SelectElement EntityValueSelect => new(EntityValueDropDown.FindElement(By.TagName("select")));
        public DatePicker FromDatePicker => new(Driver, "fromDate");
        public DatePicker ItemDate => new(Driver, "transactionDate");
        public DatePicker ToDatePicker => new(Driver, "toDate");
        public AngularPicklist RaisedByValuePicklist => new AngularPicklist(Driver).ByName("raisedBy");
        public AngularCheckbox IncludeNonRenewalCheckBox => new AngularCheckbox(Driver).ByName("includeNonRenewal");
        public AngularCheckbox IncludeRenewalCheckBox => new AngularCheckbox(Driver).ByName("includeRenewal");
        public AngularCheckbox UseRenewalDebtorCheckBox => new AngularCheckbox(Driver).ByName("useRenewalDebtor");
        public NgWebElement ProceedButton => Driver.FindElement(By.Name("save"));
        public NgWebElement BillingWizardTitle => Driver.FindElement(By.XPath("//ipx-page-title/div/h2/span/span"));
    }
}