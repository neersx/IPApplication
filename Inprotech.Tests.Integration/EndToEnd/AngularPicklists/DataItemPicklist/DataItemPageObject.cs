using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.AngularPicklists.DataItemPicklist
{
    public class DataItemPageObject : PageObject
    {
        public DataItemPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement ConfigurationSearchLink => Driver.FindElement(By.XPath("//a/span[text()='Case Search Columns']"));
        public NgWebElement SearchField => Driver.FindElement(By.XPath("//input[@placeholder='Enter text to search']"));
        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector("#search-options-search-btn"));
        public NgWebElement AddSearchColumnButton => Driver.FindElement(By.XPath("//span[contains(@class,'cpa-icon cpa-icon-plus-circle')]"));
        public NgWebElement DisplayName => Driver.FindElement(By.XPath("//ipx-text-field[@name='displayName']/div/input"));
        public NgWebElement AddButton => Driver.FindElement(By.CssSelector(".cpa.cpa-icon-plus-circle"));
        public AngularPicklist ColumnNamePicklist => new AngularPicklist(Driver).ByName("columnName");
        public NgWebElement NameInputField => Driver.FindElement(By.XPath("(//label[contains(text(),'Name')]/following-sibling::input)[2]"));
        public NgWebElement DescriptionInputField => Driver.FindElement(By.XPath("(//label[contains(text(),'Description')]/following-sibling::textarea)[2]"));
        public NgWebElement SqlStatementRadioButton => Driver.FindElement(By.CssSelector("#rdbSqlStatement"));
        public NgWebElement TestSqlButton => Driver.FindElement(By.XPath("//span[text()='Test SQL']"));
        public NgWebElement PopUpText => Driver.FindElement(By.XPath("//span[text()='Tested Successfully.']"));
        public NgWebElement SaveButton => Driver.FindElement(By.CssSelector("ipx-save-button[name='saveButton'] button"));
        public NgWebElement SearchInputField => Driver.FindElement(By.XPath("(//input[@placeholder='Enter text to search'])[2]"));
        public NgWebElement SearchItemButton => Driver.FindElement(By.XPath("(//span[@class='cpa-icon cpa-icon-search undefined'])[2]"));
        public NgWebElement EditButtonCreatedColumn => Driver.FindElement(By.XPath("//td[contains(text(),'e2e test')]/following-sibling::td//span[@class='cpa-icon cpa-icon-pencil-square-o undefined']"));
        public NgWebElement DeleteButtonCreatedColumn => Driver.FindElement(By.XPath("//td[contains(text(),'e2e update')]/following-sibling::td//span[@class='cpa-icon cpa-icon-trash undefined']"));
        public NgWebElement DeleteButton => Driver.FindElement(By.XPath("//button[text()='Delete']"));
        public NgWebElement NoResultsFoundText => Driver.FindElement(By.XPath("//span[text()='No results found.']"));
        public NgWebElement CloseButton => Driver.FindElements(By.Name("times")).Last();
        public NgWebElement ClearButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-eraser.undefined"));

        public void SendSQL(NgWebDriver driver, string val)
        {
            WithJsExt.WithJs(driver).ExecuteJavaScript<string>($"document.querySelector('.CodeMirror').CodeMirror.setValue(\"{val}\")");
        }
    }
}