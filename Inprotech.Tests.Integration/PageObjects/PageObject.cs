using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class PageObject
    {
        protected NgWebElement Container;

        protected ISearchContext SearchContext;

        public PageObject(NgWebDriver driver, NgWebElement container = null)
        {
            Driver = driver;
            Container = container;

            SearchContext = (ISearchContext)container ?? Driver;

            if (container == null)
            {
                FindElement = Driver.FindElement;
                FindElements = Driver.FindElements;
            }
            else
            {
                FindElement = container.FindElement;
                FindElements = container.FindElements;
            }
        }

        public NgWebDriver Driver { get; }

        public Func<By, NgWebElement> FindElement;
        public Func<By, IEnumerable<NgWebElement>> FindElements;
    }

    public static class PageObjectExtensions
    {
        public static void WithTimeout(this NgWebDriver driver, int timeoutSeconds, Action action)
        {
            try
            {
                Try.Do(() => driver.Manage().Timeouts().AsynchronousJavaScript = TimeSpan.FromSeconds(timeoutSeconds));
                Try.Do(() => driver.Manage().Timeouts().PageLoad = TimeSpan.FromSeconds(timeoutSeconds));

                try
                {
                    action();
                    driver.WaitForAngular();
                }
                catch (ElementNotInteractableException)
                {
                    
                }
                catch (InvalidOperationException)
                {
                    
                }
                catch (WebDriverTimeoutException)
                {
                }
            }
            finally
            {
                Try.Do(() => driver.Manage().Timeouts().AsynchronousJavaScript = TimeSpan.FromSeconds(Debugger.IsAttached ? 100 : Assm.TimeoutSeconds));
                Try.Do(() => driver.Manage().Timeouts().PageLoad = TimeSpan.FromSeconds(Assm.TimeoutSeconds));
            }
        }

        public static void Visit(this NgWebDriver driver, string url, bool withReload = false, bool doNotRetry = false)
        {
            if (withReload)
            {
                driver.Navigate().Refresh();
            }

            if (!url.StartsWith(Env.RootUrl))
                url = Env.RootUrl + url;

            var url2 = url.TrimEnd('/') + "/#/";
            var url3 = url2 + "home";
            var url4 = url2 + "portal2";
            
            var retryCount = doNotRetry ? 1 : 5;
            for (var i = 0; i < retryCount; i++)
            {
                driver.Url = url;
                driver.WaitForAngularWithTimeout();

                var browserUrl = driver.Wait().ForReadyState().WithJs().GetUrl();

                if (new[] {url, url2, url3, url4}.Contains(browserUrl))
                    break;
            }
        }
        
        public static void With<T>(this NgWebDriver driver, Action<T> run) where T : PageObject
        {
            var pageObject = (T)Activator.CreateInstance(typeof(T), driver);

            run(pageObject);
        }

        public static void With<T>(this NgWebDriver driver, Action<T, CommonPopups> run) where T : PageObject
        {
            var pageObject = (T)Activator.CreateInstance(typeof(T), driver);

            run(pageObject, new CommonPopups(driver));
        }
        
        public static bool IsNotAvailable(this NgWebElement element)
        {
            return element == null;
        }
    }
}