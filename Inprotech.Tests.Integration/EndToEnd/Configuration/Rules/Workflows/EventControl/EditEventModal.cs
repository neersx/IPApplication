using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    class EditEventModal : MaintenanceModal
    {
        public EditEventModal(NgWebDriver driver, string id = null) : base(driver, id)
        {
        }

        public IpTextField EventDescription => new IpTextField(Driver, Modal).ByName("description");
        public IpTextField EventCode => new IpTextField(Driver, Modal).ByName("code");
        public NgWebElement MaxCycles => Driver.FindElement(By.Name("maxCycles"));
        public SelectElement InternalImportance => new SelectElement(Driver.FindElement(By.Name("internalImportance")));

        public PickList EventCategory => new PickList(this.Driver).ByName("category");
        public PickList EventGroup => new PickList(this.Driver).ByName("eventGroup");

        public Checkbox RecalculateEventDate => new Checkbox(Driver).ByModel("c.formData.recalcEventDate");
        public Checkbox DontCalcDueDate => new Checkbox(Driver).ByModel("c.formData.suppressCalculation");
        public Checkbox AllowToPoliceImmediatelly => new Checkbox(Driver).ByModel("c.formData.allowPoliceImmediate");
    }
}
