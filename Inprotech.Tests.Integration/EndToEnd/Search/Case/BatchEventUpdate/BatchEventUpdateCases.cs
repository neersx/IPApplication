using Inprotech.Tests.Integration.EndToEnd.Search.Case.BulkUpdate;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.BatchEventUpdate
{
    public class BatchEventUpdateCases : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void BatchEventUpdateValidate(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");
            var page = new BatchEventUpdatePageObject(driver);
            page.SearchTextField.Click();
            var action = new Actions(driver);
            action.SendKeys(Keys.Enter).Build().Perform();
            page.FirstCheckbox.Click();
            page.BulkOperationButton.Click();
            driver.WaitForAngular();
            Assert.AreNotEqual("disabled", page.BulkEventUpdate.GetAttribute("class"));
            page.ClearSelected.Click();
            driver.WaitForAngular();
            Assert.AreEqual("disabled", page.BulkEventUpdate.GetAttribute("class"));
            page.SelectThisPage.Click();
            driver.WaitForAngular();
            Assert.AreNotEqual("disabled", page.BulkEventUpdate.GetAttribute("class"));
            ReloadPage(driver);
            page.FirstCheckbox.Click();
            page.SecondCheckbox.Click();
            page.BulkOperationButton.Click();
            page.BathEventUpdateButton.Click();
            driver.Wait().ForTrue(() => driver.WindowHandles.Count >1);
            var element = driver.SwitchTo().Window(driver.WindowHandles[1]).FindElement(By.XPath("//h3"));
            Assert.AreEqual("Batch Event Update", element.Text);
        }
    }
}