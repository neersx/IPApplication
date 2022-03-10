using System;
using System.Collections.Generic;
using System.IdentityModel.Protocols.WSTrust;
using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class DiaryTimerUpdaterFacts
    {
        public class AddContinuedTimerEntry : FactBase
        {
            [Fact]
            public async Task FetchAndAddContinuedEntry()
            {
                var f = new DiaryTimerUpdaterFixture(Db);
                var diary1 = new Diary {EntryNo = 1, EmployeeNo = 1}.In(Db);
                var diary2 = new Diary {EntryNo = 2, EmployeeNo = 1, ParentEntryNo = 2, TotalTime = new DateTime(1899, 1, 1, 1, 0, 0, 0), TimeCarriedForward = new DateTime(1899, 1, 1, 2, 0, 0, 0)}.In(Db);
                f.ChainUpdater.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).ReturnsForAnyArgs(new[] {diary2, diary1});

                Assert.Equal(2, Db.Set<Diary>().Count());
                await f.Subject.AddContinuedTimerEntry(1, 2, Fixture.TodayTime());

                f.ChainUpdater.Received(1).GetDownwardChain(Arg.Is<int>(_ => _ == 1), Arg.Is<DateTime>(_ => _ == Fixture.TodayTime().Date), Arg.Is<int>(_ => _ == 2)).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(3, Db.Set<Diary>().Count());

                var newDiary = Db.Set<Diary>().Single(_ => _.EntryNo == 3);
                Assert.Null(newDiary.FinishTime);
                Assert.Null(newDiary.TotalUnits);
                Assert.Null(newDiary.TotalTime);
                Assert.Equal(1, newDiary.IsTimer);
                Assert.Equal(Fixture.TodayTime(), newDiary.StartTime);
                Assert.Equal(new DateTime(1899, 1, 1, 3, 0, 0, 0), newDiary.TimeCarriedForward);
                Assert.Equal(2, newDiary.ParentEntryNo);

                var lastTopDiary = Db.Set<Diary>().Single(_ => _.EntryNo == 2);
                Assert.Null(lastTopDiary.TimeCarriedForward);
                Assert.Null(lastTopDiary.TotalUnits);
                Assert.Null(lastTopDiary.TimeValue);
                Assert.Null(lastTopDiary.DiscountValue);
                Assert.Null(lastTopDiary.ForeignValue);
                Assert.Null(lastTopDiary.ForeignDiscount);
                Assert.Null(lastTopDiary.CostCalculation1);
                Assert.Null(lastTopDiary.CostCalculation2);
                Assert.Null(lastTopDiary.TotalTime);

                f.SplitUpdater.Received(1).PurgeSplits(Arg.Is<Diary>(_ => _ == lastTopDiary));
                Db.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class UpdateTimeAndDataForTimerEntry : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionForInvalidData()
            {
                var f = new DiaryTimerUpdaterFixture(Db);

                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.UpdateTimeAndDataForTimerEntry(new RecordableTime {StaffId = null, EntryNo = 1}));
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.UpdateTimeAndDataForTimerEntry(new RecordableTime {StaffId = 1, EntryNo = null}));

                f.ChainUpdater.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).ReturnsForAnyArgs(new[] {new Diary {IsTimer = 0}});
                await Assert.ThrowsAsync<InvalidRequestException>(async () => await f.Subject.UpdateTimeAndDataForTimerEntry(new RecordableTime {StaffId = 1, EntryNo = 1}));
            }

            [Fact]
            public async Task UpdatesData()
            {
                var f = new DiaryTimerUpdaterFixture(Db);
                var diaryParent = new Diary {EntryNo = 1, EmployeeNo = 11}.In(Db);
                var diaryTimer = new Diary {EntryNo = 2, EmployeeNo = 11, IsTimer = 1, ParentEntryNo = 1, StartTime = Fixture.Today().AddHours(1), TimeCarriedForward = new DateTime(1899, 1, 1, 2, 0, 0)}.In(Db);

                f.ChainUpdater.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).ReturnsForAnyArgs(new[] {diaryTimer, diaryParent});
                var input = new RecordableTime {EntryNo = 2, CaseKey = 11, NarrativeNo = 1, StaffId = 1, Start = Fixture.Today().AddHours(1), ParentEntryNo = 1};
                await f.Subject.UpdateTimeAndDataForTimerEntry(input, new DateTime(1899, 1, 1, 1, 0, 0, 0));

                f.ChainUpdater.Received(1).GetDownwardChain(Arg.Is<int>(_ => _ == 1), Arg.Is<DateTime>(_ => _ == Fixture.Today().AddHours(1)), Arg.Is<int>(_ => _ == 2)).IgnoreAwaitForNSubstituteAssertion();
                f.ValueTime.Received(1).For(Arg.Any<RecordableTime>(), "en-US").IgnoreAwaitForNSubstituteAssertion();
                f.SplitUpdater.UpdateSplits(Arg.Is<Diary>(_=>_.EntryNo == 2), Arg.Any<IEnumerable<DebtorSplit>>());

                var updatedTimer = Db.Set<Diary>().Single(_ => _.EntryNo == 2);
                Assert.Equal(Fixture.Today().Add(new DateTime(1899, 1, 1, 2, 0, 0, 0).TimeOfDay), updatedTimer.FinishTime);
                f.ChainUpdater.Received(1).UpdateData(Arg.Is<IEnumerable<Diary>>(_ => _.First() == diaryTimer && _.Last() == diaryParent), Arg.Is<Diary>(_ => _.EntryNo == 2), Arg.Is(true), Arg.Is(true));
                Db.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class UpdateTimeForTimerEntry : FactBase
        {
            [Fact]
            public async Task ReturnsNullIfNoEntryFound()
            {
                var f = new DiaryTimerUpdaterFixture(Db);

                var result = await f.Subject.UpdateTimeForTimerEntry(Db.Set<Diary>().Where(_ => _.EntryNo == 1));
                Assert.Null(result);
            }

            [Fact]
            public async Task SetsFinishTimeBasedonTotalTime()
            {
                var f = new DiaryTimerUpdaterFixture(Db);
                var diary = new DiaryBuilder(Db) {IsTimer = true, StartTime = new DateTime(2019, 1, 1, 1, 1, 1), StaffId = 10}.BuildWithCase();
                var q = Db.Set<Diary>().Where(_ => _.EntryNo == diary.EntryNo && _.EmployeeNo == diary.EmployeeNo);
                var result = await f.Subject.UpdateTimeForTimerEntry(q, new DateTime(1899, 1, 1, 6, 0, 0));

                Assert.NotNull(result);
                var savedDiary = q.Single();

                Assert.Equal(diary.StartTime.GetValueOrDefault().AddHours(6), savedDiary.FinishTime);
            }

            [Fact]
            public async Task SetsFinishTimeToEndOfDayWhenTotalTimeGoesToNextDay()
            {
                var f = new DiaryTimerUpdaterFixture(Db);
                var diary = new DiaryBuilder(Db) {IsTimer = true, StartTime = new DateTime(2019, 1, 1, 9, 1, 1), StaffId = 10}.BuildWithCase();
                var q = Db.Set<Diary>().Where(_ => _.EntryNo == diary.EntryNo && _.EmployeeNo == diary.EmployeeNo);
                var result = await f.Subject.UpdateTimeForTimerEntry(q, new DateTime(1899, 1, 1, 23, 0, 0));

                Assert.NotNull(result);
                var savedDiary = q.Single();

                Assert.Equal(diary.StartTime.GetValueOrDefault().Date, savedDiary.FinishTime.GetValueOrDefault().Date);
                Assert.Equal(23, savedDiary.FinishTime.GetValueOrDefault().Hour);
                Assert.Equal(59, savedDiary.FinishTime.GetValueOrDefault().Minute);
                Assert.Equal(59, savedDiary.FinishTime.GetValueOrDefault().Second);
            }

            [Fact]
            public async Task SetsFinishTimeBasedonEndOfDay()
            {
                var f = new DiaryTimerUpdaterFixture(Db);

                var diary = new DiaryBuilder(Db) {IsTimer = true, StartTime = new DateTime(2019, 1, 1, 1, 1, 1), StaffId = 10}.BuildWithCase();
                var q = Db.Set<Diary>().Where(_ => _.EntryNo == diary.EntryNo && _.EmployeeNo == diary.EmployeeNo);
                var result = await f.Subject.UpdateTimeForTimerEntry(q);

                Assert.NotNull(result);
                var savedDiary = q.Single();

                Assert.Equal(diary.StartTime.GetValueOrDefault().Date.Add(new TimeSpan(23, 59, 59)), savedDiary.FinishTime);
            }

            [Fact]
            public async Task CallsToGetCostedTimeAndSavesData()
            {
                var f = new DiaryTimerUpdaterFixture(Db);
                var employeeNo = 10;
                var diary = new DiaryBuilder(Db) {IsTimer = true, StartTime = new DateTime(2019, 1, 1, 1, 1, 1), StaffId = employeeNo}.BuildWithCase();

                var newSplit1 = new DebtorSplit {DebtorNameNo = 1, EntryNo = diary.EntryNo, ChargeOutRate = 10, SplitPercentage = 10};
                var newSplit2 = new DebtorSplit {DebtorNameNo = 2, EntryNo = diary.EntryNo, ChargeOutRate = 60, SplitPercentage = 90};
                var costedEntry = new TimeEntry
                {
                    TotalUnits = 1,
                    DebtorSplits = new List<DebtorSplit> {newSplit1, newSplit2},
                    ChargeOutRate = 10,
                    ForeignDiscount = 11,
                    ForeignValue = 19,
                    ForeignCurrency = "AUD",
                    LocalValue = 1,
                    LocalDiscount = 100,
                    IsTimer = true,
                    StartTime = Fixture.Today(),
                    TotalTime = new DateTime(1899, 1, 1, 4, 0, 0)
                };
                f.ValueTime.For(Arg.Any<RecordableTime>(), Arg.Any<string>()).ReturnsForAnyArgs(costedEntry);

                var result = await f.Subject.UpdateTimeForTimerEntry(Db.Set<Diary>().Where(_ => _.EntryNo == diary.EntryNo));

                f.ValueTime.Received(1).For(Arg.Any<RecordableTime>(), "en-US").IgnoreAwaitForNSubstituteAssertion();
                await Db.Received(1).SaveChangesAsync();

                var savedDiary = Db.Set<Diary>().Single();
                Assert.Equal(diary.StartTime, savedDiary.StartTime);
                Assert.Equal(0, savedDiary.IsTimer);
                Assert.Equal(costedEntry.TotalUnits, savedDiary.TotalUnits);
                Assert.Equal(costedEntry.ChargeOutRate, savedDiary.ChargeOutRate);
                Assert.Equal(costedEntry.ForeignCurrency, savedDiary.ForeignCurrency);
                Assert.Equal(costedEntry.ForeignDiscount, savedDiary.ForeignDiscount);
                Assert.Equal(costedEntry.ForeignValue, savedDiary.ForeignValue);
                Assert.Equal(costedEntry.LocalDiscount, savedDiary.DiscountValue);
                Assert.Equal(costedEntry.LocalValue, savedDiary.TimeValue);
                Assert.Equal(diary.EmployeeNo, result.EmployeeNo);
                Assert.Equal(diary.EntryNo, result.EntryNo);
            }
        }

        public class ResetTimeForTimerEntry : FactBase
        {
            [Fact]
            public async Task ReturnsNullIfNoEntryFound()
            {
                var f = new DiaryTimerUpdaterFixture(Db);

                var result = await f.Subject.ResetTimeForTimerEntry(Db.Set<Diary>().Where(_ => _.EntryNo == 1), new DateTime());
                Assert.Null(result);
            }

            [Fact]
            public async Task SavesData()
            {
                var f = new DiaryTimerUpdaterFixture(Db);
                var employeeNo = 10;
                var diary = new DiaryBuilder(Db) {IsTimer = true, StartTime = new DateTime(2019, 1, 1, 1, 1, 1), StaffId = employeeNo}.BuildWithCase();
                new DebtorSplitDiary {EmployeeNo = employeeNo, EntryNo = diary.EntryNo}.In(Db);
                new DebtorSplitDiary {EmployeeNo = employeeNo, EntryNo = diary.EntryNo}.In(Db);

                var newStartTime = diary.StartTime.GetValueOrDefault().AddHours(3);
                var result = await f.Subject.ResetTimeForTimerEntry(Db.Set<Diary>().Where(_ => _.EntryNo == diary.EntryNo && _.EmployeeNo == employeeNo), newStartTime);

                Db.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();

                var savedDiary = Db.Set<Diary>().Single();
                Assert.Equal(newStartTime, savedDiary.StartTime);
                Assert.Equal(diary.EmployeeNo, result.EmployeeNo);
                Assert.Equal(diary.EntryNo, result.EntryNo);
            }
        }

        public class StopTimerEntry : FactBase
        {
            [Fact]
            public async Task ReturnsNullIfNoEntryFound()
            {
                var f = new DiaryTimerUpdaterFixture(Db);
                var result = await f.Subject.StopTimerEntry(Db.Set<Diary>().Where(_ => _.EntryNo == 1), Fixture.TodayTime());
                Assert.Null(result);
            }
            
            [Fact]
            public async Task SetsFinishToEndOfCurrentDayIfOver()
            {
                var f = new DiaryTimerUpdaterFixture(Db);
                var diary = new DiaryBuilder(Db) {IsTimer = true, StartTime = Fixture.Today().AddHours(1), StaffId = Fixture.Integer()}.BuildWithCase();
                await f.Subject.StopTimerEntry(Db.Set<Diary>().Where(_ => _.EntryNo == diary.EntryNo), Fixture.Today().AddDays(1));
                f.ValueTime.Received(1)
                 .For(Arg.Is<RecordableTime>(x => x.isTimer == true &&
                                                  x.TotalTime.Value.Date == new DateTime(1899, 1, 1) &&
                                                  x.TotalTime.Value.Hour == 22 &&
                                                  x.TotalTime.Value.Minute == 59 &&
                                                  x.TotalTime.Value.Second == 59), "en-US")
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task SetsFinishTimeToSpecifiedTime()
            {
                var f = new DiaryTimerUpdaterFixture(Db);
                var diary = new DiaryBuilder(Db) {IsTimer = true, StartTime = Fixture.Today().AddHours(1), StaffId = Fixture.Integer()}.BuildWithCase();
                await f.Subject.StopTimerEntry(Db.Set<Diary>().Where(_ => _.EntryNo == diary.EntryNo), Fixture.Today().AddHours(2).AddMinutes(10).AddSeconds(30));
                f.ValueTime.Received(1)
                 .For(Arg.Is<RecordableTime>(x => x.isTimer == true &&
                                                  x.TotalTime.Value.Date == new DateTime(1899, 1, 1) &&
                                                  x.TotalTime.Value.Hour == 1 &&
                                                  x.TotalTime.Value.Minute == 10 &&
                                                  x.TotalTime.Value.Second == 30), "en-US")
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task CallsToGetCostedTimeAndSavesData()
            {
                var f = new DiaryTimerUpdaterFixture(Db);
                var diary = new DiaryBuilder(Db) {IsTimer = true, StartTime = Fixture.Today().AddHours(1), StaffId = Fixture.Integer()}.BuildWithCase();
                var costedEntry = new TimeEntry
                {
                    TotalUnits = 1,
                    DebtorSplits = new List<DebtorSplit>(),
                    ChargeOutRate = 10,
                    ForeignDiscount = 11,
                    ForeignValue = 19,
                    ForeignCurrency = "AUD",
                    LocalValue = 1,
                    LocalDiscount = 100,
                    IsTimer = true
                };
                f.ValueTime.For(Arg.Any<RecordableTime>(), Arg.Any<string>()).ReturnsForAnyArgs(costedEntry);

                var result = await f.Subject.StopTimerEntry(Db.Set<Diary>().Where(_ => _.EntryNo == diary.EntryNo), Fixture.TodayTime());

                f.ValueTime.Received(1)
                 .For(Arg.Is<RecordableTime>(x => x.isTimer == true &&
                                                  x.TotalTime.Value.Date == new DateTime(1899, 1, 1) &&
                                                  x.TotalTime.Value.Hour == 22 &&
                                                  x.TotalTime.Value.Minute == 59 &&
                                                  x.TotalTime.Value.Second == 59), "en-US")
                 .IgnoreAwaitForNSubstituteAssertion();
                await Db.Received(1).SaveChangesAsync();

                var savedDiary = Db.Set<Diary>().Single();
                Assert.Equal(diary.StartTime, savedDiary.StartTime);
                Assert.Equal(0, savedDiary.IsTimer);
                Assert.Equal(costedEntry.TotalUnits, savedDiary.TotalUnits);
                Assert.Equal(costedEntry.ChargeOutRate, savedDiary.ChargeOutRate);
                Assert.Equal(costedEntry.ForeignCurrency, savedDiary.ForeignCurrency);
                Assert.Equal(costedEntry.ForeignDiscount, savedDiary.ForeignDiscount);
                Assert.Equal(costedEntry.ForeignValue, savedDiary.ForeignValue);
                Assert.Equal(costedEntry.LocalDiscount, savedDiary.DiscountValue);
                Assert.Equal(costedEntry.LocalValue, savedDiary.TimeValue);
                Assert.Equal(diary.EmployeeNo, result.EmployeeNo);
                Assert.Equal(diary.EntryNo, result.EntryNo);
                Assert.Equal(Fixture.TodayTime(), savedDiary.FinishTime);
                Assert.Equal(22, savedDiary.TotalTime.GetValueOrDefault().Hour);
                Assert.Equal(59, savedDiary.TotalTime.GetValueOrDefault().Minute);
                Assert.Equal(59, savedDiary.TotalTime.GetValueOrDefault().Second);
            }
        }
    }

    public class DiaryTimerUpdaterFixture : IFixture<IDiaryTimerUpdater>
    {
        public DiaryTimerUpdaterFixture(InMemoryDbContext db)
        {
            Now = Substitute.For<Func<DateTime>>();
            Now().Returns(Fixture.Today());

            ChainUpdater = Substitute.For<IChainUpdater>();
            SplitUpdater = Substitute.For<IDebtorSplitUpdater>();
            ValueTime = Substitute.For<IValueTime>();

            var m = new Mapper(new MapperConfiguration(cfg =>
            {
                cfg.AddProfile(new AccountingProfile());
                cfg.CreateMissingTypeMaps = true;
            }));
            Mapper = m.DefaultContext.Mapper.DefaultContext.Mapper;
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            PreferredCultureResolver.Resolve().Returns("en-US");

            Subject = new DiaryTimerUpdater(db, Mapper, ValueTime, Now, ChainUpdater, SplitUpdater, PreferredCultureResolver);
        }

        public IDiaryTimerUpdater Subject { get; }
        public IMapper Mapper { get; }
        public IValueTime ValueTime { get; }
        public Func<DateTime> Now { get; }
        public IChainUpdater ChainUpdater { get; }
        public IDebtorSplitUpdater SplitUpdater { get; }
        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
    }
}