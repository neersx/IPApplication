using System.Linq;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class AngularDatePicker : PageObject
    {
        readonly string _ipDatePickerTag = "ipx-date-picker";
        By _by;

        public AngularDatePicker(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public AngularDatePicker(NgWebDriver driver, string dropDownTag) : base(driver)
        {
            _ipDatePickerTag = dropDownTag;
        }

        public NgWebElement Element => FindElement(_by);

        public TextInput DateInput => new TextInput(Driver,Element).ByTagName("input");
        public NgWebElement Calendar => Element.FindElement(By.TagName("button"));
        public NgWebElement Label => Element.FindElement(By.TagName("label"));

        public bool HasError => Element.FindElement(By.CssSelector(".cpa-icon-exclamation-triangle")).WithJs().IsVisible();
        public bool HasWarning => Element.FindElement(By.CssSelector(".cpa-icon-exclamation-circle")).WithJs().IsVisible();

        public bool IsDisabled => Element.FindElement(By.TagName("select")).WithJs().IsDisabled();

        public AngularDatePicker ByName(string name)
        {
            _by = By.CssSelector($"{_ipDatePickerTag}[name='{name}']");
            return this;
        }

        public AngularDatePicker ByName(string containerSelector, string name)
        {
            _by = By.CssSelector(string.Format($"{containerSelector} {_ipDatePickerTag}[name='{name}']"));
            return this;
        }

        public AngularDatePicker ByTagName()
        {
            _by = By.CssSelector(_ipDatePickerTag);
            return this;
        }

        public AngularDatePicker ByLabel(string name)
        {
            _by = By.CssSelector($"{_ipDatePickerTag}[label='{name}'], {_ipDatePickerTag}[data-label='{name}']");
            return this;
        }

        public void ManuallyEnterValue(string input)
        {
            DateInput.Clear();
            DateInput.Input(input);
            Driver.WaitForAngular();
            DateInput.Input(Keys.Tab);
        }
    }
}