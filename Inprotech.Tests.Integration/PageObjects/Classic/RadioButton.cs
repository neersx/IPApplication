using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Classic
{
    public class RadioButton : PageObject
    {
        readonly string _name;

        public RadioButton(NgWebDriver driver, string name) : base(driver, null)
        {
            _name = name;
        }

        public NgWebElement ByValue(string value)
        {
            return Driver.FindElement(By.CssSelector($"input[name={_name}][type=radio][value={value}]"));
        }
    }
}
