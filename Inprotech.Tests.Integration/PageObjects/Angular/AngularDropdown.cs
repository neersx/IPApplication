using System.Linq;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class AngularDropdown : PageObject
    {
        readonly string _ipDropdownTag = "ipx-dropdown";
        By _by;

        public AngularDropdown(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public AngularDropdown(NgWebDriver driver, string dropDownTag) : base(driver)
        {
            _ipDropdownTag = dropDownTag;
        }

        public NgWebElement Element => FindElement(_by);

        public SelectElement Input => new SelectElement(Element.FindElement(By.TagName("select")));

        public NgWebElement Label => Element.FindElement(By.TagName("label"));

        public string Text
        {
            set
            {
                var scrollY = Driver.WithJs().GetYScroll();
                Input.SelectByText(value);
                Driver.WithJs().ScrollTo(0, scrollY);
            }

            get => Input.SelectedOption?.Text?.Trim();
        }

        public string Value
        {
            set
            {
                var availableOptions = Input.Options.Select(_ => _.GetAttribute("value"));
                var selectOption = availableOptions.Single(_ => _.Contains(value));
                Input.SelectByValue(selectOption);
            }

            get
            {
                if (!Input.AllSelectedOptions.Any())
                    return string.Empty;
                var val = Input.SelectedOption?.GetAttribute("value");
                if (val == null)
                    return string.Empty; 
                var colonIndex = val.IndexOf(':') + 2;

                return colonIndex > 1 ? val.Substring(colonIndex, val.Length - colonIndex) : val;
            }
        }

        public bool HasError => Element.FindElement(By.CssSelector(".cpa-icon-exclamation-triangle")).WithJs().IsVisible();
        public bool HasWarning => Element.FindElement(By.CssSelector(".cpa-icon-exclamation-circle")).WithJs().IsVisible();
        public bool IsDisplayed => Label.WithJs().IsVisible();

        public bool IsDisabled => Element.FindElement(By.TagName("select")).WithJs().IsDisabled();

        public AngularDropdown ById(string id)
        {
            _by = By.CssSelector($"{_ipDropdownTag}[id='{id}']");
            return this;
        }

        public AngularDropdown ByName(string name)
        {
            _by = By.CssSelector($"{_ipDropdownTag}[name='{name}']");
            return this;
        }

        public AngularDropdown ByName(string containerSelector, string name)
        {
            _by = By.CssSelector(string.Format($"{containerSelector} {_ipDropdownTag}[name='{name}']"));
            return this;
        }

        public AngularDropdown ByTagName()
        {
            _by = By.CssSelector(_ipDropdownTag);
            return this;
        }

        public AngularDropdown ByLabel(string name)
        {
            _by = By.CssSelector($"{_ipDropdownTag}[label='{name}'], {_ipDropdownTag}[data-label='{name}']");
            return this;
        }
    }
}