using Inprotech.Tests.Integration.PageObjects;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portal.Widgets
{
    class RecentCasesWidget : PageObject
    {
        public RecentCasesWidget(NgWebDriver driver, NgWebElement container) : base(driver, container)
        {
        }

        public AngularKendoGrid Grid => new AngularKendoGrid(this.Driver, "recentCasesWidget");
    }
}
