using System;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingRequestDateCalculatorFacts : FactBase
    {
        public class PolicingRequestDateCalculatorFixture : IFixture<IPolicingRequestDateCalculator>
        {
            readonly InMemoryDbContext _db;
            readonly ISiteConfiguration _siteConfiguration;
            readonly ISiteControlReader _siteControlReader;

            public PolicingRequestDateCalculatorFixture(InMemoryDbContext db)
            {
                _db = db;
                _siteConfiguration = Substitute.For<ISiteConfiguration>();
                _siteControlReader = Substitute.For<ISiteControlReader>();
                Subject = new PolicingRequestDateCalculator(_db, _siteConfiguration, _siteControlReader);
            }

            public IPolicingRequestDateCalculator Subject { get; }

            public PolicingRequestDateCalculatorFixture WithLettersAfterDays(int days = 1)
            {
                _siteControlReader.Read<int>(SiteControls.LETTERSAFTERDAYS).Returns(days);
                return this;
            }

            public PolicingRequestDateCalculatorFixture WithDefaultCountry()
            {
                var country = new Country
                {
                    Name = "Australia",
                    Id = "AU",
                    WorkDayFlag = 124
                };
                _siteConfiguration.HomeCountry().Returns(country);
                return this;
            }

            public PolicingRequestDateCalculatorFixture WithHolidays(DateTime holidayDate)
            {
                new CountryHoliday {CountryId = "AU", HolidayDate = holidayDate}.In(_db);
                return this;
            }
        }

        [Fact]
        public void ShouldGetNextLetterDate()
        {
            var f = new PolicingRequestDateCalculatorFixture(Db).WithLettersAfterDays().WithDefaultCountry();
            var r = f.Subject.GetLettersDate(Fixture.Monday);
            Assert.Equal(r, Fixture.Tuesday);
        }

        [Fact]
        public void ShouldSkipHolidays()
        {
            var f = new PolicingRequestDateCalculatorFixture(Db).WithLettersAfterDays().WithDefaultCountry().WithHolidays(Fixture.From(DayOfWeek.Thursday));
            var r = f.Subject.GetLettersDate(Fixture.From(DayOfWeek.Wednesday));
            Assert.Equal(r, Fixture.From(DayOfWeek.Friday));
        }

        [Fact]
        public void ShouldSkipHolidaysAndWeekends()
        {
            var f = new PolicingRequestDateCalculatorFixture(Db).WithLettersAfterDays(2).WithDefaultCountry().WithHolidays(Fixture.From(DayOfWeek.Friday));
            var r = f.Subject.GetLettersDate(Fixture.From(DayOfWeek.Wednesday));
            Assert.Equal(r, Fixture.From(DayOfWeek.Friday).AddDays(3));
        }

        [Fact]
        public void ShouldSkipWeekends()
        {
            var f = new PolicingRequestDateCalculatorFixture(Db).WithLettersAfterDays().WithDefaultCountry();
            var r = f.Subject.GetLettersDate(Fixture.From(DayOfWeek.Friday));
            Assert.Equal(r, Fixture.From(DayOfWeek.Friday).AddDays(3));
        }
    }
}