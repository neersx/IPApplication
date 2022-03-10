using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class ApplicationBasisBuilder : IBuilder<ApplicationBasis>
    {
        public string Id { get; set; }
        public string Name { get; set; }

        public ApplicationBasis Build()
        {
            return new ApplicationBasis(
                                        Id ?? Fixture.String(),
                                        Name ?? Fixture.String());
        }
    }
}