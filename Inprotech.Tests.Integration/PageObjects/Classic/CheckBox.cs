using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using Protractor;

namespace Inprotech.Tests.Integration.PageObjects.Classic
{
    public class Checkbox : Selectors<Checkbox>
    {
        public Checkbox(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
        }

        public bool IsChecked => Element.IsChecked();

        public bool IsDisabled => Element.IsDisabled();

        public void Click()
        {
            Element.WithJs().Click();
        }
    }
}
