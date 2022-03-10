using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using NUnit.Framework;
using OpenQA.Selenium;
using System.Linq;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.ExchangeRateVariations
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ExchangeRateVariations : IntegrationTest
    {
        ExchangeRateVariationsDbSetup _dbSetup;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ExchangeRateVariationUrlFromCurrency(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainCurrency, Allow.Delete | Allow.Modify | Allow.Create).Create();
            var driver = BrowserProvider.Get(browserType);
            _dbSetup = new ExchangeRateVariationsDbSetup();
            var data = _dbSetup.Setup();
            SignIn(driver, "/#/configuration/search", user.Username, user.Password);
            var page = new ExchangeRateVariationsPageObject(driver);
            page.SearchTextBox(driver).SendKeys("currencies");
            page.SearchButton.ClickWithTimeout();
            page.CurrenciesNavigationLink.ClickWithTimeout();
            Assert.True(page.CurrencyGrid.Rows.Count >= 3);
            var ex1 = (ExchangeRateVariation)data.e1;
            page.SearchTextBoxInCurrency(driver).SendKeys(ex1.Currency.Description);
            page.SearchButton.ClickWithTimeout();
            Assert2.WaitEqual(3, 1000, () => 1, () => page.CurrencyGrid.Rows.Count);
            Assert.True(condition: page.ExchangeRateVariationMenu.Disabled());
            page.CurrencyGrid.SelectRow(0);
            Assert.IsFalse(page.ExchangeRateVariationMenu.Disabled());
            page.ExchangeRateVariationMenu.WithJs().Click();

            var exchangeRateVariationTab = driver.WindowHandles.Last();
            var newWindow = driver.SwitchTo().Window(exchangeRateVariationTab);
            Assert.IsTrue(newWindow.Url.Contains("#/configuration/exchange-rate-variation"), "Expected exchange rate variations to open in new tab");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ExchangeRateVariationUrlFromExchangeRateSchedule(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainExchangeRatesSchedule, Allow.Delete | Allow.Modify | Allow.Create).Create();
            var driver = BrowserProvider.Get(browserType);
            _dbSetup = new ExchangeRateVariationsDbSetup();
            var data = _dbSetup.Setup();
            SignIn(driver, "/#/configuration/search", user.Username, user.Password);
            var page = new ExchangeRateVariationsPageObject(driver);
            page.SearchTextBox(driver).SendKeys("Exchange Rate Schedule");
            page.SearchButton.ClickWithTimeout();
            page.CurrenciesNavigationLink.ClickWithTimeout();
            Assert.True(page.ExchangeRateScheduleGrid.Rows.Count >= 2);
            var ex1 = (ExchangeRateVariation) data.e3;
            page.SearchTextBoxInExchangeRateSchedule(driver).SendKeys(ex1.ExchangeRateSchedule.Description);
            page.SearchButton.ClickWithTimeout();
            Assert2.WaitEqual(3, 1000, () => 1, () => page.ExchangeRateScheduleGrid.Rows.Count);
            Assert.True(condition: page.ExchangeRateVariationMenu.Disabled());
            page.ExchangeRateScheduleGrid.SelectRow(0);
            Assert.IsFalse(page.ExchangeRateVariationMenu.Disabled());
            page.ExchangeRateVariationMenu.WithJs().Click();

            var exchangeRateVariationTab = driver.WindowHandles.Last();
            var newWindow = driver.SwitchTo().Window(exchangeRateVariationTab);
            Assert.IsTrue(newWindow.Url.Contains("#/configuration/exchange-rate-variation"), "Expected exchange rate variations to open in new tab");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ExchangeRateVariationSearch(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainCurrency, Allow.Delete | Allow.Modify | Allow.Create).Create();
            var driver = BrowserProvider.Get(browserType);
            _dbSetup = new ExchangeRateVariationsDbSetup();
            var data = _dbSetup.Setup();
            SignIn(driver, "/#/configuration/exchange-rate-variation", user.Username, user.Password);
            var ex1 = (ExchangeRateVariation)data.e1;
            var page = new ExchangeRateVariationsPageObject(driver);
            page.CurrencyPicklist.Typeahead.SendKeys(ex1.Currency.Description);
            page.CurrencyPicklist.Typeahead.SendKeys(Keys.ArrowDown);
            page.CurrencyPicklist.Typeahead.SendKeys(Keys.Enter);
            page.SearchButton.ClickWithTimeout();
            Assert.AreEqual(2, page.ExchangeRateVariationGrid.Rows.Count);
            page.ClearButton.ClickWithTimeout();
            Assert.AreEqual(3, page.ExchangeRateVariationGrid.Rows.Count);

            page.CaseTypePicklist.Typeahead.Click();
            page.CaseTypePicklist.Typeahead.SendKeys(ex1.CaseType.Name);
            page.CaseTypePicklist.Typeahead.SendKeys(Keys.ArrowDown);
            page.CaseTypePicklist.Typeahead.SendKeys(Keys.Enter);
            page.CountryPicklist.Typeahead.Click();
            page.CountryPicklist.Typeahead.SendKeys(ex1.Country.Name);
            page.CountryPicklist.Typeahead.SendKeys(Keys.ArrowDown);
            page.CountryPicklist.Typeahead.SendKeys(Keys.Enter);
            page.PropertyTypePicklist.Typeahead.Click();
            page.PropertyTypePicklist.Typeahead.SendKeys(ex1.PropertyTypeCode);
            page.PropertyTypePicklist.Typeahead.SendKeys(Keys.ArrowDown);
            page.PropertyTypePicklist.Typeahead.SendKeys(Keys.Enter);
            page.SubTypePicklist.Typeahead.Click();
            page.SubTypePicklist.Typeahead.SendKeys(ex1.SubtypeCode);
            page.SubTypePicklist.Typeahead.SendKeys(Keys.ArrowDown);
            page.SubTypePicklist.Typeahead.SendKeys(Keys.Enter);
            page.SearchButton.ClickWithTimeout();
            Assert2.WaitEqual(3, 500, () => 1, () => page.ExchangeRateVariationGrid.Rows.Count);
            page.ClearButton.ClickWithTimeout();
            Assert.AreEqual(3, page.ExchangeRateVariationGrid.Rows.Count);

            // Delete
            var deleteMenu = page.DeleteMenu;
            Assert.IsTrue(deleteMenu.Disabled());
            page.ExchangeRateVariationGrid.SelectRow(2);
            Assert.IsFalse(deleteMenu.Disabled());
            deleteMenu.WithJs().Click();
            var popups = new CommonPopups(driver);
            Assert.NotNull(popups.ConfirmDeleteModal);
            driver.FindElement(By.CssSelector(".buttons > button:nth-child(1)")).ClickWithTimeout();
            Assert.AreEqual(3, page.ExchangeRateVariationGrid.Rows.Count);
            deleteMenu.WithJs().Click();
            driver.FindElement(By.CssSelector(".buttons > button:nth-child(2)")).ClickWithTimeout();
            Assert.AreEqual(2, page.ExchangeRateVariationGrid.Rows.Count);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ExchangeRateVariationMaintenance(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainCurrency, Allow.Delete | Allow.Modify | Allow.Create).Create();
            var driver = BrowserProvider.Get(browserType);
            _dbSetup = new ExchangeRateVariationsDbSetup();
            SignIn(driver, "/#/configuration/exchange-rate-variation", user.Username, user.Password);
            var page = new ExchangeRateVariationsPageObject(driver);

            page.ButtonAdd.ClickWithTimeout();
            Assert.NotNull(page.Modal);
            Assert.AreEqual(false, page.ModalSave.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);
            Assert.NotNull(page.effectiveDate.DateInput.Value);
            page.CurrencyPicklistField.Typeahead.SendKeys("AUD");
            Assert.AreEqual(true, page.ModalSave.Enabled);
            page.ModalSave.ClickWithTimeout();
            Assert.IsTrue(page.BuyFactor.HasError);
            Assert.IsTrue(page.SellFactor.HasError);
            Assert.IsTrue(page.BuyRate.HasError);
            Assert.IsTrue(page.SellFactor.HasError);
            page.BuyFactor.Input.SendKeys(Fixture.String(2));
            page.SellFactor.Input.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.IsFalse(page.SellFactor.HasError);
            Assert.IsFalse(page.BuyRate.HasError);
            Assert.IsFalse(page.SellFactor.HasError);
            page.BuyFactor.Input.Clear();
            page.BuyFactor.Input.SendKeys("1");
            Assert.IsFalse(page.BuyFactor.HasError);
            Assert.AreEqual(true, page.ModalSave.Enabled);
            page.ModalSave.ClickWithTimeout();
            Assert.AreEqual(1, page.ExchangeRateVariationGrid.Rows.Count);
            Assert.AreEqual("Australian Dollar", page.ExchangeRateVariationGrid.CellText(0, 1));
            Assert.AreEqual("1.0000", page.ExchangeRateVariationGrid.CellText(0, 5));

        }
    }
}