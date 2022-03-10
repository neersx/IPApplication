using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.AngularPicklists.ColumnGroupPicklist
{
    public class ColumnGroupPageObject : PageObject
    {
        public ColumnGroupPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement ConfigurationSearchLink => Driver.FindElement(By.XPath("//a/span[text()='Case Search Columns']"));
        public NgWebElement SearchField => Driver.FindElement(By.XPath("//input[@placeholder='Enter text to search']"));
        public NgWebElement AddSearchColumnButton => Driver.FindElement(By.XPath("//span[contains(@class,'cpa-icon cpa-icon-plus-circle')]"));
        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector("#search-options-search-btn"));
        public NgWebElement AddButton => Driver.FindElement(By.CssSelector(".cpa.cpa-icon-plus-circle"));
        public NgWebElement DescriptionInputField => Driver.FindElement(By.XPath("(//label[contains(text(),'Description')]/following-sibling::textarea)[2]"));
        public NgWebElement SaveButton => Driver.FindElement(By.CssSelector("ipx-save-button[name='saveButton'] button"));
        public NgWebElement ItemInputField => Driver.FindElement(By.XPath("(//input[@placeholder='Enter text to search'])[2]"));
        public NgWebElement ItemSearchButton => Driver.FindElement(By.XPath("(//span[@class='cpa-icon cpa-icon-search undefined'])[2]"));
        public NgWebElement EditButtonCreatedColumn => Driver.FindElement(By.XPath("//td[contains(text(),'TESTING1234')]/following-sibling::td//span[@class='cpa-icon cpa-icon-pencil-square-o undefined']"));
        public NgWebElement DeleteButtonCreatedColumn => Driver.FindElement(By.XPath("//td[contains(text(),'TESTING1235')]/following-sibling::td//span[@class='cpa-icon cpa-icon-trash undefined']"));
        public NgWebElement DeleteButton => Driver.FindElement(By.XPath("//button[text()='Delete']"));
        public NgWebElement NoResultsFoundText => Driver.FindElement(By.XPath("//span[text()='No results found.']"));
        public NgWebElement CloseButton => Driver.FindElements(By.Name("times")).Last();
        public NgWebElement ClearButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-eraser.undefined"));
    }
}