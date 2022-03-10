using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    class DocumentsModal : MaintenanceModal
    {
        public DocumentsModal(NgWebDriver driver) : base(driver)
        {
            Charge = new ChargeForm(driver);
        }

        public PickList Document => new PickList(Driver).ByName(".modal", "document");
        public IpRadioButton ProduceEventOccurs=> new IpRadioButton(Driver).ByValue("eventOccurs");
        public IpRadioButton ProduceOnDueDate => new IpRadioButton(Driver).ByValue("onDueDate");
        public IpRadioButton ProduceRecurring => new IpRadioButton(Driver).ByValue("asScheduled");
        
        public ChargeForm Charge { get; }

        public TextDropDownGroup StartSending => new TextDropDownGroup(Driver, Modal).ByName("startBefore");
        public Checkbox Recurring => new Checkbox(Driver, Modal).ByModel("vm.recurring");
        public TextDropDownGroup RepeatEvery => new TextDropDownGroup(Driver, Modal).ByName("repeatEvery");
        public TextDropDownGroup StopAfter => new TextDropDownGroup(Driver, Modal).ByName("stopTime");
        public IpTextField MaxDocuments => new IpTextField(Driver, Modal).ByName("maxDocuments");
        
        public Checkbox CheckCycleForSubstitute => new Checkbox(Driver, Modal).ByModel("vm.formData.isCheckCycleForSubstitute");
    }
}
