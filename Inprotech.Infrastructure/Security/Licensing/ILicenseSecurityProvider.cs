using System.Collections.Generic;

namespace Inprotech.Infrastructure.Security.Licensing
{
    public interface ILicenseSecurityProvider
    {
        Dictionary<int, LicenseData> ListUserLicenses();
        bool IsLicensedForModules(List<LicensedModule> licensedModules);
    }
}
