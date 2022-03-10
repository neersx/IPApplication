using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Web.Builders.Model.ValidCombinations
{
    public class ValidCategoryBuilder : IBuilder<ValidCategory>
    {
        public CaseCategory CaseCategory { get; set; }
        public CaseType CaseType { get; set; }
        public Country Country { get; set; }
        public PropertyType PropertyType { get; set; }
        public string CaseCategoryDesc { get; set; }

        public ValidCategory Build()
        {
            return new ValidCategory(
                                     CaseCategory ?? new CaseCategoryBuilder().Build(),
                                     Country ?? new CountryBuilder().Build(),
                                     CaseType ?? new CaseTypeBuilder().Build(),
                                     PropertyType ?? new PropertyTypeBuilder().Build(),
                                     CaseCategoryDesc =
                                         CaseCategoryDesc ?? (CaseCategory != null ? CaseCategory.Name : Fixture.String("ValidCaseCategory")));
        }
    }
}