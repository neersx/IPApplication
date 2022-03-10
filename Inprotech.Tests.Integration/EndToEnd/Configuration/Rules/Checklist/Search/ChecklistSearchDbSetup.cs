using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Checklist.Search
{
    internal class ChecklistSearchDbSetup : DbSetup
    {
        const string ValidPropertyTypeDescription = "e2e - valid property type";
        const string ValidChecklistDescription = "e2e - valid checklist";

        public ChecklistSearchData SetUp()
        {
            var office = InsertWithNewId(new Office { Name = "e2e-" + Fixture.AlphaNumericString(10) });
            var caseType = InsertWithNewId(new CaseType { Name = "e2e-caseType" }, x => x.Code, useAlphaNumeric: true);
            var propertyType = InsertWithNewId(new PropertyType { Name = "e2e-propertyType" }, x => x.Code, useAlphaNumeric: true);
            var jurisdiction = InsertWithNewId(new Country { Name = "e2e-country", Type = "1" }, x => x.Id, useAlphaNumeric: true);
            var caseCategory = InsertWithNewId(new CaseCategory { Name = "e2e-caseCategory", CaseType = caseType }, x => x.CaseCategoryId, useAlphaNumeric: true, maxLength: 2);
            var subType = InsertWithNewId(new SubType { Name = "e2e-subType" }, x => x.Code, useAlphaNumeric: true);
            var basis = InsertWithNewId(new ApplicationBasis { Name = "e2e-basis" }, x => x.Code, useAlphaNumeric: true);
            var checklist = InsertWithNewId(new CheckList { Description = "e2e-checklist" }, x => x.Id);
            var question = InsertWithNewId(new Question {QuestionString = "e2e-question"}, x => x.Id);
            var deleteQuestion = InsertWithNewId(new Question {QuestionString = "e2e-delete-question"}, x => x.Id);
            if (!DbContext.Set<ValidProperty>().Any(_ => _.PropertyName == ValidPropertyTypeDescription))
            {
                DbContext.Set<ValidProperty>().Add(new ValidProperty
                {
                    CountryId = jurisdiction.Id,
                    PropertyTypeId = propertyType.Code,
                    PropertyName = ValidPropertyTypeDescription
                });
            }
            if (!DbContext.Set<ValidChecklist>().Any(_ => _.ChecklistDescription == ValidChecklistDescription))
            {
                DbContext.Set<ValidChecklist>().Add(new ValidChecklist(jurisdiction, propertyType, caseType, checklist.Id, ValidChecklistDescription));
            }
            var firstCriteria = InsertWithNewId(new Criteria
            {
                Description = Fixture.Prefix("with-caseType"),
                PurposeCode = CriteriaPurposeCodes.CheckList,
                ChecklistType = checklist.Id,
                CaseTypeId = caseType.Code,
                RuleInUse = 1,
                IsProtected = false
            });
            var secondCriteria = InsertWithNewId(new Criteria
            {
                Description = Fixture.Prefix("with-caseType-and-propertyType"),
                PurposeCode = CriteriaPurposeCodes.CheckList,
                ChecklistType = checklist.Id,
                CaseTypeId = caseType.Code,
                CountryId = jurisdiction.Id,
                RuleInUse = 1,
                IsProtected = false
            });
            if (!DbContext.Set<ChecklistItem>().Any(_ => _.CriteriaId == firstCriteria.Id && _.QuestionId == question.Id))
            {
                DbContext.Set<ChecklistItem>().Add(new ChecklistItem { Criteria = firstCriteria, QuestionId = question.Id, Question = Fixture.String(10)});
            }
            DbContext.SaveChanges();
            var @case = new CaseBuilder(DbContext).Create("e2e", true, null, jurisdiction, propertyType);
            return new ChecklistSearchData
            {
                Office = office,
                CaseType = caseType,
                PropertyType = propertyType,
                Jurisdiction = jurisdiction,
                CaseCategory = caseCategory,
                SubType = subType,
                Basis = basis,
                ValidPropertyType = ValidPropertyTypeDescription,
                ValidChecklist = ValidChecklistDescription,
                Case = @case,
                Criteria1 = firstCriteria,
                Criteria2 = secondCriteria,
                Question = question,
                DeleteQuestion = deleteQuestion
            };
        }
    }

    public class ChecklistSearchData
    {
        public Office Office { get; set; }
        public CaseType CaseType { get; set; }
        public Country Jurisdiction { get; set; }
        public PropertyType PropertyType { get; set; }
        public CaseCategory CaseCategory { get; set; }
        public SubType SubType { get; set; }
        public ApplicationBasis Basis { get; set; }
        public string ValidPropertyType { get; set; }
        public string ValidChecklist { get; set; }
        public Case Case { get; set; }
        public Criteria Criteria1 { get; set; }
        public Criteria Criteria2 { get; set; }
        public Question Question { get; set; }
        public Question DeleteQuestion { get; set; }
    }
}