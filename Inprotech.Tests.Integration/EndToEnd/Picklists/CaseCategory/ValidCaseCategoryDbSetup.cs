using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using System.Linq;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.CaseCategory
{
    class ValidCaseCategoryDbSetup : DbSetup
    {
        public const string PropertyTypePrefix = "e2e - valid property type";
        public const string CaseTypePrefix = "e2e - case type";
        public const string CaseCategoryPrefix = "e2e - valid case category type";
        internal const string JurisdictionDescription = "e2e - jurisdiction";
        internal const string CaseTypeDescription = CaseTypePrefix;
        internal const string ValidPropertyTypeDescription = PropertyTypePrefix;
        internal const string ValidCaseCategoryDescription = CaseCategoryPrefix;
        internal const string ValidCaseCategoryeEdited = CaseCategoryPrefix + " edited";
        internal const string DuplicateValidCaseCategory = CaseCategoryPrefix + " duplicate";

        public void Prepare()
        {
            PrepareValidCharacteristics();
        }

        void PrepareValidCharacteristics()
        {
            if (DbContext == null) return;

            if (!DbContext.Set<Country>().Any(_ => _.Name == JurisdictionDescription))
                DbContext.Set<Country>().Add(new Country("e2e", JurisdictionDescription, "0") { AllMembersFlag = 0 });

            if (!DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().Any(_ => _.Name == ValidPropertyTypeDescription))
                DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().Add(new InprotechKaizen.Model.Cases.PropertyType("_", ValidPropertyTypeDescription));

            if (!DbContext.Set<InprotechKaizen.Model.Cases.CaseType>().Any(_ => _.Name == ValidPropertyTypeDescription))
                DbContext.Set<InprotechKaizen.Model.Cases.CaseType>().Add(new InprotechKaizen.Model.Cases.CaseType("@", CaseTypeDescription));

            if (!DbContext.Set<InprotechKaizen.Model.Cases.CaseCategory>().Any(_ => _.Name == ValidCaseCategoryDescription))
                DbContext.Set<InprotechKaizen.Model.Cases.CaseCategory>().Add(new InprotechKaizen.Model.Cases.CaseCategory("@", "e2", ValidCaseCategoryDescription));

            if (!DbContext.Set<InprotechKaizen.Model.Cases.CaseCategory>().Any(_ => _.Name == DuplicateValidCaseCategory))
                DbContext.Set<InprotechKaizen.Model.Cases.CaseCategory>().Add(new InprotechKaizen.Model.Cases.CaseCategory("@", "e3", DuplicateValidCaseCategory));

            DbContext.SaveChanges();

            Insert(new ValidProperty
            {
                CountryId = "e2e",
                PropertyTypeId = "_",
                PropertyName = ValidPropertyTypeDescription
            });

            DbContext.SaveChanges();
        }

    }
}
