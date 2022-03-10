using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    class RemindersModal : MaintenanceModal
    {
        public RemindersModal(NgWebDriver driver) : base(driver, null)
        {
        }

        public IpTextField StandardMessage => new IpTextField(Driver, Modal).ByName("standardMessage");
        public IpTextField AlternateMessage => new IpTextField(Driver, Modal).ByName("alternateMessage");
        public Checkbox UseOnAndAfterDueDate => new Checkbox(Driver, Modal).ByModel("vm.formData.useOnAndAfterDueDate");

        public Checkbox AlsoSendEmail => new Checkbox(Driver, Modal).ByModel("vm.formData.sendEmail");
        public IpTextField EmailSubject => new IpTextField(Driver, Modal).ByName("emailSubject");

        public TextDropDownGroup StartSending => new TextDropDownGroup(Driver, Modal).ByName("startBefore");
        public Checkbox Recurring => new Checkbox(Driver, Modal).ByModel("vm.recurring");
        public TextDropDownGroup RepeatEvery => new TextDropDownGroup(Driver, Modal).ByName("repeatEvery");
        public TextDropDownGroup StopAfter => new TextDropDownGroup(Driver, Modal).ByName("stopTime");

        public Checkbox StaffCheckbox => new Checkbox(Driver, Modal).ByModel("vm.formData.sendToStaff");
        public Checkbox SignatoryCheckbox => new Checkbox(Driver, Modal).ByModel("vm.formData.sendToSignatory");
        public Checkbox CriticalListCheckbox => new Checkbox(Driver, Modal).ByModel("vm.formData.sendToCriticalList");

        public PickList Name => new PickList(Driver).ByName(".modal", "name");
        public PickList NameType => new PickList(Driver).ByName(".modal", "nameTypes");
        public PickList Relationship => new PickList(Driver).ByName(".modal", "relationship");
    }
}
