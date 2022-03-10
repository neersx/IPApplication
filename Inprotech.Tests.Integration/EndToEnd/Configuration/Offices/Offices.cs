using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Accounting.Time;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Offices
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class Offices : IntegrationTest
    {
        OfficesDbSetup _dbSetup;

        [TestCase(BrowserType.Chrome, Ignore = "Will be fixed in other DR")]
        [TestCase(BrowserType.FireFox, Ignore = "Will be fixed in other DR")]
        public void OfficesList(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainOffice, Allow.Delete | Allow.Modify | Allow.Create).Create();
            var driver = BrowserProvider.Get(browserType);
            _dbSetup = new OfficesDbSetup();
            var data = _dbSetup.SetupOffices();
            SignIn(driver, "/#/configuration/search", user.Username, user.Password);
            var page = new OfficesPageObject(driver);
            page.SearchTextBox(driver).SendKeys("Offices");
            page.SearchButton.ClickWithTimeout();
            page.OfficeNavigationLink.ClickWithTimeout();

            Assert.True(page.OfficeGrid.Rows.Count >= 3);
            page.SearchTextBoxInOffice(driver).SendKeys("E2e");
            page.SearchButton.ClickWithTimeout();
            Assert.AreEqual(3, page.OfficeGrid.Rows.Count);
            var o1 = (Office)data.o1;
            Assert.AreEqual(o1.Name, page.OfficeGrid.CellText(0, 1));

            // Delete
            var deleteMenu = page.DeleteMenu;
            Assert.IsTrue(deleteMenu.Disabled());
            page.OfficeGrid.SelectRow(2);
            Assert.IsFalse(deleteMenu.Disabled());
            deleteMenu.WithJs().Click();
            var popups = new CommonPopups(driver);
            Assert.NotNull(popups.ConfirmDeleteModal);
            driver.FindElement(By.CssSelector(".buttons > button:nth-child(1)")).ClickWithTimeout();
            Assert.AreEqual(3, page.OfficeGrid.Rows.Count);
            deleteMenu.WithJs().Click();
            driver.FindElement(By.CssSelector(".buttons > button:nth-child(2)")).ClickWithTimeout();
            Assert.AreEqual(2, page.OfficeGrid.Rows.Count);

            //add
            page.ButtonAddOffice.ClickWithTimeout();
            Assert.NotNull(page.Modal);
            Assert.AreEqual(false, page.ModalSave.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);
            page.OfficeDesc.Input.SendKeys("E2e office 4");
            page.LanguagePicklist.SendKeys("English");
            page.LanguagePicklist.Click();
            driver.WaitForAngular();
            Assert.AreEqual(true, page.ModalSave.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);
            page.ModalSave.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.AreEqual(3, page.OfficeGrid.Rows.Count);
        }
    }
}