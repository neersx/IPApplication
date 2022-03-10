using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.PtoAccess
{
    public class SchedulePageObject : MaintenanceModal
    {
        public SchedulePageObject(NgWebDriver driver) : base(driver, "NewSchedule")
        {
        }

        public IpTextField ScheduleName => new IpTextField(Driver).ByName("schedule");

        public DropDown DataSourceType => new DropDown(Driver).ByName("selectedDataSource");

        public DatePicker ExpiresAfter => new DatePicker(Driver, "expiresAfter");

        public IpRadioButton RunOnceOption => new IpRadioButton(Driver).ByLabel("dataDownload.newSchedule.runOnce");
        public IpRadioButton ContinuousOption => new IpRadioButton(Driver).ByLabel("dataDownload.newSchedule.continuous");

        public IpRadioButton RecurringOption => new IpRadioButton(Driver).ByLabel("dataDownload.newSchedule.recurring");

        public Checkbox AsapOption => new Checkbox(Driver).ByModel("vm.schedule.runNow");

        public SelectElement StartTimeHour => new SelectElement(Driver.FindElement(By.Id("runoncestarthour")));

        public SelectElement StartTimeMinutes => new SelectElement(Driver.FindElement(By.Id("runoncestartminute")));

        public void Save()
        {
            Apply();

            WaitUntilModalClose();
        }
    }
}