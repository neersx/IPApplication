using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class AngularCheckbox : PageObject
    {
        string _byCss;

        public AngularCheckbox(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public AngularCheckbox ByLabel(string label)
        {
            _byCss += $"ipx-checkbox[label='{label}']";
            return this;
        }

        public AngularCheckbox ByTagName()
        {
            _byCss += "ipx-checkbox";
            return this;
        }

        public AngularCheckbox ByModel(string model)
        {
            _byCss += $"[ng-model='{model}']";
            return this;
        }

        public AngularCheckbox ByName(string name)
        {
            _byCss += $"ipx-checkbox[name='{name}']";
            return this;
        }

        public AngularCheckbox ById(string id)
        {
            _byCss += $"ipx-checkbox[id='{id}']";
            return this;
        }

        public AngularCheckbox ByValue(string value)
        {
            _byCss += $"ipx-checkbox[value='{value}']";
            return this;
        }

        public NgWebElement Element => FindElement(By.CssSelector(_byCss));

        public NgWebElement Label => Element.FindElement(By.TagName("label"));

        public NgWebElement Input => Element.FindElement(By.TagName("input"));

        public bool IsShown => FindElements(By.CssSelector(_byCss)).Any();

        public bool IsChecked => Input.IsChecked();

        public bool IsDisabled => Input.IsDisabled();

        public void Click()
        {
            Label.Click();
            Driver.WaitForAngular();
        }
    }
}