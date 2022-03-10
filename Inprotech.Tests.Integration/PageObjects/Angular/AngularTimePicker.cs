using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Angular
{
    public class AngularTimePicker : PageObject
    {
        readonly NgWebDriver _driver;
        By _by;
        public AngularTimePicker(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            _driver = driver;
        }

        public new AngularTimePicker FindElement(By by)
        {
            _by = by;
            return this;
        }

        public NgWebElement Element => base.FindElement(_by);

        public NgWebElement Input => Element.FindElement(By.TagName("input"));

        public void SetValue(string text)
        {
            Element.ClickWithTimeout();
            Input.SendKeys(text);
            Input.SendKeys(Keys.Tab);
            Driver.WaitForAngularWithTimeout();
        }
    }
}