using System.Security.Claims;
using CPA.SingleSignOn.Client;
using InprotechKaizen.Model.Components.Security.SingleSignOn;

namespace Inprotech.Web.Security
{
    public static class SsoClaimsIdentityExtensions
    {
        public static SsoIdentity ToSsoIdentity(this ClaimsIdentity identity)
        {
            return new SsoIdentity
                   {
                       Email = identity.GetEmail(),
                       FirstName = identity.GetFirstName(),
                       LastName = identity.GetLastName(),
                       Guk = identity.GetGUK()
                   };
        }
    }
}