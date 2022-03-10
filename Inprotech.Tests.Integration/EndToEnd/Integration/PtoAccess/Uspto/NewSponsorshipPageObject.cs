using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.PtoAccess.Uspto
{
    public class NewSponsorshipPageObject : MaintenanceModal
    {
        public NewSponsorshipPageObject(NgWebDriver driver) : base(driver, null)
        {
        }

        public IpTextField Email => new IpTextField(Driver).ByName("SponsoredEmail");
        public IpTextField AuthenticatorKey => new IpTextField(Driver).ByName("authenticatorKey");
        public IpTextField Name => new IpTextField(Driver).ByName("name");
        public IpTextField Password => new IpTextField(Driver).ByName("password");
        public IpTextField CustomerNumbers => new IpTextField(Driver).ByName("customerNumbers");
    }
}