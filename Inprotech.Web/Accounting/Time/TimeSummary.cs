using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.Accounting.Time;

namespace Inprotech.Web.Accounting.Time
{
    public interface ITimeSummaryProvider
    {
        Task<(TimeSummary summary, int count)> Get(IQueryable<TimeEntry> query);
    }

    public class TimeSummaryProvider : ITimeSummaryProvider
    {
        readonly ISiteControlReader _siteControlReader;

        public TimeSummaryProvider(ISiteControlReader siteControlReader)
        {
            _siteControlReader = siteControlReader;
        }

        public async Task<(TimeSummary summary, int count)> Get(IQueryable<TimeEntry> query)
        {
            var data = await Task.FromResult( query.Select(_ => new
            {
                _.LocalValue,
                _.LocalDiscount,
                _.TimeCarriedForward,
                _.TotalUnits,
                _.TotalTime
            }).ToList());

            var entries = data.Select(_ => new TimeEntry
            {
                LocalValue = _.LocalValue,
                LocalDiscount = _.LocalDiscount,
                TimeCarriedForward = _.TimeCarriedForward,
                TotalUnits = _.TotalUnits,
                TotalTime = _.TotalTime
            }).ToArray();

            if (!entries.Any()) return (new TimeSummary(), 0);

            var hoursPerDay = _siteControlReader.Read<decimal>(SiteControls.StandardDailyHours);
            var chargeableTime = ChargeableTime(entries);
            var chargeablePercentage = GetChargeablePercentage(chargeableTime, hoursPerDay);

            return (new TimeSummary
            {
                ChargeableSeconds = chargeableTime,
                ChargeableUnits = GetChargeableUnits(entries),
                ChargeablePercentage = chargeablePercentage,
                TotalHours = entries.Sum(_ => _.SecondsCarriedForward != null ? _.SecondsCarriedForward.GetValueOrDefault() + _.ElapsedTimeInSeconds.GetValueOrDefault() : _.ElapsedTimeInSeconds.GetValueOrDefault()),
                TotalValue = entries.Sum(_ => _.LocalValue.GetValueOrDefault()),
                TotalUnits = entries.Sum(_ => (int) _.TotalUnits.GetValueOrDefault()),
                TotalDiscount = entries.Sum(_ => _.LocalDiscount.GetValueOrDefault())
            }, entries.Length);
        }

        int ChargeableTime(TimeEntry[] entries)
        {
            return entries.Where(_ => _.LocalValue.HasValue && _.LocalValue > 0)
                          .Select(_ => _.SecondsCarriedForward != null ? _.SecondsCarriedForward.GetValueOrDefault() + _.ElapsedTimeInSeconds.GetValueOrDefault() : _.ElapsedTimeInSeconds.GetValueOrDefault())
                          .Aggregate(0, (total, item) => total + item);
        }

        int GetChargeableUnits(TimeEntry[] entries)
        {
            var units = entries.Where(_ => _.LocalValue.HasValue && _.LocalValue > 0)
                               .Select(_ => _.TotalUnits.GetValueOrDefault())
                               .Aggregate((decimal) 0, (total, item) => total + item);
            return (int) units;
        }

        decimal GetChargeablePercentage(int chargeableTime, decimal hours)
        {
            return Math.Round(chargeableTime > 0 ? chargeableTime / (hours == 0 ? 28800 : hours * 3600) * 100 : 0, MidpointRounding.AwayFromZero);
        }
    }

    public class TimeSummary
    {
        public int? ChargeableSeconds { get; set; }
        public decimal? ChargeablePercentage { get; set; }
        public int? ChargeableUnits { get; set; }
        public int? TotalHours { get; set; }
        public decimal? TotalValue { get; set; }
        public int? TotalUnits { get; set; }
        public decimal? TotalDiscount { get; set; }
    }
}