using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class InlineAlert : PageObject
    {
        public InlineAlert(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public NgWebElement Element => FindElement(By.CssSelector("ip-inline-alert"));

        public bool Displayed => Element.Displayed;
    }
}