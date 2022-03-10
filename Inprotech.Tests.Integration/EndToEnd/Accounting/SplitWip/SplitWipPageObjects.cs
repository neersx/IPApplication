using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.SplitWip
{
    public class SplitWipPageObjects : PageObject
    {
        public SplitWipPageObjects(NgWebDriver driver) : base(driver)
        {
        }

        public AngularPicklist CasePicklist => new AngularPicklist(Driver).ByName("case");
        public AngularDropdown Reason => new AngularDropdown(Driver).ByName("reason");
        public IpxNumericField Amount => new IpxNumericField(Driver, Container).ByName("amount");
        public IpxNumericField SplitPercent => new IpxNumericField(Driver, Container).ByName("splitPercent");
        public AngularKendoGrid SplitWipGrid => new AngularKendoGrid(Driver, "splitWip");
        public ButtonInput AllocateRemainder => new ButtonInput(Driver).ByName("allocateRemainder");
        public ButtonInput ApplyButton => new ButtonInput(Driver).ByCssSelector("ipx-apply-button");
        public ButtonInput SaveButton => new ButtonInput(Driver).ByCssSelector("ipx-save-button button");
        public NgWebElement ButtonClose => Driver.FindElement(By.CssSelector("ipx-close-button button"));
    }
}
