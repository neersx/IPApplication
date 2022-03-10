using System;
using System.Linq;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Angular
{
    public class IpxTextField : PageObject
    {
        By _by;

        public IpxTextField(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public IpxTextField ByLabel(string label)
        {
            _by = By.CssSelector($"ipx-text-field[label='{label}']");
            return this;
        }

        public IpxTextField ByTagName()
        {
            _by = By.CssSelector("ipx-text-field");
            return this;
        }

        public IpxTextField ByName(string name)
        {
            _by = By.CssSelector($"ipx-text-field[name='{name}']");
            return this;
        }

        public IpxTextField ById(string id)
        {
            _by = By.CssSelector($"ipx-text-field[id='{id}']");
            return this;
        }

        public NgWebElement Element => FindElement(_by);

        public NgWebElement Input => Element.FindElements(By.TagName("input")).Any() ? Element.FindElement(By.TagName("input")) : Element.FindElement(By.TagName("textarea"));

        public bool HasError => Element.FindElement(By.CssSelector(".cpa-icon-exclamation-triangle")).WithJs().IsVisible(); // .Displayed is flaky on teamcity so using withJs instead
        public bool HasWarning => Element.FindElement(By.CssSelector(".cpa-icon-exclamation-circle")).WithJs().IsVisible();

        public string Text
        {
            get { return Input.GetAttribute("value"); }
            set
            {
                if (value != null)
                {
                    Input.Clear();
                    Input.SendKeys(value);
                    Element.Click();
                }
            }
        }

        public bool Exists => FindElements(_by).Any();
    }

    [Obsolete("Use IpxTextField instead")]
    public class AngularTextField : IpxTextField
    {
        [Obsolete("Use IpxTextField instead")]
        public AngularTextField(NgWebDriver driver, string name) : base(driver)
        {
            ByName(name);
        }
    }
}