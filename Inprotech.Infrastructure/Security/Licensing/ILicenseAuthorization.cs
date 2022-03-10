using System.Collections.Generic;

namespace Inprotech.Infrastructure.Security.Licensing
{
    public interface ILicenseAuthorization
    {
        bool Authorize(IEnumerable<RequiresLicenseAttribute> controllerAttributes);
    }
}
