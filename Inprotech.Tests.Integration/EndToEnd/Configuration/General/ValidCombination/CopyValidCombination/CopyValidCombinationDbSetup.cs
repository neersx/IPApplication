using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ValidCombination.CopyValidCombination
{
    class CopyValidCombinationDbSetup : DbSetup
    {
        public const string JurisdictionCode = "e2e";
        public const string JurisdictionDescription = "e2e - jurisdiction";
        public const string JurisdictionCode1 = "e3e";
        public const string JurisdictionDescription1 = "e3e - jurisdiction";
        public const string PropertyTypeDescription = "Patents";
        public const string CategoryDescription = ".BIZ";

        public dynamic PrepareEnvironment()
        {
            PrepareValidCombinations();

            return new
            {
                JurisdictionCode,
                JurisdictionCode1
            };
        }

        void PrepareValidCombinations()
        {
            // Base Objects
            var jurisdiction = Insert(new Country(JurisdictionCode, JurisdictionDescription) { AllMembersFlag = 0, Type = "0" });
            Insert(new Country(JurisdictionCode1, JurisdictionDescription1) { AllMembersFlag = 0, Type = "0" });
            var property = DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().First(_ => _.Code.Equals("P"));
            var category = DbContext.Set<CaseCategory>().First(_ => _.Name.Equals(CategoryDescription, StringComparison.CurrentCultureIgnoreCase));
            var caseType = DbContext.Set<CaseType>().First(_ => _.Code.Equals("A"));
            var action = DbContext.Set<InprotechKaizen.Model.Cases.Action>().First(_ => _.Code.Equals("CP"));
            var basis = DbContext.Set<ApplicationBasis>().First(_ => _.Code.Equals("Y"));
            var checklist = DbContext.Set<CheckList>().First(_ => _.Id.Equals(3));
            var relationship = DbContext.Set<CaseRelation>().First(_ => _.Relationship.Equals("AGR"));
            var status = DbContext.Set<InprotechKaizen.Model.Cases.Status>().First(_ => _.Id.Equals(-216));
            var subType = DbContext.Set<InprotechKaizen.Model.Cases.SubType>().First(_ => _.Code.Equals("5"));

            Insert(new ValidProperty
            {
                CountryId = jurisdiction.Id,
                PropertyTypeId = property.Code,
                PropertyName = PropertyTypeDescription
            });
            
            Insert(new ValidAction(jurisdiction.Id, property.Code, caseType.Code, action.Code));
            Insert(new ValidBasis(jurisdiction, property, basis));
            Insert(new ValidChecklist(jurisdiction, property,caseType, checklist));
            Insert(new ValidRelationship(jurisdiction, property, relationship));
            Insert(new ValidStatus(jurisdiction, property, caseType, status));
            var validCategory = Insert(new ValidCategory(category, jurisdiction, caseType, property, category.Name));
            Insert(new ValidSubType(validCategory, jurisdiction, caseType, property, subType));
        }
    }
}