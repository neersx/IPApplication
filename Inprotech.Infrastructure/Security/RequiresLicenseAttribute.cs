using System;
using Inprotech.Infrastructure.Security.Licensing;

namespace Inprotech.Infrastructure.Security
{
    [AttributeUsage(AttributeTargets.Class,  AllowMultiple = true)]
    public class RequiresLicenseAttribute : Attribute
    {
        public RequiresLicenseAttribute(
            LicensedModule licensedModule)
        {
            LicensedModule = licensedModule;
        }

        public LicensedModule LicensedModule { get; private set; }
    }
}