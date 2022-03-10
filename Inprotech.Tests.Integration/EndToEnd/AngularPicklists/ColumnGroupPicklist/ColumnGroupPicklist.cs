using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium.Interactions;

namespace Inprotech.Tests.Integration.EndToEnd.AngularPicklists.ColumnGroupPicklist
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ColumnGroupPicklist : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AddEditDeleteForColumnGroupPicklist(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/search");
            var page = new ColumnGroupPageObject(driver);
            page.SearchField.SendKeys("Case Search Columns");
            page.SearchButton.ClickWithTimeout();
            page.ConfigurationSearchLink.ClickWithTimeout();
            page.AddSearchColumnButton.ClickWithTimeout();
            Actions action = new Actions(driver);
            var columnGroupPicklist = new AngularPicklist(driver).ByName("columnGroup");
            columnGroupPicklist.SearchButton.Click();
            action.SendKeys(OpenQA.Selenium.Keys.Enter).Build().Perform();
            Assert.IsTrue(page.AddButton.Displayed);
            page.AddButton.Click();
            page.DescriptionInputField.SendKeys("TESTING1234");
            page.SaveButton.WithJs().Click();
            page.ItemInputField.SendKeys("TESTING1234");
            page.ItemSearchButton.Click();
            page.EditButtonCreatedColumn.Click();
            page.DescriptionInputField.Click();
            page.DescriptionInputField.Clear();
            page.DescriptionInputField.SendKeys("TESTING1235");
            page.SaveButton.WithJs().Click();
            page.CloseButton.WithJs().Click();
            page.ClearButton.WithJs().Click();
            page.ItemInputField.SendKeys("TESTING1235");
            page.ItemSearchButton.Click();
            page.DeleteButtonCreatedColumn.Click();
            page.DeleteButton.Click();
            Assert.IsTrue(page.NoResultsFoundText.Displayed);
        }
    }
}
