using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects
{
    public class ButtonInput : Selectors<ButtonInput>
    {
        public ButtonInput(NgWebDriver driver) : base(driver)
        {
        }
        public ButtonInput(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public void Click()
        {
            Element.ClickWithTimeout();
        }

        public bool IsVisible()
        {
            return Element.WithJs().IsVisible();
        }

        public bool IsDisabled()
        {
            return Element.WithJs().IsDisabled() || Element.WithJs().GetAttributeValue<string>("disabled") == "disabled";
        }

        public T GetAttributeValue<T>(string attribute)
        {
            return Element.WithJs().GetAttributeValue<T>(attribute);
        }
    }
}