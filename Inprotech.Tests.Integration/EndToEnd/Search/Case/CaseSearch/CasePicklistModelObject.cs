using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.CaseSearch
{
    public class CasePicklistModelObject : PageObject
    {
        public CasePicklistModelObject(NgWebDriver driver) : base(driver)
        {
        }

        public AngularKendoGrid ResultGrid => new AngularKendoGrid(Driver, "picklistResults");

        public NgWebElement InlineAlert => Driver.FindElement(By.CssSelector("#picklistResults > ipx-kendo-grid > ipx-inline-alert > div > span"));

        public NgWebElement SearchElement => Driver.FindElement(By.XPath("//*[@id='picklistResults']/ipx-kendo-grid/kendo-grid/kendo-grid-toolbar/grid-toolbar/picklist-toolbar/div[1]/div[1]/ipx-picklist-case-search-panel[1]/ipx-search-option[1]/div[1]/form[1]/div[1]/div[1]/ipx-picklist-search-field[1]/div/input"));

        public NgWebElement SearchButton => Driver.FindElement(By.XPath("//*[@id='searchBody']/div[1]/div[1]/ipx-picklist-search-field/div/span[2]/ipx-icon-button/div/button"));
        public NgWebElement ClearButton => Driver.FindElement(By.XPath("//*[@id='searchBody']/div[1]/div[1]/ipx-picklist-search-field/div/span[1]/ipx-icon-button/div/button"));

        public AngularPicklist NameTypeahead => new AngularPicklist(Driver).ByName("name");

        public AngularPicklist CaseOfficeTypeahead => new AngularPicklist(Driver).ById("caseOffice");

        public AngularPicklist CaseTypeahead => new AngularPicklist(Driver).ById("searchCaseType");

        public AngularPicklist JurisdictionTypeahead => new AngularPicklist(Driver).ById("searchJurisdiction");

        public NgWebElement SavedSearchButton => Driver.FindElement(By.XPath("//*[@id='searchBody']/div[2]/button[2]/span"));
        public NgWebElement ClearSearchButton => Driver.FindElement(By.XPath("//*[@id='searchBody']/div[2]/button[1]/span"));
        
    }
}