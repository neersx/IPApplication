using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Jurisdictions.Maintenance;
using InprotechKaizen.Model.Cases;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Jurisdictions.Maintenance
{
    public class CountryHolidayMaintenanceFacts
    {
        public const string TopicName = "businessDays";
        const string CountryCode = "AF";

        public class CountryHolidayMaintenanceFixture : IFixture<CountryHolidayMaintenance>
        {
            readonly InMemoryDbContext _db;
            public DateTime TodayDate;

            public CountryHolidayMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;
                TodayDate = DateTime.UtcNow;
                Subject = new CountryHolidayMaintenance(db);
            }

            public CountryHolidayMaintenance Subject { get; set; }

            public CountryHoliday PrepareData()
            {
                return new CountryHoliday(CountryCode, TodayDate) { HolidayName = "Public Holiday" }.In(_db);
            }
        }

        public class ValidateMethod : FactBase
        {
            [Fact]
            public void ShouldGiveDuplicateHolidayDateErrorOnValidate()
            {
                var f = new CountryHolidayMaintenanceFixture(Db);
                f.PrepareData();
                var countryModel = new CountryHolidayMaintenanceModel {CountryId = CountryCode, Holiday = "Public Holiday", HolidayDate = f.TodayDate};
                
                var errors = f.Subject.Validate(countryModel).ToArray();

                Assert.Single(errors);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == "Duplicate Holiday Date.");
            }

            [Fact]
            public void ShouldGiveRequiredFieldMessageIfMandatoryHolidayNameNotProvided()
            {
                var f = new CountryHolidayMaintenanceFixture(Db);
                f.PrepareData();
                var countryModel = new CountryHolidayMaintenanceModel { CountryId = CountryCode, Holiday = string.Empty };
               
                var errors = f.Subject.Validate(countryModel).ToArray();

                Assert.Single(errors);
                Assert.Contains(errors, v => v.Topic == TopicName);
                Assert.Contains(errors, v => v.Message == "Mandatory field Holiday was empty.");
            }
        }

        public class SaveUpdateMethod : FactBase
        {
            [Fact]
            public void ShouldUpdateCountryHoliday()
            {
                var f = new CountryHolidayMaintenanceFixture(Db);
                var countryHoliday = f.PrepareData();

                var date = DateTime.UtcNow.AddDays(2);
                var countryHolidayMaintenanceModel = new CountryHolidayMaintenanceModel
                {
                    Id = countryHoliday.Id,
                    CountryId = countryHoliday.CountryId,
                    HolidayDate = date,
                    Holiday = "Updated Holiday"
                };

                f.Subject.Save(countryHolidayMaintenanceModel);

                var record = Db.Set<CountryHoliday>().First(_ => _.Id == countryHoliday.Id);

                Assert.NotNull(record);

                Assert.Equal(record.CountryId, CountryCode);
                Assert.Equal(record.HolidayDate, date);
                Assert.Equal("Updated Holiday", record.HolidayName);
            }

            [Fact]
            public void ShouldAddCountryHoliday()
            {
                var f = new CountryHolidayMaintenanceFixture(Db);
                f.PrepareData();
                
                var countryHolidayMaintenanceModel = new CountryHolidayMaintenanceModel
                {
                    CountryId = CountryCode,
                    HolidayDate = DateTime.UtcNow.AddDays(1),
                    Holiday = "New Public Holiday"
                };

                f.Subject.Save(countryHolidayMaintenanceModel);

                var total = Db.Set<CountryHoliday>().Where(_ => _.CountryId == CountryCode).ToList();
                Assert.Equal(2, total.Count);

                var record = Db.Set<CountryHoliday>().First(_ => _.HolidayName == "New Public Holiday" && _.CountryId == CountryCode);

                Assert.Equal(record.CountryId, CountryCode);
                Assert.Equal("New Public Holiday", record.HolidayName);
            }

            [Fact]
            public void ShouldDeleteExistingCountryHoliday()
            {
                var f = new CountryHolidayMaintenanceFixture(Db);
                var countryHoliday = f.PrepareData();

                var countryHolidayMaintenanceModels = new List<CountryHolidayMaintenanceModel> {new CountryHolidayMaintenanceModel {Id = countryHoliday.Id, CountryId = CountryCode}};

                f.Subject.Delete(countryHolidayMaintenanceModels);

                var totalTableState = Db.Set<CountryHoliday>();
                Assert.Empty(totalTableState);
            }
        }
    }
}