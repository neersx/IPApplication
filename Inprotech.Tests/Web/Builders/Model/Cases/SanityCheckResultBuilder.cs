using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class SanityCheckResultBuilder : IBuilder<SanityCheckResult>
    {
        public int CaseId { get; set; }

        public SanityCheckResult Build()
        {
            return new SanityCheckResult
            {
                Id = Fixture.Integer(),
                ProcessId = Fixture.Integer(),
                CaseId = CaseId,
                IsWarning = false,
                CanOverride = false,
                DisplayMessage = "Sanity Check Result"
            };
        }
    }
}