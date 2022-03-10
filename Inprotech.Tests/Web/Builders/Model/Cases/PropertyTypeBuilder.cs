using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class PropertyTypeBuilder : IBuilder<PropertyType>
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public decimal AllowSubClass { get; set; }

        public PropertyType Build()
        {
            return new PropertyType(Id ?? Fixture.String("Id"), Name ?? Fixture.String("Name"))
            {
                AllowSubClass = AllowSubClass
            };
        }
    }
}