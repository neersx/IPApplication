using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Angular
{
    public class IpxNumericField : PageObject
    {
        By _by;

        public IpxNumericField(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public IpxNumericField ByTagName()
        {
            _by = By.CssSelector("ipx-numeric");
            return this;
        }

        public IpxNumericField ByName(string name)
        {
            _by = By.CssSelector($"ipx-numeric[name='{name}']");
            return this;
        }

        public NgWebElement Element => FindElement(_by);

        public NgWebElement Input => Element.FindElement(By.TagName("input"));

        public string Number => Input.GetAttribute("value");

        public string SetValue
        {
            set
            {
                Input.Clear();
                Input.SendKeys(value);
            }
        }
    }
}
