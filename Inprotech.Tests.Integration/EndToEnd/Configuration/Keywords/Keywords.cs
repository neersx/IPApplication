using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Accounting.Time;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Keywords;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Keywords
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class Keywords : IntegrationTest
    {
        KeywordsDbSetup _dbSetup;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void KeywordsList(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.MaintainKeyword, Allow.Delete | Allow.Modify | Allow.Create).Create();
            var driver = BrowserProvider.Get(browserType);
            _dbSetup = new KeywordsDbSetup();
            var data = _dbSetup.SetupKeyWords();
            SignIn(driver, "/#/configuration/search", user.Username, user.Password);
            var page = new KeywordsPageObject(driver);
            page.SearchTextBox(driver).SendKeys("Keywords");
            page.SearchButton.ClickWithTimeout();
            page.KeywordNavigationLink.ClickWithTimeout();

            Assert.True(page.KeywordsGrid.Rows.Count >= 3);
            page.SearchTextBoxInKeywords(driver).SendKeys("E2e");
            page.SearchButton.ClickWithTimeout();
            Assert.AreEqual(page.KeywordsGrid.Rows.Count, 2);
            var k1 = (Keyword) data.k1;
            Assert.AreEqual(k1.KeyWord, page.KeywordsGrid.CellText(0, 1));

            // Delete
            var deleteMenu = page.DeleteMenu;
            Assert.IsTrue(deleteMenu.Disabled());
            page.KeywordsGrid.SelectRow(1);
            Assert.IsFalse(deleteMenu.Disabled());
            deleteMenu.WithJs().Click();
            var popups = new CommonPopups(driver);
            Assert.NotNull(popups.ConfirmDeleteModal);
            driver.FindElement(By.CssSelector(".buttons > button:nth-child(1)")).ClickWithTimeout();
            Assert.AreEqual(page.KeywordsGrid.Rows.Count, 2);
            deleteMenu.WithJs().Click();
            driver.FindElement(By.CssSelector(".buttons > button:nth-child(2)")).ClickWithTimeout();
            Assert.AreEqual(page.KeywordsGrid.Rows.Count, 1);

            //add
            page.ButtonAddOffice.ClickWithTimeout();
            Assert.NotNull(page.Modal);
            Assert.AreEqual(false, page.ModalSave.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);
            page.Keyword.Input.SendKeys("test");
            driver.WaitForAngular();
            Assert.AreEqual(true, page.ModalSave.Enabled);
            Assert.AreEqual(true, page.ModalCancel.Enabled);
            page.ModalSave.ClickWithTimeout();
            driver.WaitForAngular();
            Assert.AreEqual(1, page.KeywordsGrid.Rows.Count);
        }
    }
}