using System;
using System.Globalization;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class TextArea : PageObject
    {
        readonly NgWebDriver _driver;
        readonly string _id;

        public TextArea(NgWebDriver driver, string id) : base(driver)
        {
            _id = id;
            _driver = driver;
        }

        public NgWebElement Input => _driver.FindElement(By.Id(_id)).FindElement(By.CssSelector("textarea"));

        public void Enter(string value, bool clearBeforeEntry = false)
        {
            if (clearBeforeEntry)
                Input.Clear();

            Input.SendKeys(value);  
        }
    }
}