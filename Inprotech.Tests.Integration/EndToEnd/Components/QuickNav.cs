using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Components
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class QuickNav : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void OpenShortcutsModalByClickOrKeyboard(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/detailpage");
                
            driver.FindElement(By.CssSelector("#quick-links-container #cheatSheet")).WithJs().Click();

            Assert.True(driver.FindElement(By.Id("keyboard-shortcuts-cheatsheet")).WithJs().IsVisible());

            driver.FindElement(By.CssSelector("button[class='btn btn-icon btn-discard']")).WithJs().Click();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        public void OpenShortcutsModalByKeyboard(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/deve2e/detailpage");

            driver.FindElement(By.CssSelector("#quick-links-container #cheatSheet")).ClickWithTimeout();

            Assert.True(driver.FindElement(By.Id("keyboard-shortcuts-cheatsheet")).WithJs().IsVisible());

            driver.FindElement(By.CssSelector("button[class='btn btn-icon btn-discard']")).WithJs().Click();
        }
    }
}