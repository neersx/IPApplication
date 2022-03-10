using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Web.Builders.Model.ValidCombinations
{
    public class ValidStatusBuilder : IBuilder<ValidStatus>
    {
        public Status Status { get; set; }
        public CaseType CaseType { get; set; }
        public Country Country { get; set; }
        public PropertyType PropertyType { get; set; }

        public ValidStatus Build()
        {
            return new ValidStatus(
                                   Country ?? new CountryBuilder().Build(),
                                   PropertyType ?? new PropertyTypeBuilder().Build(),
                                   CaseType ?? new CaseTypeBuilder().Build(),
                                   Status ?? new StatusBuilder().Build());
        }
    }
}