using Inprotech.Tests.Integration.PageObjects;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.PtoAccess.Innography
{
    public class NewInnographySchedulePageObject : SchedulePageObject
    {
        public NewInnographySchedulePageObject(NgWebDriver driver) : base(driver)
        {
        }

        public PickList SaveQuery => new PickList(Driver).ById("savedQuerySelected");

        public PickList RunAs => new PickList(Driver).ById("runAsUserSelected");

        public DropDown DownloadType => new DropDown(Driver).ByName("selectedDownloadType");
    }
}