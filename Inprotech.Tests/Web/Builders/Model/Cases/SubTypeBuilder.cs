using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class SubTypeBuilder : IBuilder<SubType>
    {
        public string Id { get; set; }
        public string Name { get; set; }

        public SubType Build()
        {
            return new SubType(
                               Id ?? Fixture.String(),
                               Name ?? Fixture.String()
                              );
        }
    }
}