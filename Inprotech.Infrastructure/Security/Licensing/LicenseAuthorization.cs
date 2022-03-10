using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Infrastructure.Security.Licensing
{
    public class LicenseAuthorization : ILicenseAuthorization
    {
        readonly ILicenseSecurityProvider _licenseSecurityProvider;

        public LicenseAuthorization(ILicenseSecurityProvider licenseSecurityProvider)
        {
            if (licenseSecurityProvider == null) throw new ArgumentNullException(nameof(licenseSecurityProvider));
            _licenseSecurityProvider = licenseSecurityProvider;
        }

        public bool Authorize(IEnumerable<RequiresLicenseAttribute> controllerAttributes)
        {
            if (controllerAttributes == null) throw new ArgumentNullException(nameof(controllerAttributes));

            var controllerAttributesArray = controllerAttributes.ToArray();

            if(!controllerAttributesArray.Any())
                return true;

            var userLicenses = _licenseSecurityProvider.ListUserLicenses();
            
            if (controllerAttributesArray.Any(a => userLicenses.Any(userLicense => userLicense.Key == (int)a.LicensedModule)))
                return true;

            return false;
        }
    }
}
