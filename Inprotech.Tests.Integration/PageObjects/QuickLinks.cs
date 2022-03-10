using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class QuickLinks : PageObject
    {
        public QuickLinks(NgWebDriver driver) : base(driver)
        {
        }

        NgWebElement Bar => Driver.FindElement(By.CssSelector("div#rightBar>div#quick-links-container"));

        public NgWebElement Get(string id)
        {
            return Driver.FindElement(By.Id(id));
        }

        public void Open(string id)
        {
            Driver.FindElement(By.Id(id)).WithJs().Click();
            Driver.WaitForAngularWithTimeout();
        }

        public void Close()
        {
            Driver.FindElement(By.Id("dismiss-quick-link")).WithJs().Click();
        }

        public NgWebElement SlideContainer => Driver.FindElement(By.Id("quick-links-content"));
    }
}
