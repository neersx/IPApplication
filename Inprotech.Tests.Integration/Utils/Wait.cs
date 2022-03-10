using System;
using System.Linq;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.Utils
{
    internal class DriverWait
    {
        const int DefaultWaitTimeout = 15000;
        const int DefaultSleepTimeout = 1000;

        readonly NgWebDriver _driver;

        internal DriverWait(NgWebDriver driver)
        {
            _driver = driver;
        }

        public NgWebDriver ForReadyState(int msTimeout = DefaultWaitTimeout)
        {
            try
            {
                var wait = new WebDriverWait(_driver, TimeSpan.FromMilliseconds(msTimeout));
                wait.Until(wrapper => _driver.WrappedDriver.ExecuteJavaScript<string>(@"return document.readyState") == "complete");
            }
            catch (WebDriverException)
            {
            }

            return _driver;
        }

        public NgWebElement ForVisible(By locatorKey, int msTimeout = DefaultWaitTimeout)
        {
            new WebDriverWait(_driver, TimeSpan.FromMilliseconds(msTimeout))
                .Until(ExpectedConditions.ElementIsVisible(locatorKey));

            return _driver.FindElement(locatorKey);
        }

        public NgWebElement ForExists(By locatorKey, int msTimeout = DefaultWaitTimeout)
        {
            new WebDriverWait(_driver, TimeSpan.FromMilliseconds(msTimeout))
                .Until(ExpectedConditions.ElementExists(locatorKey));

            return _driver.FindElement(locatorKey);
        }

        public void ForInvisible(By by, int msTimeout = DefaultWaitTimeout)
        {
            if (!_driver.FindElements(by).Any(_ => _.Displayed))
                return;

            new WebDriverWait(_driver, TimeSpan.FromMilliseconds(msTimeout))
                .Until(d =>
                       {
                           try
                           {
                               return !d.FindElements(by).Any(_ => _.Displayed);
                           }
                           catch (NoSuchElementException)
                           {
                               return false;
                           }
                       });
        }

        public void ForTrue(Func<bool> condition, int msTimeout = DefaultWaitTimeout, int sleepInterval = DefaultSleepTimeout)
        {
            new WebDriverWait(new SystemClock(), _driver, TimeSpan.FromMilliseconds(msTimeout), TimeSpan.FromMilliseconds(sleepInterval))
                .Until(d => condition().Equals(true));
        }

        public void ForAlert(int msTimeout = DefaultWaitTimeout, int waitTime = DefaultSleepTimeout)
        {
            new WebDriverWait(new SystemClock(), _driver, TimeSpan.FromMilliseconds(msTimeout), TimeSpan.FromMilliseconds(waitTime))
                .Until(ExpectedConditions.AlertIsPresent());
        }
    }

    internal static class DriverWaitExt
    {
        public static DriverWait Wait(this NgWebDriver driver)
        {
            return new DriverWait(driver);
        }
    }
}