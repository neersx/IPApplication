using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.PropertyType
{
    class PropertyTypeDbSetup : DbSetup
    {
        public const string JurisdictionCode = "e2e";
        public const string JurisdictionDescription = "e2e - jurisdiction";

        public dynamic PrepareEnvironment()
        {
            PrepareValidCombinations();

            return new
            {
                JurisdictionCode,
                JurisdictionDescription
            };
        }

        void PrepareValidCombinations()
        {
            // Base Objects
            Insert(new Country(JurisdictionCode, JurisdictionDescription) { AllMembersFlag = 0, Type = "0" });
        }
    }
}
