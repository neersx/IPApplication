using Inprotech.Tests.Integration.Extensions;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class Checkbox : PageObject
    {
        string _byCss;

        public Checkbox(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public Checkbox ByLabel(string label)
        {
            _byCss += $"ip-checkbox[label='{label}']";
            return this;
        }

        public Checkbox ByTagName()
        {
            _byCss += "ip-checkbox";
            return this;
        }

        public Checkbox ByModel(string model)
        {
            _byCss += $"[ng-model='{model}']";
            return this;
        }

        public Checkbox ByName(string name)
        {
            _byCss += $"ip-checkbox[name='{name}']";
            return this;
        }

        public NgWebElement Element => FindElement(By.CssSelector(_byCss));

        public NgWebElement Label => Element.FindElement(By.TagName("label"));

        public NgWebElement Input => Element.FindElement(By.TagName("input"));

        public bool IsChecked => Input.IsChecked();

        public bool IsDisabled => Input.IsDisabled();

        public void Click()
        {
            Label.Click();
            Driver.WaitForAngular();
        }
    }
}