using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Security
{
    public interface ILicenseAuthorization
    {
        bool TryAuthorize(User user, out AuthorizationResponse response);
    }

    public class LicenseAuthorization : ILicenseAuthorization
    {
        readonly ILicenses _licenses;

        public LicenseAuthorization(ILicenses licenses)
        {
            _licenses = licenses;
        }

        public bool TryAuthorize(User user, out AuthorizationResponse response)
        {
            response = AuthorizationResponse.Authorized();

            var r = _licenses.Verify(user.Id);
            if (r.IsBlocked)
            {
                var reasonCode = r.FailReason.ToString().ToHyphenatedLowerCase();
                var unlicensedModule = r.UnlicensedModule;

                response = new AuthorizationResponse(reasonCode, unlicensedModule);
                return false;
            }

            return true;
        }
    }
}