using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Integration.EndToEnd.Components.Picklist
{
    public class PicklistDbSetup : DbSetup
    {
        public PickListFixture Setup()
        {
            var propertyType = InsertWithNewId(new PropertyType {Name = Fixture.String(5)});

            return new PickListFixture
            {
                PropertyType = propertyType.Name
            };
        }
    }

    public class PickListFixture
    {
        public string PropertyType { get; set; }
    }
}
