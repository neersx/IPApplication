using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.CaseListMaintenance
{
    public class CaseListMaintenancePageObject : PageObject
    {
        public CaseListMaintenancePageObject(NgWebDriver driver) : base(driver)
        {
        }
        public NgWebElement ConfigurationSearchLink => Driver.FindElement(By.XPath("//a/span[text()='Case List']"));
        public NgWebElement BulkActionMenu => Driver.FindElement(By.Name("list-ul"));
        public NgWebElement Delete => Driver.FindElement(By.CssSelector("a#bulkaction_a123_delete span.text-elipses"));
        public AngularKendoGrid ResultGrid => new AngularKendoGrid(Driver, "searchResults");
        public NgWebElement ButtonAddCaseListElement => Driver.FindElement(By.XPath("//span[contains(@class,'cpa-icon cpa-icon-plus-circle')]"));
        public NgWebElement SearchField => Driver.FindElement(By.XPath("//input[@placeholder='Enter text to search']"));
        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector("button.btn.btn-icon span.cpa-icon.cpa-icon-search"));
    }
}