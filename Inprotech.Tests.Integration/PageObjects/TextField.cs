using System.Linq;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class IpTextField : PageObject
    {
        By _by;

        public IpTextField(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public IpTextField ByLabel(string label)
        {
            _by = By.CssSelector($"ip-text-field[label='{label}']");
            return this;
        }

        public IpTextField ByTagName()
        {
            _by = By.CssSelector("ip-text-field");
            return this;
        }

        public IpTextField ByName(string name)
        {
            _by = By.CssSelector($"ip-text-field[name='{name}']");
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
                }
            }
        }
    }

    public class TextField : PageObject
    {
        readonly NgWebDriver _driver;
        readonly string _name;

        public TextField(NgWebDriver driver, string name) : base(driver)
        {
            _name = name;
            _driver = driver;
        }

        new NgWebElement Container => _driver.FindElement(By.Name(_name));

        public NgWebElement Element => Container;

        public NgWebElement Input => Container.FindElements(By.TagName("input")).Any() ? Container.FindElement(By.TagName("input")) : Container.FindElement(By.TagName("textarea"));

        public bool HasError => Container.FindElement(By.CssSelector(".cpa-icon-exclamation-triangle")).WithJs().IsVisible(); // .Displayed is flaky on teamcity so using withJs instead

        public string Text
        {
            get { return Input.GetAttribute("value"); }
            set
            {
                if (value != null)
                {
                    Input.Clear();
                    Input.SendKeys(value);
                }
            }
        }
    }
}