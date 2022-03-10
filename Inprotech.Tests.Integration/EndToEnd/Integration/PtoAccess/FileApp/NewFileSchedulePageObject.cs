using Inprotech.Tests.Integration.PageObjects;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.PtoAccess.FileApp
{
    public class NewFileSchedulePageObject : SchedulePageObject
    {
        public NewFileSchedulePageObject(NgWebDriver driver) : base(driver)
        {
        }

        public PickList SaveQuery => new PickList(Driver).ById("savedQuerySelected");

        public PickList RunAs => new PickList(Driver).ById("runAsUserSelected");
    }
}