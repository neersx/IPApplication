using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    class DateLogicRulesModal : MaintenanceModal
    {
        public DateLogicRulesModal(NgWebDriver driver, string id = null) : base(driver, id)
        {
        }

        public IpRadioButton AppliesToEventDate => new IpRadioButton(Driver, Modal).ByName("appliesToEventDate");
        public IpRadioButton AppliesToDueDate => new IpRadioButton(Driver, Modal).ByName("appliesToDueDate");

        public DropDown Operator => new DropDown(Driver, Modal).ByName("operator");

        public PickList CompareEvent => new PickList(Driver).ByName(".modal", "compareEvent");

        public IpRadioButton UseEvent => new IpRadioButton(Driver, Modal).ByName("useEvent");
        public IpRadioButton UseDue => new IpRadioButton(Driver, Modal).ByName("useDue");
        public IpRadioButton UseEither => new IpRadioButton(Driver, Modal).ByName("useEither");

        public DropDown RelativeCycle => new DropDown(Driver, Modal).ByName("relativeCycle");

        public PickList CaseRelationship => new PickList(Driver).ByName(".modal", "caseRelationship");

        public Checkbox MustExist => new Checkbox(Driver, Modal).ByModel("vm.formData.eventMustExist");

        public IpRadioButton BlockUser => new IpRadioButton(Driver, Modal).ByName("blockUser");
        public IpRadioButton WarnUser => new IpRadioButton(Driver, Modal).ByName("warnUser");

        public TextField FailureMessage => new TextField(Driver, "failureMessage");
    }
}