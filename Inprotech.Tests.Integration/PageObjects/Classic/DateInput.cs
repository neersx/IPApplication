using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Classic
{
    public class DateInput : PageObject
    {
        readonly string _name;

        public DateInput(NgWebDriver driver, string name) : base(driver)
        {
            _name = name;
        }

        public void Input(string dateString)
        {
            Driver.FindElement(By.Id(_name)).FindElement(By.TagName("input")).SendKeys(dateString);
        }

        public string Value => Driver.FindElement(By.Id(_name)).FindElement(By.TagName("input")).WithJs().GetValue();
        
    }
}
