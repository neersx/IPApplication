using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.ExchangeRateSchedule
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ExchangeRateSchedule : IntegrationTest
    {
        ExchangeRateScheduleDbSetup _dbSetup;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ExchangeRateScheduleMaintenance(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainExchangeRatesSchedule, Allow.Delete | Allow.Modify | Allow.Create).Create();
            var driver = BrowserProvider.Get(browserType);
            _dbSetup = new ExchangeRateScheduleDbSetup();
            var data = _dbSetup.SetupExchangeRateSchedule();
            SignIn(driver, "/#/configuration/search", user.Username, user.Password);
            var page = new ExchangeRateSchedulePageObject(driver);
            page.SearchTextBox(driver).SendKeys("Exchange Rate Schedule");
            page.SearchButton.ClickWithTimeout();
            page.ExchangeRateScheduleNavigationLink.ClickWithTimeout();
            Assert.True(page.ExchangeRateScheduleGrid.Rows.Count >= 3);
            page.SearchTextBoxInOffice(driver).SendKeys("AAA");
            page.SearchButton.Click();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(1, page.ExchangeRateScheduleGrid.Rows.Count);
            Assert.AreEqual(data.e1.ExchangeScheduleCode, page.ExchangeRateScheduleGrid.CellText(0, 1));

            //maintain
            page.ButtonAdd.ClickWithTimeout();
            Assert.NotNull(page.Modal);
            Assert.AreEqual(false, page.ModalSave.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);
            page.Code.Input.SendKeys("EX1");
            page.Description.Input.SendKeys("EX1 Description");
            driver.WaitForAngular();
            Assert.AreEqual(true, page.ModalSave.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);
            page.ModalSave.ClickWithTimeout();
            driver.WaitForAngular();
            page.SearchTextBoxInOffice(driver).Clear();
            page.SearchTextBoxInOffice(driver).SendKeys("EX1");
            page.SearchButton.Click();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(1, page.ExchangeRateScheduleGrid.Rows.Count);
            Assert.AreEqual("EX1", page.ExchangeRateScheduleGrid.CellText(0, 1));
            Assert.AreEqual("EX1 Description", page.ExchangeRateScheduleGrid.CellText(0, 2));

            // Delete
            page.SearchTextBoxInOffice(driver).Clear();
            page.SearchButton.ClickWithTimeout();
            var deleteMenu = page.DeleteMenu;
            Assert.IsTrue(deleteMenu.Disabled());
            page.ExchangeRateScheduleGrid.SelectRow(0);
            Assert.IsFalse(deleteMenu.Disabled());
            deleteMenu.WithJs().Click();
            var popups = new CommonPopups(driver);
            Assert.NotNull(popups.ConfirmDeleteModal);
            driver.FindElement(By.CssSelector(".buttons > button:nth-child(1)")).ClickWithTimeout();
            var totalCount = _dbSetup.TotalExchangeRateScheduleCount().count;
            deleteMenu.WithJs().Click();
            driver.FindElement(By.CssSelector(".buttons > button:nth-child(2)")).ClickWithTimeout();
            Assert.AreEqual(totalCount - 1, _dbSetup.TotalExchangeRateScheduleCount().count);
        }
    }
}