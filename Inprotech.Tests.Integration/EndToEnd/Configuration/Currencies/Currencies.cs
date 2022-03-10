using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Accounting.Time;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Currencies
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class Currencies : IntegrationTest
    {
        CurrenciesDbSetup _dbSetup;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CurrencyMaintenance(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainCurrency, Allow.Delete | Allow.Modify | Allow.Create).Create();
            var driver = BrowserProvider.Get(browserType);
            _dbSetup = new CurrenciesDbSetup();
            var data = _dbSetup.SetupCurrencies();
            SignIn(driver, "/#/configuration/search", user.Username, user.Password);
            var page = new CurrenciesPageObject(driver);
            page.SearchTextBox(driver).SendKeys("currencies");
            page.SearchButton.ClickWithTimeout();
            page.CurrenciesNavigationLink.ClickWithTimeout();
            Assert.True(page.CurrencyGrid.Rows.Count >= 3);
            page.SearchTextBoxInOffice(driver).SendKeys("Currency 1");
            page.SearchButton.ClickWithTimeout();
            Assert2.WaitEqual(3, 500, () => 1, () => page.CurrencyGrid.Rows.Count);
            Assert.AreEqual(data.c1, page.CurrencyGrid.CellText(0, 3));

            // Delete
            page.SearchTextBoxInOffice(driver).Clear();
            page.SearchButton.ClickWithTimeout();
            var deleteMenu = page.DeleteMenu;
            Assert.IsTrue(deleteMenu.Disabled());
            page.CurrencyGrid.SelectRow(0);
            Assert.IsFalse(deleteMenu.Disabled());
            deleteMenu.WithJs().Click();
            var popups = new CommonPopups(driver);
            Assert.NotNull(popups.ConfirmDeleteModal);
            driver.FindElement(By.CssSelector(".buttons > button:nth-child(1)")).ClickWithTimeout();
            var totalCurrencyCount = _dbSetup.TotalCurrencyCount().count;
            deleteMenu.WithJs().Click();
            driver.FindElement(By.CssSelector(".buttons > button:nth-child(2)")).ClickWithTimeout();
            Assert.AreEqual(totalCurrencyCount - 1, _dbSetup.TotalCurrencyCount().count);

            page.SearchTextBoxInOffice(driver).Clear();

            //maintain
            page.ButtonAdd.ClickWithTimeout();
            Assert.NotNull(page.Modal);
            Assert.AreEqual(false, page.ModalSave.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);
            page.CurrencyCode.Input.SendKeys("ADD");
            page.Description.Input.SendKeys("Add Code Description");
            driver.WaitForAngular();
            Assert.AreEqual(true, page.ModalSave.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);
            page.ModalSave.ClickWithTimeout();
            driver.WaitForAngular();
            page.SearchTextBoxInOffice(driver).SendKeys("ADD");
            page.SearchButton.ClickWithTimeout();
            Assert2.WaitEqual(3, 500, () => 1, () => page.CurrencyGrid.Rows.Count);

            // exchange rate history
            page.CurrencyGrid.Cell(0, 1).FindElement(By.CssSelector("a")).ClickWithTimeout();
            Assert.NotNull(page.Modal);
            Assert.AreEqual(1, page.HistoryGrid.Rows.Count);
            page.ModalCancel.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.AreEqual(1, page.CurrencyGrid.Rows.Count);
        }
    }
}