using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CaseTypeBuilder : IBuilder<CaseType>
    {
        public string Id { get; set; }
        public string Name { get; set; }

        public string ActualCaseTypeId { get; set; }
        public string Code { get; internal set; }
        public int? Program { get; set; }

        public CaseType Build()
        {
            return new CaseType(Id ?? Fixture.String("Id"), Name ?? Fixture.String("Name")) { ActualCaseTypeId = ActualCaseTypeId, Program = Program };
        }
    }
}