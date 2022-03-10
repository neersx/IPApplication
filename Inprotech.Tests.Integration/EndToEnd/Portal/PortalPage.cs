using Inprotech.Tests.Integration.EndToEnd.Portal.Widgets;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portal
{
    internal class PortalPage : PageObject
    {
        public PortalPage(NgWebDriver driver) : base(driver)
        {
        }

        public RecentCasesWidget RecentCasesWidget => new RecentCasesWidget(Driver, Driver.FindElement(By.ClassName("recent-cases-widget")));
    }
}