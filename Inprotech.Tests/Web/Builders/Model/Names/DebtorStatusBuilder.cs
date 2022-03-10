using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class DebtorStatusBuilder : IBuilder<DebtorStatus>
    {
        public string Status { get; set; }
        public short RestrictionAction { get; set; }
        public string ClearTextPassword { get; set; }

        public DebtorStatus Build()
        {
            return new DebtorStatus(Fixture.Short())
            {
                Status = Status ?? Fixture.String(),
                RestrictionType = RestrictionAction,
                ClearTextPassword = ClearTextPassword ?? Fixture.String()
            };
        }
    }
}