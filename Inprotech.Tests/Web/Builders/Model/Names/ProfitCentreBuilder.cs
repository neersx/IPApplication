using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class ProfitCentreBuilder : IBuilder<ProfitCentre>
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public Name Entity { get; set; }

        public ProfitCentre Build()
        {
            return new ProfitCentre(
                              Id ?? Fixture.String(),
                              Name ?? Fixture.String(),
                              Entity?? new Name()
                             );
        }
    }
}