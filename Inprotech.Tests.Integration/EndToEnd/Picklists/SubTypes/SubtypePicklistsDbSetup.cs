using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.SubTypes
{
    class SubtypePicklistsDbSetup
    {
        public const string SubTypesPrefix = "e2e - subtype";
        public const string ExistingSubtype = SubTypesPrefix + " existing";
        public const string ExistingSubTypes2 = SubTypesPrefix + "2";
        public const string ExistingSubTypes3 = SubTypesPrefix + "3";
        public const string SubTypesToBeAdded = SubTypesPrefix + " add";

        public SubtypePicklistsDbSetup()
        {
            DbContext = new SqlDbContext();
        }

        public IDbContext DbContext { get; }

        public ScenarioData Prepare()
        {
            var existingSubTypes = AddSubTypes("1", ExistingSubtype);
            var existingSubTypes2 = AddSubTypes("2", ExistingSubTypes2);
            AddSubTypes("3", ExistingSubTypes3);

            return new ScenarioData
                   {
                       PrefixSubTypes = SubTypesPrefix,
                       SubTypesId = existingSubTypes.Code,
                       SubTypesName = existingSubTypes.Name,
                       ExistingSubType = existingSubTypes,
                       ExistingSubType2 = existingSubTypes2
                   };
        }

        public SubType AddSubTypes(string id, string name)
        {
            var subTypes = DbContext.Set<SubType>().FirstOrDefault(_ => _.Code == id);
            if (subTypes != null)
                return subTypes;

            subTypes = new SubType(id, name);

            DbContext.Set<SubType>().Add(subTypes);
            DbContext.SaveChanges();

            return subTypes;
        }

        public SubType CreateValidSubTypeCombination(SubType subType)
        {
            var country = DbContext.Set<Country>().FirstOrDefault();
            var propertyType = DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().FirstOrDefault();
            var caseCategory = DbContext.Set<InprotechKaizen.Model.Cases.CaseCategory>().FirstOrDefault();
            var validCategory = DbContext.Set<ValidCategory>().SingleOrDefault(_ => _.CaseCategoryId == caseCategory.CaseCategoryId && _.Country.Id == country.Id && _.CaseTypeId == caseCategory.CaseTypeId && _.PropertyType.Code == propertyType.Code)
                                ?? new ValidCategory(caseCategory, country, caseCategory.CaseType, propertyType, "e2e vc");
            var validSubType = new ValidSubType(validCategory, country, caseCategory.CaseType, propertyType, subType);
            DbContext.Set<ValidSubType>().Add(validSubType);
            DbContext.SaveChanges();
            return validSubType?.SubType;
        }

        public class ScenarioData
        {
            public SubType ExistingSubType;
            public SubType ExistingSubType2;
            public string PrefixSubTypes;
            public string SubTypesId;
            public string SubTypesName;
        }
    }
}