using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Angular;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.InstructionType
{
    public class AngularInstructionTypePicklistModal : MaintenanceModal
    {
        public AngularInstructionTypePicklistModal(NgWebDriver driver) : base(driver)
        {
        }

        public AngularTextField Code => new AngularTextField(Driver, "code");

        public AngularTextField Description => new AngularTextField(Driver, "value");

        public AngularDropdown RecordedAgainst => new AngularDropdown(Driver).ByName("recordedAgainst");

        public AngularDropdown RestrictedBy => new AngularDropdown(Driver).ByName("restrictedBy");
    }
}