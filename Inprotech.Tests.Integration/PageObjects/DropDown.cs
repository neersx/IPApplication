using System.Linq;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class DropDown : PageObject
    {
        readonly string _ipDropdownTag = "ip-dropdown";
        By _by;

        public DropDown(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public DropDown(NgWebDriver driver, string dropDownTag) : base(driver)
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

            get => Input.SelectedOption.Text;
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
                var val = Input.SelectedOption.GetAttribute("value");
                var colonIndex = val.IndexOf(':') + 1;

                return colonIndex > 0 ? val.Substring(colonIndex, val.Length - colonIndex) : val;
            }
        }

        public bool HasError => Element.FindElement(By.CssSelector(".cpa-icon-exclamation-triangle")).WithJs().IsVisible();
        public bool HasWarning => Element.FindElement(By.CssSelector(".cpa-icon-exclamation-circle")).WithJs().IsVisible();
        public bool IsDisplayed => Label.WithJs().IsVisible();

        public bool IsDisabled => Element.FindElement(By.TagName("select")).WithJs().IsDisabled();

        public DropDown ByName(string name)
        {
            _by = By.CssSelector($"{_ipDropdownTag}[name='{name}']");
            return this;
        }

        public DropDown ByName(string containerSelector, string name)
        {
            _by = By.CssSelector(string.Format($"{containerSelector} {_ipDropdownTag}[name='{name}']"));
            return this;
        }

        public DropDown ByTagName()
        {
            _by = By.CssSelector(_ipDropdownTag);
            return this;
        }

        public DropDown ByLabel(string name)
        {
            _by = By.CssSelector($"{_ipDropdownTag}[label='{name}'], {_ipDropdownTag}[data-label='{name}']");
            return this;
        }
    }
}