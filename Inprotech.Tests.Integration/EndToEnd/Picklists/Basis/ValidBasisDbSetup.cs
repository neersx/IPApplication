using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using System.Linq;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Basis
{
    class ValidBasisDbSetup : DbSetup
    {
        public const string PropertyTypePrefix = "e2e - valid property type";
        public const string CaseTypePrefix = "e2e - case type";
        public const string CaseCategoryPrefix = "e2e - valid case category type";
        public const string BasisPrefix = "e2e - valid basis";
        internal const string JurisdictionDescription = "e2e - jurisdiction";
        internal const string CaseTypeDescription = CaseTypePrefix;
        internal const string ValidPropertyTypeDescription = PropertyTypePrefix;
        internal const string ValidCaseCategoryDescription = CaseCategoryPrefix;
        internal const string ValidBasisDescription = BasisPrefix;
        internal const string ValidBasisEdited = BasisPrefix + " edited";
        internal const string DuplicateValidBasis = BasisPrefix + " duplicate";

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

            if (!DbContext.Set<InprotechKaizen.Model.Cases.CaseType>().Any(_ => _.Name == CaseTypeDescription))
                DbContext.Set<InprotechKaizen.Model.Cases.CaseType>().Add(new InprotechKaizen.Model.Cases.CaseType("@", CaseTypeDescription));

            if (!DbContext.Set<InprotechKaizen.Model.Cases.CaseCategory>().Any(_ => _.Name == ValidCaseCategoryDescription))
                DbContext.Set<InprotechKaizen.Model.Cases.CaseCategory>().Add(new InprotechKaizen.Model.Cases.CaseCategory("@", "e2", ValidCaseCategoryDescription));

            if (!DbContext.Set<ApplicationBasis>().Any(_ => _.Name == ValidBasisDescription))
                DbContext.Set<ApplicationBasis>().Add(new ApplicationBasis("e2", ValidBasisDescription));

            if (!DbContext.Set<ApplicationBasis>().Any(_ => _.Name == DuplicateValidBasis))
                DbContext.Set<ApplicationBasis>().Add(new ApplicationBasis("e3", DuplicateValidBasis));

            DbContext.SaveChanges();

            Insert(new ValidProperty
            {
                CountryId = "e2e",
                PropertyTypeId = "_",
                PropertyName = ValidPropertyTypeDescription
            });

            Insert(new ValidCategory
            {
                CountryId = "e2e",
                PropertyTypeId = "_",
                CaseTypeId = "@",
                CaseCategoryId = "e2",
                CaseCategoryDesc = ValidCaseCategoryDescription
            });

            DbContext.SaveChanges();
        }

    }
}
