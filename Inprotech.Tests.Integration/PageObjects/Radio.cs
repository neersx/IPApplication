using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class IpRadioButton : PageObject
    {
        string _byCss = "ip-radio-button";

        public IpRadioButton(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public IpRadioButton ByLabel(string label)
        {
            _byCss += $"[label='{label}']";
            return this;
        }
        public IpRadioButton ByName(string name)
        {
            _byCss = $"ip-radio-button[name='{name}']";
            return this;
        }

        public IpRadioButton ByModel(string model)
        {
            _byCss += $"[ng-model='{model}']";
            return this;
        }

        public IpRadioButton ByValue(string value)
        {
            _byCss += $"[value='{value}']";
            return this;
        }

        public NgWebElement Element => FindElement(By.CssSelector(_byCss));

        public NgWebElement Label => Element.FindElement(By.TagName("label"));

        public NgWebElement Input => Element.FindElement(By.TagName("input"));

        public bool IsChecked => Input.IsChecked();

        public bool IsDisabled => Input.IsDisabled();

        public bool IsDisplayed => Label.WithJs().IsVisible();

        public void Click() => Label.ClickWithTimeout();
    }

    public class IpxRadioButton : PageObject
    {
        string _byCss = "ipx-radio-button";

        public IpxRadioButton(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }
        
        public IpxRadioButton ById(string id)
        {
            _byCss += $"[id='{id}']";
            return this;
        }

        public IpxRadioButton ByLabel(string label)
        {
            _byCss += $"[label='{label}']";
            return this;
        }

        public IpxRadioButton ByName(string name)
        {
            _byCss = $"ipx-radio-button[name='{name}']";
            return this;
        }

        public IpxRadioButton ByModel(string model)
        {
            _byCss += $"[ng-model='{model}']";
            return this;
        }

        public IpxRadioButton ByValue(string value)
        {
            _byCss += $"[value='{value}']";
            return this;
        }

        public NgWebElement Element => FindElement(By.CssSelector(_byCss));

        public NgWebElement Label => Element.FindElement(By.TagName("label"));

        public NgWebElement Input => Element.FindElement(By.TagName("input"));

        public bool IsChecked => Input.IsChecked();

        public bool IsDisabled => Input.IsDisabled();

        public bool IsDisplayed => Label.WithJs().IsVisible();

        public void Click() => Label.ClickWithTimeout();
    }

    class RadioButtonOrCheckbox
    {
        readonly NgWebDriver _driver;
        readonly string _id;

        public RadioButtonOrCheckbox(NgWebDriver driver, string id)
        {
            _driver = driver;
            _id = id;
        }

        public NgWebElement Label => _driver.FindElement(By.CssSelector("label[for='" + _id + "']"));

        public NgWebElement Input => _driver.FindElement(By.Id(_id));

        public bool IsChecked => Input.WithJs().IsChecked();

        public bool IsDisabled => Input.WithJs().IsDisabled();

        public void Click()
        {
            Label.ClickWithTimeout();
        }
    }

    static class Radio
    {
        internal static RadioButtonOrCheckbox FindRadio(this NgWebDriver driver, string id)
        {
            return new RadioButtonOrCheckbox(driver, id);
        }

        internal static RadioButtonOrCheckbox FindCheckbox(this NgWebDriver driver, string id)
        {
            return new RadioButtonOrCheckbox(driver, id);
        }
    }
}