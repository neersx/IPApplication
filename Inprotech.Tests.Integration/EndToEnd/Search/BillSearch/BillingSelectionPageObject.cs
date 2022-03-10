using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Search.BillSearch
{
    public class BillingSelectionPageObject : PageObject
    {
        public BillingSelectionPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement SelectAll => Driver.FindElement(By.XPath("//a[@id='a123_selectall']"));
        public NgWebElement ExportToPdfMessage => Driver.FindElement(By.XPath("//tbody/tr/td/a"));
        public List<NgWebElement> NotificationButton => Driver.FindElements(By.CssSelector("span.notification-count")).ToList();
        public int NotificationTextCount => Convert.ToInt32(NotificationButton.First().Text);

        public void NotificationCount(int notificationCount)
        {
            var count = 0;
            while (count < 30)
            {
                Driver.WaitForAngularWithTimeout(1000);
                if (NotificationButton.Count == 1)
                {
                    if (NotificationTextCount == notificationCount + 1)
                    {
                        break;
                    }
                }

                count++;
            }
        }

    }
}
