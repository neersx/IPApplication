using System;

namespace Inprotech.Infrastructure.Security.Licensing
{
    public class LicenseData
    {
        public LicenseData(int licensedModule, string licensedModuleName, DateTime? expiryDate)
        {
            LicensedModule = licensedModule;
            LicensedModuleName = licensedModuleName;
            ExpiryDate = expiryDate;
            IsTimeBased = ExpiryDate.HasValue;
        }

        public int LicensedModule { get; set; }

        public string LicensedModuleName { get; set; }

        public bool IsTimeBased { get; set; }

        public DateTime? ExpiryDate { get; set; }
    }
}