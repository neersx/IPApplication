using System;
using System.Threading;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using Protractor;

namespace Inprotech.Tests.Integration.Utils
{
    public static class WaitHelper
    {
        public static void WaitForGridLoadComplete(NgWebDriver driver, KendoGrid grid = null)
        {
            if (grid != null)
            {
                driver.Wait().ForTrue(() => grid.GridIsLoaded, 3000);
            }
            else
            {
                driver.Wait().ForExists(By.CssSelector(".k-grid.ip-data-loaded"));
            }
        }

        public static void WaitForBlockUi(this NgWebDriver driver)
        {
            var script = "return $('.block-modal-window').is(':visible') == false;";

            driver.Wait().ForTrue(() => driver.WrappedDriver.ExecuteJavaScript<bool>(script));
        }

        public static void WaitForGridLoader(this NgWebDriver driver)
        {
            var script = "return $('.k-loading-image').is(':visible') == false";

            driver.Wait().ForTrue(() => driver.WrappedDriver.ExecuteJavaScript<bool>(script));
        }

        [Obsolete("Wait for an element state to change, don't just wait")]
        public static void Wait(int milliseconds = 300)
        {
            Thread.Sleep(milliseconds);
        }
    }
}