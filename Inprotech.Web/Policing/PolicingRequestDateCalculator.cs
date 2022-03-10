using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Policing
{
    public interface IPolicingRequestDateCalculator
    {
        DateTime GetLettersDate(DateTime startDate);
    }

    internal class PolicingRequestDateCalculator : IPolicingRequestDateCalculator
    {
        readonly IDbContext _dbContext;
        readonly ISiteConfiguration _siteConfiguration;
        readonly ISiteControlReader _siteControlReader;

        public PolicingRequestDateCalculator(IDbContext dbContext, ISiteConfiguration siteConfiguration, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _siteConfiguration = siteConfiguration;
            _siteControlReader = siteControlReader;
        }

        public DateTime GetLettersDate(DateTime startDate)
        {
            var lettersAfterDays = _siteControlReader.Read<int>(SiteControls.LETTERSAFTERDAYS);
            var letterDate = startDate.Date.AddDays(lettersAfterDays);
            var country = _siteConfiguration.HomeCountry();
            var holidays = _dbContext.Set<CountryHoliday>().Where(_ => _.CountryId == country.Id).ToList();
            while ((holidays.Find(_ => _.HolidayDate == letterDate) != null) || IsWeekend(country.WorkDayFlag.GetValueOrDefault(), letterDate))
                letterDate = letterDate.AddDays(1);
            return letterDate;
        }

        bool IsWeekend(int workDayFlag, DateTime date)
        {
            var offDays = GetOffDays(workDayFlag);
            if (offDays.Count == 7)
                return (date.DayOfWeek == DayOfWeek.Saturday) || (date.DayOfWeek == DayOfWeek.Sunday);

            return offDays.Contains(date.DayOfWeek);
        }

        List<DayOfWeek> GetOffDays(int workDayFlag)
        {
            var flags = new Dictionary<DayOfWeek, int>
                        {
                            {DayOfWeek.Saturday, 1},
                            {DayOfWeek.Sunday, 2},
                            {DayOfWeek.Monday, 4},
                            {DayOfWeek.Tuesday, 8},
                            {DayOfWeek.Wednesday, 16},
                            {DayOfWeek.Thursday, 32},
                            {DayOfWeek.Friday, 64}
                        };
            return flags.Where(_ => (workDayFlag & _.Value) == 0).Select(_ => _.Key).ToList();
        }
    }
}