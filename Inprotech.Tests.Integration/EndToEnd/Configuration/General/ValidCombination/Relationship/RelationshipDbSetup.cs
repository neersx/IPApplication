using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.Relationship
{
    class RelationshipDbSetup : DbSetup
    {
        public const string JurisdictionCode = "e2e";
        public const string JurisdictionDescription = "e2e - jurisdiction";
        public const string PropertyTypeDescription = "Patents";

        public dynamic PrepareEnvironment()
        {
            PrepareValidCombinations();

            return new
            {
                JurisdictionCode,
                JurisdictionDescription,
                PropertyTypeDescription
            };
        }

        void PrepareValidCombinations()
        {
            // Base Objects
            var jurisdiction = Insert(new Country(JurisdictionCode, JurisdictionDescription) { AllMembersFlag = 0, Type = "0" });

            Insert(new ValidProperty
            {
                CountryId = jurisdiction.Id,
                PropertyTypeId = "P",
                PropertyName = PropertyTypeDescription
            });
        }
    }
}
