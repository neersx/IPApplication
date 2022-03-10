using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    class TextDropDownGroup : PageObject
    {
        By _by;

        public TextDropDownGroup(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public NgWebElement Element => FindElement(_by);

        public NgWebElement TextInput => Element.FindElement(By.CssSelector(".control-group input[type=text]"));

        public SelectElement SelectElement => new SelectElement(Element.FindElement(By.CssSelector(".control-group select")));

        public string Text
        {
            get => TextInput.GetAttribute("value");

            set
            {
                if (string.IsNullOrEmpty(value)) return;
                TextInput.Clear();
                TextInput.SendKeys(value);
            }
        }

        public string OptionText
        {
            get => SelectElement.SelectedOption.Text;

            set
            {
                using (new PreserveScroll(SelectElement.WrappedElement as NgWebElement))
                {
                    SelectElement.SelectByText(value);
                }
            }
        }

        public bool IsDisabled => TextInput.IsDisabled() && !SelectElement.WrappedElement.Enabled;

        public bool IsHidden => Driver.FindElements(_by).Count == 0;

        public TextDropDownGroup ByLabel(string label)
        {
            _by = By.CssSelector($"ip-text-dropdown-group[label='{label}']");
            return this;
        }

        public TextDropDownGroup ByName(string name)
        {
            _by = By.CssSelector($"ip-text-dropdown-group[name='{name}']");
            return this;
        }
    }
}