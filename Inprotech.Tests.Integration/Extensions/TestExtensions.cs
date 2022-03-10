using System.Threading;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;
using OpenQA.Selenium.Remote;
using Protractor;

namespace Inprotech.Tests.Integration.Extensions
{
    public static class TestExtensions
    {
        public static void WaitForAngularWithTimeout(this NgWebDriver driver, int waitTimeout = 500, int numberOfRetries = 3)
        {
            Thread.Sleep(200);
            Try.Retry(numberOfRetries, waitTimeout, driver.WaitForAngular);
        }

        public static void TryClick(this NgWebElement element)
        {
            Try.Retry(3, 500, element.Click);
        }

        public static void ClickWithTimeout(this NgWebElement element, int timeoutSeconds = 2, bool waitForAngular = true)
        {
            var driver = element.CurrentDriver();
            driver.WithTimeout(timeoutSeconds, element.Click);
            if (waitForAngular)
                driver.WaitForAngular();
        }

        public static NgWebDriver CurrentDriver(this NgWebElement element)
        {
            var rwe = (RemoteWebElement)element.WrappedElement;
            var driver = (RemoteWebDriver)rwe.WrappedDriver;

            return BrowserProvider.Get((string)driver.Capabilities.GetCapability("browserName"));
        }

        public static bool Is(this NgWebDriver driver, BrowserType browserType)
        {
            var rwd = (RemoteWebDriver)driver.WrappedDriver;
            var browserName = (string)rwd.Capabilities.GetCapability("browserName");
            return BrowserProvider.Browsers[browserName] == browserType;
        }

        public static NgWebElement GetParent(this NgWebElement element)
        {
            try
            {
                return element.WithJs().GetParent();
            }
            catch (InvalidSelectorException)
            {
                return null;
            }
        }

        public static NgWebElement GetSibling(this NgWebElement element, string elementTag)
        {
            try
            {
                return element.FindElement(By.XPath($"./following-sibling::{elementTag}"));
            }
            catch (InvalidSelectorException)
            {
                return null;
            }
        }

        public static bool IsElementPresent(this NgWebDriver driver, By locatorKey)
        {
            try
            {
                driver.FindElement(locatorKey);
                return true;
            }
            catch (NoSuchElementException)
            {
                return false;
            }
        }

        public static string Value(this NgWebElement element)
        {
            return element.GetAttribute("value");
        }

        public static void ClickLinkToNewBrowserWindow(this NgWebDriver driver, NgWebElement link)
        {
            link.WithJs().Click();

            driver.SwitchTo().Window(driver.WindowHandles[1]);
        }

        public static bool IsChecked(this NgWebElement element)
        {
            return element.WithJs().IsChecked();
        }

        public static bool IsDisabled(this NgWebElement element)
        {
            return element.WithJs().IsDisabled();
        }

        public static void HoverOff(this NgWebDriver driver)
        {
            // hover off a control to close tooltips
            new Actions(driver).MoveByOffset(50, 50).Perform();
        }

        public static void Hover(this NgWebDriver driver, NgWebElement element)
        {
            new Actions(driver).MoveToElement(element).Build().Perform();
        }
    }
}