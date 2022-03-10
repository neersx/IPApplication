using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;

namespace Inprotech.Tests.Integration.EndToEnd.AngularPicklists.DataItemPicklist
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class DataItemPicklist : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AddEditDeleteForDataItemPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/search");
            var page = new DataItemPageObject(driver);
            Actions action = new Actions(driver);
            page.SearchField.SendKeys("Case Search Columns");
            page.SearchButton.ClickWithTimeout();
            page.ConfigurationSearchLink.ClickWithTimeout();
            page.AddSearchColumnButton.WithJs().Click();

            driver.WaitForAngular();
            page.DisplayName.SendKeys("test");
            page.ColumnNamePicklist.SendKeys("UserColumnBoolean");
            page.ColumnNamePicklist.SendKeys(Keys.ArrowDown);
            page.ColumnNamePicklist.SendKeys(Keys.ArrowDown);
            page.ColumnNamePicklist.SendKeys(Keys.Tab);

            var dataItemPicklist = new AngularPicklist(driver).ByName("dataItem");
            dataItemPicklist.SearchButton.TryClick();
            action.SendKeys(OpenQA.Selenium.Keys.Enter).Build().Perform();
            Assert.IsTrue(page.AddButton.Displayed);
            page.AddButton.Click();
            page.NameInputField.SendKeys("e2e test");
            page.DescriptionInputField.SendKeys("description1234");
            page.SendSQL(driver, "select * from dbo.ALERTTEMPLATE");
            page.TestSqlButton.Click();
            Assert.IsTrue(page.PopUpText.Displayed);
            page.SaveButton.WithJs().Click();
            page.SearchInputField.SendKeys("e2e test");
            page.SearchItemButton.Click();
            page.EditButtonCreatedColumn.Click();
            page.NameInputField.Click();
            for (int i = 0; i < 10; i++)
            {
                action.SendKeys(OpenQA.Selenium.Keys.Delete).Build().Perform();
                action.SendKeys(OpenQA.Selenium.Keys.Backspace).Build().Perform();
            }
            driver.WaitForAngularWithTimeout(500);
            page.NameInputField.SendKeys("e2e update");
            page.SaveButton.WithJs().Click();
            page.CloseButton.WithJs().Click();
            page.ClearButton.WithJs().Click();
            page.SearchInputField.SendKeys("e2e update");
            page.SearchItemButton.Click();
            page.DeleteButtonCreatedColumn.Click();
            page.DeleteButton.Click();
            Assert.IsTrue(page.NoResultsFoundText.Displayed);
        }
    }
}
