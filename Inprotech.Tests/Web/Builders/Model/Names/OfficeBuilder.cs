using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Names
{
    public class OfficeBuilder : IBuilder<Office>
    {
        public int? Id { get; set; }
        public string Name { get; set; }

        public Office Build()
        {
            return new Office(
                              Id ?? Fixture.Integer(),
                              Name ?? Fixture.String("OfficeName")
                             );
        }
    }
}