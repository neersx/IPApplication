using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CasePropertyBuilder : IBuilder<CaseProperty>
    {
        public Case Case { get; set; }
        public Status Status { get; set; }
        public ApplicationBasis ApplicationBasis { get; set; }
        public int? RenewalType { get; set; }
        public CaseProperty Build()
        {
            var property = new CaseProperty(
                                            Case ?? new CaseBuilder().Build(),
                                            ApplicationBasis ?? new ApplicationBasisBuilder().Build(),
                                            Status ?? new StatusBuilder().Build()) {RenewalType = RenewalType};
            return property;
        }
    }
}