using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Offices
{
    public class OfficesDbSetup : DbSetup
    {
        public dynamic SetupOffices()
        {
            var o1 = new OfficeBuilder(DbContext).Create("E2e office 1");
            var o2 = InsertWithNewId(new Office(1111, "E2e office 2"));
            var o3 = new OfficeBuilder(DbContext).Create("E2e office 3");
            o1.Country = new CountryBuilder(DbContext).Create("E2e country");
            o1.UserCode = Fixture.String(3);
            o1.IrnCode = Fixture.String(3);
            return new
            {
                o1,
                o2,
                o3
            };
        }
    }
}
