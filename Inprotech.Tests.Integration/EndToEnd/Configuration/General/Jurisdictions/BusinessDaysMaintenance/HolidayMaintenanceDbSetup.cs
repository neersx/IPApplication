using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions.BusinessDaysMaintenance
{
    public class HolidayMaintenanceDbSetUp : DbSetup
    {
        const string CountryCode = "h01";
        const string CountryName = "h01-country";

        public CountryHoliday CountryHolidayToBeAdded;

        public ScenarioData Prepare()
        {
            var nameStyleId = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int) TableTypes.NameStyle).Id;
            var addressStyleId = DbContext.Set<TableCode>().First(_ => _.TableTypeId == (int) TableTypes.AddressStyle).Id;

            DbContext.Set<Country>().Add(new Country(CountryCode, CountryName, "0") {PostalName = "h01h01", NameStyleId = nameStyleId, AddressStyleId = addressStyleId});
            DbContext.SaveChanges();
            CountryHolidayToBeAdded = new CountryHoliday(CountryCode, DateTime.UtcNow.AddDays(2)) {HolidayName = "new public holiday"};

            return new ScenarioData
            {
                CountryCode = CountryCode,
                CountryName = CountryName,
                CountryHolidayToBeAdded = CountryHolidayToBeAdded,
                UpdatedHolidayName = "Updated Holiday"
            };
        }

        public class ScenarioData
        {
            public string CountryCode { get; set; }
            public string CountryName { get; set; }
            public CountryHoliday CountryHolidayToBeAdded { get; set; }

            public string UpdatedHolidayName { set; get; }
        }
    }
}