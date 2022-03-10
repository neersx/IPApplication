using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.TaxCode
{
    [Category(Categories.E2E)]
    [TestFixture]
    class MaintainTaxCode : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AddEditAndDeleteTaxCode(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/taxcodes");
            var page = new TaxCodePageObject(driver);
            driver.WaitForAngularWithTimeout();
            page.AddButton.Click();
            driver.WaitForAngularWithTimeout();
            page.TaxCode.SendKeys("TC1");
            page.TaxCodeDescription.SendKeys("Tax code description");
            page.SaveTaxCodeButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            Assert.AreEqual("Your changes have been successfully saved.", page.SuccessMessage.Text, "The changes have been successfully saved.");
            Assert.AreEqual("TC1",page.TaxCode.Value());
            Assert.AreEqual("Tax code description", page.TaxCodeDescription.Value());
            driver.WaitForAngularWithTimeout();
            page.DeleteButton.ClickWithTimeout();
            page.Delete.Click();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            Assert.AreEqual("Your changes have been successfully saved.", page.SuccessMessage.Text, "The changes have been successfully saved.");
            driver.WaitForAngularWithTimeout();
            page.BackButton.ClickWithTimeout();
            page.AddButton.Click();
            driver.WaitForAngularWithTimeout();
            page.TaxCode.SendKeys("TC1");
            page.TaxCodeDescription.SendKeys("Tax code description");
            page.SaveTaxCodeButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("Your changes have been successfully saved.", page.SuccessMessage.Text, "The changes have been successfully saved.");
            page.BackButton.ClickWithTimeout();
            driver.WaitForGridLoader();
            page.AddButton.Click();
            driver.WaitForAngularWithTimeout();
            page.TaxCode.SendKeys("TC1");
            page.TaxCodeDescription.SendKeys("Tax code description");
            page.SaveTaxCodeButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("The field entered must be unique.", page.AlertMessage.Text);
            page.AlertOkButton.Click();
            page.TaxCode.Clear();
            page.TaxCode.SendKeys("TC2");
            page.SaveTaxCodeButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            Assert.AreEqual("Your changes have been successfully saved.", page.SuccessMessage.Text, "The changes have been successfully saved.");
            page.BackButton.ClickWithTimeout();
            driver.WaitForGridLoader();
            var grid = page.ResultGrid;
            grid.ActionMenu.OpenOrClose();
            page.BulkMenuSelectAllButton.Click();
            page.BulkMenuDeleteButton.Click();
            page.Delete.ClickWithTimeout();
            var alertMessage = page.AlertMessage.Text;
            Assert.True(alertMessage.Contains("This process has been partially completed."));
            Assert.True(alertMessage.Contains("Items highlighted in red cannot be deleted as they are in use."));
            page.AlertOkButton.Click();
            driver.WaitForAngularWithTimeout();
            page.AddButton.Click();
            driver.WaitForAngularWithTimeout();
            page.TaxCode.SendKeys("TC1");
            page.TaxCodeDescription.SendKeys("Tax code description");
            page.SaveTaxCodeButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("Your changes have been successfully saved.", page.SuccessMessage.Text, "The changes have been successfully saved.");
            Assert.IsTrue(page.TaxCode.IsDisabled());
            Assert.IsFalse(page.TaxCodeDescription.IsDisabled());
            page.TaxCodeDescription.Clear();
            page.TaxCodeDescription.SendKeys("Tax code description test");
            page.SaveButton.ClickWithTimeout();
            Assert.AreEqual("Your changes have been successfully saved.", page.SuccessMessage.Text, "The changes have been successfully saved.");
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual("Tax code description test", page.TaxCodeDescription.Value());
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void AddUpdateAndDeleteTaxRate(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/taxcodes");
            var page = new TaxCodePageObject(driver);
            driver.WaitForAngularWithTimeout(); 
            var grid = page.ResultGrid;
            page.AddButton.Click();
            driver.WaitForAngularWithTimeout();
            page.TaxCode.SendKeys("TC1");
            page.TaxCodeDescription.SendKeys("Tax code description");
            page.SaveTaxCodeButton.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            Assert.AreEqual("Your changes have been successfully saved.", page.SuccessMessage.Text, "The changes have been successfully saved.");
            driver.WaitForGridLoader();
            page.TaxRate.NavigateTo();
            driver.WaitForAngularWithTimeout();
            driver.WaitForGridLoader();
            var taskGrid = page.TaxRate.TaxRateGrid;
            taskGrid.AddButton.ClickWithTimeout();
            page.SelectPickListItem(0,"jurisdiction","Afghanistan");
            taskGrid.Cell(0, taskGrid.FindColByText("Tax Rate")).FindElement(By.TagName("input")).SendKeys("10.00");
            page.EffectiveDate.GoToDate(2);
            page.SaveButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(1, taskGrid.Rows.Count, "1 record is displayed");
            taskGrid.Cell(0, taskGrid.FindColByText("Tax Rate")).FindElement(By.TagName("input")).Clear();
            taskGrid.Cell(0, taskGrid.FindColByText("Tax Rate")).FindElement(By.TagName("input")).SendKeys("11.00");
            page.SaveButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual("11.00", page.TaxRateEntry.Value());
            page.DeleteRow.ClickWithTimeout();
            page.SaveButton.ClickWithTimeout();
            driver.WaitForAngular();
            driver.WaitForGridLoader();
            Assert.AreEqual(0, taskGrid.Rows.Count, "0 record is displayed");
        }
    }
}
