using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CaseCategoryBuilder : IBuilder<CaseCategory>
    {
        public string CaseTypeId { get; set; }
        public string CaseCategoryId { get; set; }
        public string Name { get; set; }

        public CaseCategory Build()
        {
            return new CaseCategory(
                                    CaseTypeId ?? Fixture.String(),
                                    CaseCategoryId ?? Fixture.String(),
                                    Name ?? Fixture.String()
                                   );
        }
    }
}