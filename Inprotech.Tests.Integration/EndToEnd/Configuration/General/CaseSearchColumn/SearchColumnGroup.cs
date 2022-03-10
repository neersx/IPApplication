using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.CaseSearchColumn
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class SearchColumnGroup : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _columnSearchDbSetup = new ColumnSearchCaseDbSetup();
            _scenario = _columnSearchDbSetup.Prepare();
        }

        ColumnSearchCaseDbSetup _columnSearchDbSetup;
        ColumnSearchCaseDbSetup.ScenarioData _scenario;

        [TestCase(BrowserType.Chrome, Ignore="Flaky Test")]
        [TestCase(BrowserType.FireFox, Ignore="Flaky Test")]
        [TestCase(BrowserType.Ie, Ignore = "Picklist not opening in IE")]
        public void AddCaseSearchColumnGroup(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/search");
            var page = new ColumnSearchPageObject(driver);
            page.SearchField.SendKeys("Case Search Columns");
            page.SearchButton.ClickWithTimeout();
            page.ConfigurationSearchLink.ClickWithTimeout();

            #region Add Case Search Column
            driver.WaitForGridLoader();
            page.AddSearchColumnButton.ClickWithTimeout();
            Assert.IsTrue(page.ParameterTextField.IsDisabled());
            Assert.IsTrue(page.VisibleCheckbox.IsChecked());
            Assert.IsFalse(page.MandatoryCheckbox.IsChecked());
            Assert.IsTrue(page.InternalCheckbox.IsChecked());
            Assert.IsFalse(page.ExternalCheckbox.IsChecked());
            page.DisplayName.SendKeys("e2e column");
            var picklist = new AngularPicklist(driver).ById("column-name");
            picklist.OpenPickList("UserColumnBoolean");
            driver.FindElement(By.XPath("//td[contains(text(),'UserColumnBoolean')]")).ClickWithTimeout();
            Assert.IsTrue(page.DataItemPicklist.Enabled);
            Assert.IsTrue(page.ParameterTextField.Enabled);
            page.ColumnDescription.SendKeys("e2e Description");
            page.ColumnGroupPicklist.SendKeys("e2e - Group");
            page.DisplayName.Click();
            page.ColumnGroupPicklist.Click();
            page.DataItemPicklist.SendKeys("e2e - DataItem");
            page.DisplayName.Click();
            page.DataItemPicklist.Click();
            page.ParameterTextField.SendKeys("1");
            page.SaveColumnButton.ClickWithTimeout();
            driver.WaitForGridLoader();
            page.SearchField.SendKeys("e2e");
            page.ColumnSearchButton.WithJs().Click();
            var grid = page.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "1 record is returned by search");
            Assert.AreEqual("e2e column", grid.Cell(0, 1).Text);
            Assert.AreEqual("e2e Description", grid.Cell(0, 2).Text);

            #endregion

            #region Edit Case Search Column

            driver.FindElement(By.XPath("//span/a[text()='e2e column']")).ClickWithTimeout();
            page.ColumnDescription.Click();
            page.ColumnDescription.Clear();
            page.ColumnDescription.SendKeys("e2e Description updated");
            page.SaveColumnButton.ClickWithTimeout();
            page.CloseColumnButton.ClickWithTimeout();
            driver.WaitForGridLoader();
            page.SearchField.Clear();
            page.SearchField.SendKeys("e2e");
            page.ColumnSearchButton.WithJs().Click();
            Assert.AreEqual("e2e Description updated", grid.Cell(0, 2).Text);

            #endregion

            #region Delete Case Search Column
            driver.WaitForAngularWithTimeout();
            grid.Cell(0, 0).Click();
            page.BulkActionMenu.Click();
            page.Delete.Click();
            var popups = new CommonPopups(driver);
            popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
            Assert.AreEqual(0, grid.Rows.Count, "0 record is returned by search");

            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void VerifyCaseSearchColumnFromPresentationScreen(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/search");
            var page = new ColumnSearchPageObject(driver);
            page.SearchField.SendKeys("Case Search Columns");
            page.SearchButton.ClickWithTimeout();
            page.ConfigurationSearchLink.ClickWithTimeout();
            page.AddSearchColumnButton.ClickWithTimeout();
            page.DisplayName.SendKeys("e2e column");
            page.ColumnNamePicklist.EnterExactSelectAndBlur("BilledTotal");
            page.DisplayName.Click();
            page.SaveColumnButton.ClickWithTimeout();
            driver.Visit(Env.RootUrl + "/#/case/search");
            page.PresentationLink.ClickWithTimeout();
            page.SearchColumnInputField.SendKeys("e2e column");
            var action = new Actions(driver);
            driver.FindElement(By.XPath("//strong[text()='e2e column']")).Click();
            action.MoveToElement(driver.FindElement(By.XPath("//strong[text()='e2e column']"))).Build().Perform();
            ((IJavaScriptExecutor) driver).ExecuteScript("arguments[0].click();", page.EditColumnButton);
            Assert.IsTrue(page.DisplayName.Displayed);
            page.ColumnDescription.Click();
            page.ColumnDescription.Clear();
            page.ColumnDescription.SendKeys("e2e Description updated");
            page.ColumnEditModalSaveButton.ClickWithTimeout();
            Assert.IsTrue(page.MaintainColumnButton.Displayed);
            Assert.IsTrue(page.GreenBorder.Displayed);
            page.MaintainColumnButton.ClickWithTimeout();
            foreach (var winHandle in driver.WindowHandles)
                driver.SwitchTo().Window(winHandle);
            driver.WaitForAngularWithTimeout(100);
            Assert.IsTrue(page.AddSearchColumnButton.Displayed);
            var grid = page.ResultGrid;
            page.SearchField.Clear();
            page.SearchField.SendKeys("e2e");
            page.ColumnSearchButton.WithJs().Click();
            driver.FindElement(By.XPath("//span/a[text()='e2e column']")).ClickWithTimeout();
            Assert.AreEqual("e2e Description updated", grid.Cell(0, 2).Text);
        }
    }
}