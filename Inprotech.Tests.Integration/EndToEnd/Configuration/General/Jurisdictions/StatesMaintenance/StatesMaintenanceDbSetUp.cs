using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.StatesMaintenance
{
    class StatesMaintenanceDbSetUp : DbSetup
    {
        public const string CountryCode1 = "c01";
        public const string CountryName1 = "c01 - country";

        public void Prepare()
        {
            var nameStyleId = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int)TableTypes.NameStyle).Id;
            var addressStyleId = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int)TableTypes.AddressStyle).Id;
            var country = new Country(CountryCode1, CountryName1, "0") { PostalName = "c05c05", NameStyleId = nameStyleId, AddressStyleId = addressStyleId };
            DbContext.Set<Country>().Add(country);
            DbContext.Set<Address>().Add(new Address { Id = -300, City = "Kabul", Street1 = "Kabul Street", State = "InUse", Country = country, PostCode = "2000" });

            DbContext.SaveChanges();
        }
    }
}