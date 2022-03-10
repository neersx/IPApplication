using Inprotech.Tests.Integration.PageObjects;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.PtoAccess.Uspto
{
    internal class NewPrivatePairSchedulePageObject : SchedulePageObject
    {
        public NewPrivatePairSchedulePageObject(NgWebDriver driver) : base(driver)
        {
        }

        public DropDown DigitalCertifcate => new DropDown(Driver).ByName("selectedCertificate");

        public DropDown DownloadType => new DropDown(Driver).ByName("selectedDownloadType");
    }
}