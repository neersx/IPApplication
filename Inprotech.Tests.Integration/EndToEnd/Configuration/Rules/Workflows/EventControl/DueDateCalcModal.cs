using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    class DueDateCalcModal : MaintenanceModal
    {
        public DueDateCalcModal(NgWebDriver driver) : base(driver, null)
        {
        }

        public PickList Event => new PickList(Driver).ByName(".modal", "fromEvent");

        public IpRadioButton EventDate => new IpRadioButton(Driver, Modal).ByLabel("workflows.common.eventDate");

        public IpRadioButton DueDate => new IpRadioButton(Driver, Modal).ByLabel("workflows.common.dueDate");

        public IpRadioButton Either => new IpRadioButton(Driver, Modal).ByLabel(".either");

        public Checkbox MustExist => new Checkbox(Driver, Modal).ByLabel(".mustExist");

        public IpRadioButton Subtract => new IpRadioButton(Driver, Modal).ByLabel("workflows.eventcontrol.dueDateCalc.operatorMap.subtract");

        public IpRadioButton Add => new IpRadioButton(Driver, Modal).ByLabel("workflows.eventcontrol.dueDateCalc.operatorMap.add");

        public TextDropDownGroup Period => new TextDropDownGroup(Driver, Modal).ByLabel("workflows.common.period");

        public DropDown RelativeCycle => new DropDown(Driver, Modal).ByLabel("workflows.common.relCycle");

        public DropDown AdjustBy => new DropDown(Driver, Modal).ByLabel(".adjustBy");

        public DropDown NonWorkDay => new DropDown(Driver, Modal).ByLabel(".ifNonWorkDay");

        public IpTextField ToCycle => new IpTextField(Driver, Modal).ByLabel(".toCycle");

        public PickList Jurisdiction => new PickList(Driver).ByName(".modal", "jurisdiction");

        public PickList Document => new PickList(Driver).ByName(".modal", "document");

        public IpRadioButton UseStandardReminder => new IpRadioButton(Driver, Modal).ByLabel(".standardReminder");

        public IpRadioButton UseAlternateReminder => new IpRadioButton(Driver, Modal).ByLabel(".alternateReminder");

        public IpRadioButton SuppressAllReminders => new IpRadioButton(Driver, Modal).ByLabel(".suppressReminders");
    }
}
