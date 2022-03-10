using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Web.Builders.Model.ValidCombinations
{
    public class ValidBasisExBuilder : IBuilder<ValidBasisEx>
    {
        public CaseCategory CaseCategory { get; set; }
        public CaseType CaseType { get; set; }
        public ValidBasis ValidBasis { get; set; }

        public ValidBasisEx Build()
        {
            return new ValidBasisEx(
                                    CaseType ?? new CaseTypeBuilder().Build(),
                                    CaseCategory ?? new CaseCategoryBuilder().Build(),
                                    ValidBasis ?? new ValidBasisBuilder().Build());
        }
    }
}