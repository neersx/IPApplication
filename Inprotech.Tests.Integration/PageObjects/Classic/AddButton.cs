using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Classic
{
    public class AddButton : Selectors<AddButton>
    {
        public AddButton(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public bool IsDisabled => Element.GetParent().GetCssValue("cursor") == "not-allowed" && Element.GetParent().GetAttribute("class") == "link-disabled";

        public void Click()
        {
            Element.WithJs().Click();
        }
    }
}