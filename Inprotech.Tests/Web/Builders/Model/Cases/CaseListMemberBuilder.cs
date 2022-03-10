using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CaseListMemberBuilder : IBuilder<CaseListMember>
    {
        public int? CaseId { get; set; }
        public bool IsPrimeCase { get; set; }

        public CaseListMember Build()
        {
            return new CaseListMember(Fixture.Integer(), CaseId ?? new CaseBuilder().Build().Id, IsPrimeCase);
        }
    }
}