using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Web.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Time;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class TimeSummaryProviderFacts
    {
        public class GetMethod : FactBase
        {
            [Fact]
            public async Task RetrievesTimesheetSettings()
            {
                var f = new TimeSummaryProviderFixture();
                await f.Subject.Get(f.TimeEntries.AsQueryable());
                f.SiteControlReader.Received(1).Read<decimal>(SiteControls.StandardDailyHours);
            }

            [Fact]
            public async Task ReturnsChargeableTotals()
            {
                var f = new TimeSummaryProviderFixture(true);
                var result = (await f.Subject.Get(f.TimeEntries.AsQueryable())).summary;
                Assert.Equal(14400, result.ChargeableSeconds);
                Assert.Equal(40, result.ChargeableUnits);
                Assert.Equal(50, result.ChargeablePercentage);
                Assert.Equal(18000, result.TotalHours);
                Assert.Equal(400, result.TotalValue);
                Assert.Equal(20, result.TotalDiscount);
                Assert.Equal(50, result.TotalUnits);
            }

            [Fact]
            public async Task ReturnsEmptySummaryWhenNoEntries()
            {
                var f = new TimeSummaryProviderFixture();
                var result = (await f.Subject.Get(new TimeEntry[] { }.AsQueryable())).summary;
                f.SiteControlReader.DidNotReceive().Read<int>(Arg.Any<string>());
                Assert.False(result.ChargeablePercentage.HasValue);
                Assert.False(result.ChargeableSeconds.HasValue);
                Assert.False(result.ChargeableUnits.HasValue);
                Assert.False(result.TotalHours.HasValue);
                Assert.False(result.TotalValue.HasValue);
                Assert.False(result.TotalDiscount.HasValue);
                Assert.False(result.TotalUnits.HasValue);
            }

            [Fact]
            public async Task ReturnsTotalHoursAndValue()
            {
                var f = new TimeSummaryProviderFixture();
                var result = (await f.Subject.Get(f.TimeEntries.AsQueryable())).summary;
                Assert.Equal(18000, result.TotalHours);
                Assert.Equal(0, result.TotalValue);
                Assert.Equal(0, result.ChargeableSeconds);
                Assert.Equal(0, result.ChargeableUnits);
                Assert.Equal(0, result.ChargeablePercentage);
                Assert.Equal(0, result.TotalDiscount);
                Assert.Equal(50, result.TotalUnits);
            }
        }

        public class TimeSummaryProviderFixture : IFixture<TimeSummaryProvider>
        {
            public TimeSummaryProviderFixture(bool withCharges = false)
            {
                SiteControlReader = Substitute.For<ISiteControlReader>();
                Subject = new TimeSummaryProvider(SiteControlReader);
                TimeEntries = GetEntries(withCharges);
            }

            public ISiteControlReader SiteControlReader { get; set; }
            public TimeEntry[] TimeEntries { get; set; }
            public TimeSummaryProvider Subject { get; set; }

            TimeEntry[] GetEntries(bool withCharges)
            {
                var totalTime = Fixture.Today().Date;
                return new[]
                {
                    new TimeEntry {NarrativeText = "IncompleteTime", TotalUnits = 0, TotalTime = totalTime},
                    new TimeEntry {NarrativeText = "ZeroValue", TotalUnits = 10, TotalTime = totalTime.AddHours(1), LocalValue = 0},
                    new TimeEntry {NarrativeText = "Chargeable 1", TotalUnits = 10, TotalTime = totalTime.AddHours(1), LocalValue = withCharges ? 100 : 0, LocalDiscount = withCharges ? 10 : 0},
                    new TimeEntry {NarrativeText = "Chargeable 2", TotalUnits = 10, TotalTime = totalTime.AddHours(1), LocalValue = withCharges ? 100 : 0, LocalDiscount = withCharges ? 10 : 0},
                    new TimeEntry {NarrativeText = "Chargeable 3 - Parent", TotalUnits = 10, TotalTime = null, LocalValue = withCharges ? 100 : 0, EntryNo = 99},
                    new TimeEntry {NarrativeText = "Chargeable 4 - Child", TotalUnits = 10, TotalTime = totalTime.AddHours(1), LocalValue = withCharges ? 100 : 0, ParentEntryNo = 99, TimeCarriedForward = totalTime.AddHours(1)}
                };
            }
        }
    }
}