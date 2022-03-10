using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.Basis
{
    class BasisDbSetup : DbSetup
    {
        public const string JurisdictionCode = "e2e";
        public const string JurisdictionDescription = "e2e - jurisdiction";
        public const string PropertyTypeDescription = "Patents";
        public const string CategoryDescription = ".BIZ";

        public dynamic PrepareEnvironment()
        {
            PrepareValidCombinations();

            return new
            {
                JurisdictionCode,
                JurisdictionDescription,
                PropertyTypeDescription,
                CategoryDescription
            };
        }

        void PrepareValidCombinations()
        {
            // Base Objects
            var jurisdiction = Insert(new Country(JurisdictionCode, JurisdictionDescription) { AllMembersFlag = 0, Type = "0" });
            var property = DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().First(_ => _.Code.Equals("P"));
            var category = DbContext.Set<CaseCategory>().First(_ => _.Name.Equals(CategoryDescription, StringComparison.CurrentCultureIgnoreCase));
            var caseType = DbContext.Set<CaseType>().First(_ => _.Code.Equals("A"));

            Insert(new ValidProperty
            {
                CountryId = jurisdiction.Id,
                PropertyTypeId = property.Code,
                PropertyName = PropertyTypeDescription
            });

            Insert(new ValidCategory(category, jurisdiction, caseType, property, category.Name));
        }
    }
}