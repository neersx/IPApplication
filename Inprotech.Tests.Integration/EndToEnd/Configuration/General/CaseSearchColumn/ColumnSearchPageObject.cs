using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.CaseSearchColumn
{
    public class ColumnSearchPageObject : PageObject
    {
        public ColumnSearchPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement ConfigurationSearchLink => Driver.FindElement(By.XPath("//a/span[text()='Case Search Columns']"));
        public NgWebElement SearchField => Driver.FindElement(By.XPath("//input[@placeholder='Enter text to search']"));
        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector("#search-options-search-btn"));
        public NgWebElement InternalRadioButton => Driver.FindElement(By.XPath("//input[@id='forInternal-input']/following-sibling::label"));
        public NgWebElement ExternalRadioButton => Driver.FindElement(By.XPath("//input[@id='forExternal-input']/following-sibling::label"));
        public NgWebElement CaseSearchHeader => Driver.FindElement(By.XPath("//span[text()='Case Search Column Maintenance']"));
        public NgWebElement ColumnSearchButton => Driver.FindElement(By.XPath("//span[@class='cpa-icon cpa-icon-search']"));
        public AngularKendoGrid ResultGrid => new AngularKendoGrid(Driver, "searchResults");
        public NgWebElement AddSearchColumnButton => Driver.FindElement(By.XPath("//span[contains(@class,'cpa-icon cpa-icon-plus-circle')]"));
        public NgWebElement DisplayName => Driver.FindElement(By.XPath("//ipx-text-field[@name='displayName']/div/input"));
        public AngularPicklist ColumnNamePicklist => new AngularPicklist(Driver).ByName("columnName");
        public NgWebElement ColumnDescription => Driver.FindElement(By.XPath("//ipx-text-field[@name='columnDescription']/div/textarea"));
        public NgWebElement ColumnGroupPicklist => Driver.FindElement(By.XPath("//ipx-typeahead[@name='columnGroup']/div/div/input"));
        public NgWebElement DataItemPicklist => Driver.FindElement(By.XPath("//ipx-typeahead[@name='dataItem']/div/div/input"));
        public NgWebElement ParameterTextField => Driver.FindElement(By.XPath("//ipx-text-field[@name='parameter']/div/input"));
        public NgWebElement VisibleCheckbox => Driver.FindElement(By.XPath("//ipx-checkbox[@name='visible']/div/input"));
        public NgWebElement MandatoryCheckbox => Driver.FindElement(By.XPath("//ipx-checkbox[@name='mandatory']/div/input"));
        public NgWebElement InternalCheckbox => Driver.FindElement(By.XPath("//ipx-checkbox[@name='internal']/div/input"));
        public NgWebElement ExternalCheckbox => Driver.FindElement(By.XPath("//ipx-checkbox[@name='external']/div/input"));
        public NgWebElement SaveColumnButton => Driver.FindElement(By.XPath("//ipx-save-button[@name='saveSearchColumn']/button"));
        public NgWebElement CloseColumnButton => Driver.FindElement(By.XPath("//ipx-icon[@name='times']"));
        public NgWebElement BulkActionMenu => Driver.FindElement(By.Name("list-ul"));
        public NgWebElement SelectPage => Driver.FindElement(By.Id("a123_selectall"));
        public NgWebElement Delete => Driver.FindElement(By.Id("bulkaction_a123_Delete"));
        public NgWebElement PresentationLink => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-bars-vertical"));
        public NgWebElement SearchColumnInputField => Driver.FindElement(By.XPath("//ipx-text-field[@name='searchTerm']/div/input"));
        public NgWebElement EditColumnButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-pencil-square-o.undefined"));
        public NgWebElement ColumnEditModalSaveButton => Driver.FindElement(By.XPath("//ipx-save-button[@name='saveSearchColumn']/button"));
        public NgWebElement MaintainColumnButton => Driver.FindElement(By.CssSelector("#column"));
        public NgWebElement GreenBorder => Driver.FindElement(By.CssSelector(".treeview-saved"));
        public NgWebElement RefreshButton => Driver.FindElement(By.CssSelector(".cpa-icon-refresh"));
        public NgWebElement NewColumn => Driver.FindElement(By.XPath("//strong[text()='e2e column']"));
        public IpxTextField AvailableColumnInputField => new IpxTextField(Driver).ByName("searchTerm");
    }
}