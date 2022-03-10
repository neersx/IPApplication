using System;
using System.Collections.Generic;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Jurisdictions;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;
using InprotechKaizen.Model.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Jurisdictions.Maintenance
{

    public class CountryHolidayMaintenanceControllerFacts
    {
        const string CountryCode = "AF";

        public class CountryHolidayMaintenanceControllerFixture : IFixture<CountryHolidayMaintenanceController>
        {
            readonly InMemoryDbContext _db;
            public DateTime TodayDate;

            public CountryHolidayMaintenanceControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                TodayDate = DateTime.UtcNow;
                CountryHolidayMaintenance = Substitute.For<ICountryHolidayMaintenance>();

                Subject = new CountryHolidayMaintenanceController(CountryHolidayMaintenance);
            }

            public ICountryHolidayMaintenance CountryHolidayMaintenance { get; set; }

            public CountryHolidayMaintenanceController Subject { get; set; }

            public CountryHoliday PrepareData()
            {
                return new CountryHoliday(CountryCode, TodayDate) { HolidayName = "Public Holiday" }.In(_db);
            }

            public class SaveMethod : FactBase
            {
                [Fact]
                public void ShouldUpdateCountryHoliday()
                {
                    var f = new CountryHolidayMaintenanceControllerFixture(Db);
                   
                    f.CountryHolidayMaintenance.Save(Arg.Any<CountryHolidayMaintenanceModel>()).Returns(true);
                    var result = f.Subject.Save(new CountryHolidayMaintenanceModel());

                    Assert.True(result);
                }

            }
           
            public class DeleteMethod : FactBase
            {
                [Fact]
                public void ShouldReturnTrueOnDelete()
                {
                    var f = new CountryHolidayMaintenanceControllerFixture(Db);
                   
                    f.CountryHolidayMaintenance.Delete(Arg.Any<List<CountryHolidayMaintenanceModel>>()).Returns(true);
                    var models = new List<CountryHolidayMaintenanceModel> {new CountryHolidayMaintenanceModel()};
                    var result = f.Subject.Delete(models);

                    Assert.True(result);
                }

            }

            public class IsDuplicateMethod : FactBase
            {
                [Fact]
                public void ShouldReturnTrue()
                {
                    var f = new CountryHolidayMaintenanceControllerFixture(Db);

                    f.CountryHolidayMaintenance.IsDuplicate(Arg.Any<CountryHolidayMaintenanceModel>()).Returns(true);
                    var result = f.Subject.IsDuplicate(new CountryHolidayMaintenanceModel());

                    Assert.True(result);
                }

            }
        }
    }
}
