using System.Collections.Generic;
using System.Collections.ObjectModel;
using Inprotech.Integration;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using Protractor;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison
{
    public class InboxPageObject : PageObject
    {
        public InboxPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public ReadOnlyCollection<NgWebElement> Notifications => Driver.FindElements(NgBy.Repeater("n in notifications"));

        public CaseComparisonViewPageObject CaseComparisonView => new CaseComparisonViewPageObject(Driver).ById("caseComparisonView");

        public ErrorViewPageObject ErrorView => new ErrorViewPageObject(Driver).ById("errorView");

        public ReadOnlyCollection<NgWebElement> Sources => Driver.FindElements(By.CssSelector(".i-filter"));

        public Checkbox IncludeError => new Checkbox(Driver).ByModel("filterParams.includeErrors");
        
        public Checkbox IncludeReviewed => new Checkbox(Driver).ByModel("filterParams.includeReviewed");

        public Checkbox IncludeRejected => new Checkbox(Driver).ByModel("filterParams.includeRejected");

        public void ToggleFilter(DataSourceType source)
        {
            Driver.WrappedDriver.ExecuteJavaScript<object>($"$('#pill{source}').parent().click()");
        }

        public IEnumerable<DisplayedNotifications> DisplayedNotifications()
        {
            foreach (var notification in Notifications)
            {
                yield return new DisplayedNotifications
                             {
                                 Title = notification.FindElement(By.CssSelector(".nf-row-title")).Text,
                                 CaseRef = notification.FindElement(By.CssSelector(".nf-caseRef")).Text,
                                 Source = notification.FindElement(By.CssSelector("div.nf-row-main span:nth-child(1)")).Text,
                                 ApplicationNumber = notification.FindElement(By.CssSelector("div[ng-show='n.appNum']")).Text,
                                 PublicationNumber = notification.FindElement(By.CssSelector("div[ng-show='n.pubNum']")).Text,
                                 RegistrationNumber = notification.FindElement(By.CssSelector("div[ng-show='n.regNum']")).Text
                             };
            }
        }
    }

    public class DisplayedNotifications
    {
        public string Title { get; set; }

        public string CaseRef { get; set; }

        public string ApplicationNumber { get; set; }

        public string PublicationNumber { get; set; }

        public string RegistrationNumber { get; set; }

        public string Source { get; set; }
    }
}