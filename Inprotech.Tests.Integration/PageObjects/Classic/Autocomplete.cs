using System;
using System.Threading;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.Extensions;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Classic
{
    public class Autocomplete : PageObject
    {
        readonly string _name;

        public Autocomplete(NgWebDriver driver, string name) : base(driver)
        {
            _name = name;
        }

        public void SelectByText(string text)
        {
            var retry = 0;
            var setValue = text;

            string InnerSetText()
            {
                var input = Driver.FindElements(By.CssSelector($"#{_name} input"))[1];

                input.SendKeys(text);

                input.SendKeys(Keys.Tab);

                input.SendKeys(Keys.Tab);

                Driver.Wait().ForTrue(AutoCompleteSet);

                Thread.Sleep(TimeSpan.FromSeconds(2));

                if (Driver.Is(BrowserType.Ie))
                {
                    // ensure focus left the field.
                    Driver.FindElement(By.ClassName("logo")).WithJs().Focus();
                }

                return Driver.WrappedDriver.ExecuteJavaScript<string>($"return $('#{_name} input').val()");
            }

            do
            {
                setValue = InnerSetText();
            }
            while (!string.IsNullOrWhiteSpace(setValue) && retry++ <= 3);
        }

        public void Clear()
        {
            Driver.FindElements(By.CssSelector($"#{_name} input"))[1].Clear();
            
            if (Driver.Is(BrowserType.Ie))
            {
                // ensure focus left the field.
                Driver.FindElement(By.ClassName("logo")).WithJs().Focus();
            }
        }

        public bool HasClass(string className)
        {
            return Driver.FindElement(By.Id(_name)).WithJs().HasClass(className);
        } 

        Func<bool> AutoCompleteSet => () => Driver.WrappedDriver.ExecuteJavaScript<bool>("return $('.fa-spinner').is(':visible') == false");
    }
}