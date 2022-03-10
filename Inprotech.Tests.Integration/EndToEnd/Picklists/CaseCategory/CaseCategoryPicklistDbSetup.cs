using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.CaseCategory
{
    class CaseCategoryPicklistDbSetup
    {
        public const string CaseCategoryPrefix = "e2e - casecategory";
        public const string ExistingCaseType = "B";
        public const string ExistingCaseCategory = CaseCategoryPrefix + " existing";
        public const string ExistingCaseCategory2 = ExistingCaseCategory + "2";
        public const string ExistingCaseCategory3 = ExistingCaseCategory + "3";
        public const string CaseCategoryToBeAdded = CaseCategoryPrefix + " add";
        public CaseCategoryPicklistDbSetup()
        {
            DbContext = new SqlDbContext();
        }

        public IDbContext DbContext { get; }

        public ScenarioData Prepare()
        {
            var existingCaseCategory = AddCaseCategory(ExistingCaseType,"1",ExistingCaseCategory);
            AddCaseCategory(ExistingCaseType, "2", ExistingCaseCategory2);
            AddCaseCategory(ExistingCaseType, "3", ExistingCaseCategory3);

            return new ScenarioData
            {
                CaseCategoryCode = existingCaseCategory.CaseCategoryId,
                CaseCategoryName = existingCaseCategory.Name,
                CaseType = existingCaseCategory.CaseTypeId,
                ExistingApplicationCaseCategory = existingCaseCategory
            };
        }

        public InprotechKaizen.Model.Cases.CaseCategory AddCaseCategory(string caseTypeId,string caseCategoryCode, string caseCategoryDesc)
        {
            var caseCategory = DbContext.Set<InprotechKaizen.Model.Cases.CaseCategory>().FirstOrDefault(_ => _.Name == caseCategoryDesc);
            if (caseCategory != null)
                return caseCategory;

            caseCategory = new InprotechKaizen.Model.Cases.CaseCategory(caseTypeId, caseCategoryCode, caseCategoryDesc);

            DbContext.Set<InprotechKaizen.Model.Cases.CaseCategory>().Add(caseCategory);
            DbContext.SaveChanges();

            return caseCategory;
        }

        public void AddValidCaseCategory(InprotechKaizen.Model.Cases.CaseCategory caseCategory)
        {
            var country = DbContext.Set<Country>().FirstOrDefault();
            var propertyType = DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().FirstOrDefault();
            var caseType = DbContext.Set<InprotechKaizen.Model.Cases.CaseType>().Single(_ => _.Code == "B");
            var validCaseCategory = new ValidCategory(caseCategory, country, caseType, propertyType, caseCategory.Name);

            DbContext.Set<ValidCategory>().Add(validCaseCategory);
            DbContext.SaveChanges();
        }

        public class ScenarioData
        {
            public string CaseCategoryCode;
            public string CaseCategoryName;
            public string CaseType;
            public InprotechKaizen.Model.Cases.CaseCategory ExistingApplicationCaseCategory;
        }
    }
}
