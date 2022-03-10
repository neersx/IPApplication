using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.InstructionType
{
    public class InstructionTypePicklistModal : MaintenanceModal
    {
        public InstructionTypePicklistModal(NgWebDriver driver) : base(driver)
        {
        }

        public TextField Code => new TextField(Driver, "code");

        public TextField Description => new TextField(Driver, "value");

        public DropDown RecordedAgainst => new DropDown(Driver).ByName("recordedAgainst");

        public DropDown RestrictedBy => new DropDown(Driver).ByName("restrictedBy");
    }
}