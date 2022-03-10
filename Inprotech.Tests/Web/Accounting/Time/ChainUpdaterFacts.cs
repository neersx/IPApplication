using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class ChainUpdaterFacts
    {
        public class GetDownwardChain
        {
            [Fact]
            public async Task ThrowsErrorIfUpdateMadeToNonLeafEntry()
            {
                var f = new ChainUpdaterFixture();
                f.TimesheetList.DiaryFor(Arg.Any<int>(), Arg.Any<DateTime>()).ReturnsForAnyArgs(new[] {new Diary {EntryNo = 1, ParentEntryNo = 2}, new Diary {EntryNo = 2}}.AsDbAsyncEnumerble());

                await Assert.ThrowsAsync<ArgumentException>(async () => await f.Subject.GetDownwardChain(10, Fixture.Today(), 2));
                f.TimesheetList.Received(1).DiaryFor(10, Fixture.Today());
            }
        }

        public class GetWholeChain
        {
            [Fact]
            public async Task ThrowsErrorIfentryNotFound()
            {
                var f = new ChainUpdaterFixture();
                f.TimesheetList.DiaryFor(Arg.Any<int>(), Arg.Any<DateTime>()).ReturnsForAnyArgs(new[] {new Diary {EntryNo = 1, ParentEntryNo = 2}, new Diary {EntryNo = 2}}.AsDbAsyncEnumerble());

                await Assert.ThrowsAsync<ArgumentException>(async () => await f.Subject.GetWholeChain(10, Fixture.Today(), 22));
                f.TimesheetList.Received(1).DiaryFor(10, Fixture.Today());
            }
        }

        public class DateUpdated
        {
            [Fact]
            public void UpdatesChainExceptForFirstRecord()
            {
                var f = new ChainUpdaterFixture();
                var chain = new[]
                {
                    new Diary {EntryNo = 1, ParentEntryNo = 2, ChargeOutRate = 100, ForeignCurrency = "AUD", StartTime = Fixture.Monday, FinishTime = Fixture.Monday},
                    new Diary {EntryNo = 2, ParentEntryNo = 3, StartTime = Fixture.Today().AddHours(1), FinishTime = Fixture.Today().AddHours(5)},
                    new Diary {EntryNo = 3, StartTime = Fixture.Today().AddHours(6), FinishTime = Fixture.Today().AddHours(7)}
                };

                f.Subject.DateUpdated(chain, Fixture.Monday);

                Assert.True(chain.All(_ => _.ChargeOutRate == 100));
                Assert.True(chain.All(_ => _.ForeignCurrency == "AUD"));
                Assert.True(chain.All(_ => _.StartTime.GetValueOrDefault().Date == Fixture.Monday));
                Assert.True(chain.All(_ => _.FinishTime.GetValueOrDefault().Date == Fixture.Monday));

                Assert.Equal(Fixture.Monday.AddHours(1), chain[1].StartTime);
                Assert.Equal(Fixture.Monday.AddHours(5), chain[1].FinishTime);

                Assert.Equal(Fixture.Monday.AddHours(6), chain[2].StartTime);
                Assert.Equal(Fixture.Monday.AddHours(7), chain[2].FinishTime);
            }
        }

        public class UpdateData
        {
            readonly Diary _diary1 = new Diary {EntryNo = 1};
            readonly Diary _diary2 = new Diary {EntryNo = 2, ParentEntryNo = 1};

            IEnumerable<Diary> GetData()
            {
                return new[]
                {
                    _diary2, _diary1
                };
            }

            [Fact]
            public void ExcludeTopEntry()
            {
                var f = new ChainUpdaterFixture();
                var updateFrom = new Diary {CaseId = 10, NarrativeNo = 10};
                f.Subject.UpdateData(GetData(), updateFrom, true);

                Assert.Null(_diary2.CaseId);
                Assert.Null(_diary1.CaseId);
                Assert.Equal(updateFrom.NarrativeNo, _diary1.NarrativeNo);
            }

            [Fact]
            public void IncludeTopEntry()
            {
                var f = new ChainUpdaterFixture();
                var updateFrom = new Diary {CaseId = 10, NarrativeNo = 10};
                f.Subject.UpdateData(GetData(), updateFrom, false, true);

                Assert.Equal(updateFrom.CaseId, _diary2.CaseId);
                Assert.Equal(updateFrom.NarrativeNo, _diary2.NarrativeNo);

                Assert.Equal(updateFrom.CaseId, _diary1.CaseId);
            }

            [Fact]
            public void UpdateBasicsWithOtherData()
            {
                var f = new ChainUpdaterFixture();
                var updateFrom = new Diary {CaseId = 10, NameNo = 1, Activity = "act", ChargeOutRate = 10, ForeignCurrency = "AUD", NarrativeNo = 10};
                f.Subject.UpdateData(GetData(), updateFrom, false, true);

                Assert.Equal(updateFrom.CaseId, _diary1.CaseId);
                Assert.Equal(updateFrom.NameNo, _diary1.NameNo);
                Assert.Equal(updateFrom.ChargeOutRate, _diary1.ChargeOutRate);
                Assert.Equal(updateFrom.ForeignCurrency, _diary1.ForeignCurrency);

                Assert.Equal(updateFrom.NarrativeNo, _diary1.NarrativeNo);
            }

            [Fact]
            public void DoNotUpdateBasics()
            {
                var f = new ChainUpdaterFixture();
                var updateFrom = new Diary {CaseId = 10, NameNo = 1, Activity = "act", ChargeOutRate = 10, ForeignCurrency = "AUD", NarrativeNo = 10, LongNarrative = "Long", ShortNarrative = "Short", Notes = "Notes"};
                f.Subject.UpdateData(GetData(), updateFrom);

                Assert.Null(_diary1.CaseId);
                Assert.Null(_diary1.NameNo);
                Assert.Null(_diary1.ChargeOutRate);
                Assert.Null(_diary1.ForeignCurrency);

                Assert.Equal(updateFrom.NarrativeNo, _diary1.NarrativeNo);
                Assert.Equal(updateFrom.LongNarrative, _diary1.LongNarrative);
                Assert.Equal(updateFrom.ShortNarrative, _diary1.ShortNarrative);
                Assert.Equal(updateFrom.Notes, _diary1.Notes);
            }
        }

        public class RemoveEntryFromChain
        {
            Diary[] SetChain(int staffId)
            {
                return new[]
                {
                    new Diary {EmployeeNo = staffId, EntryNo = 4, ParentEntryNo = 3, StartTime = Fixture.Monday.Date.AddHours(7), FinishTime = Fixture.Monday.Date.AddHours(11), TransactionId = Fixture.Integer(), WipEntityId = Fixture.Integer()},
                    new Diary {EmployeeNo = staffId, EntryNo = 3, ParentEntryNo = 2, StartTime = Fixture.Monday.Date.AddHours(4), FinishTime = Fixture.Monday.Date.AddHours(7)},
                    new Diary {EmployeeNo = staffId, EntryNo = 2, ParentEntryNo = 1, StartTime = Fixture.Monday.Date.AddHours(2), FinishTime = Fixture.Monday.Date.AddHours(4)},
                    new Diary {EmployeeNo = staffId, EntryNo = 1, ParentEntryNo = null, StartTime = Fixture.Monday.Date.AddHours(1), FinishTime = Fixture.Monday.Date.AddHours(2)}
                };
            }

            [Fact]
            public async Task ReturnsEntryIfSingleEntryFound()
            {
                var entries = new[] {new Diary {EntryNo = 99, ParentEntryNo = null, StartTime = Fixture.Monday.Date.AddHours(11), FinishTime = Fixture.Monday.Date.AddHours(12)}};
                var f = new ChainUpdaterFixture();

                var result = await f.Subject.RemoveEntryFromChain(entries, 99);
                Assert.Equal(entries.Single(_ => _.EntryNo == 99), result.diaryToRemove);
                Assert.Null(result.newLastChild);
            }

            [Fact]
            public async Task DeleteTopEntry()
            {
                var f = new ChainUpdaterFixture();
                var entries = SetChain(1);

                var result = await f.Subject.RemoveEntryFromChain(entries, 4);
                
                Assert.Null(entries.Single(_ => _.EntryNo == 4).ParentEntryNo);
                Assert.Equal(new DateTime(1899, 1, 1).AddHours(3),entries.Single(_ => _.EntryNo == 3).TotalTime);
                Assert.Equal(new DateTime(1899, 1, 1).AddHours(3),entries.Single(_ => _.EntryNo == 3).TimeCarriedForward);
                Assert.Equal( new DateTime(1899, 1, 1).AddHours(3), result.newLastChild.TotalTime);
            }

            [Fact]
            public async Task DeleteMiddleEntry()
            {
                var f = new ChainUpdaterFixture();
                var entries = SetChain(1);

                var result = await f.Subject.RemoveEntryFromChain(entries, 3);

                Assert.Null(entries.Single(_ => _.EntryNo == 3).ParentEntryNo);
                Assert.Equal(2, entries.Single(_ => _.EntryNo == 4).ParentEntryNo);
                Assert.Equal(new DateTime(1899, 1, 1).AddHours(4), entries.Single(_ => _.EntryNo == 4).TotalTime);
                Assert.Equal(new DateTime(1899, 1, 1).AddHours(3), entries.Single(_ => _.EntryNo == 4).TimeCarriedForward);
                Assert.Equal( new DateTime(1899, 1, 1).AddHours(4), result.newLastChild.TotalTime);
            }

            [Fact]
            public async Task DeleteLastEntry()
            {
                var f = new ChainUpdaterFixture();
                var entries = SetChain(1);

                var result = await f.Subject.RemoveEntryFromChain(entries, 1);

                Assert.Null(entries.Single(_ => _.EntryNo == 1).ParentEntryNo);
                Assert.Null(entries.Single(_ => _.EntryNo == 2).ParentEntryNo);
                Assert.Equal(new DateTime(1899, 1, 1).AddHours(4), entries.Single(_ => _.EntryNo == 4).TotalTime);
                Assert.Equal(new DateTime(1899, 1, 1).AddHours(5), entries.Single(_ => _.EntryNo == 4).TimeCarriedForward);
                Assert.Equal( new DateTime(1899, 1, 1).AddHours(4), result.newLastChild.TotalTime);
            }

            [Fact]
            public async Task TotalTimeNotUpdatedForTimer()
            {
                var timeEntry = new Diary{EntryNo = 20, ParentEntryNo = null, StartTime = Fixture.Monday.Date.AddHours(13), FinishTime = Fixture.Monday.Date.AddHours(14)};
                var timerEntry = new Diary {EntryNo = 21, ParentEntryNo = 20, StartTime = Fixture.Monday.Date.AddHours(14), FinishTime = null, IsTimer = 1};
                timerEntry.FinishTime = null;
                timerEntry.TotalTime = null;
                timerEntry.NameNo = 100;
                timerEntry.CaseId = 999;
                timerEntry.Activity = "Jump";

                var entries = new[] {timerEntry, timeEntry};
                var f = new ChainUpdaterFixture();

                var result = await f.Subject.RemoveEntryFromChain(entries, 20);

                Assert.Null(entries.Single(_ => _.EntryNo == 21).ParentEntryNo);
                Assert.Equal(null, entries.Single(_ => _.EntryNo == 21).TotalTime);
                Assert.Equal(new DateTime(1899, 1, 1), entries.Single(_ => _.EntryNo == 21).TimeCarriedForward);
                Assert.Null(result.newLastChild.TotalTime);
            }

            [Fact]
            public async Task TransNumberSetForNewLastChild()
            {
                var f = new ChainUpdaterFixture();
                var entries = SetChain(1);
                var oldLastChild = entries.First();
                var result = await f.Subject.RemoveEntryFromChain(entries, 4);

                Assert.Equal(oldLastChild.WipEntityId, result.newLastChild.WipEntityId);
                Assert.Equal(oldLastChild.TransactionId, result.newLastChild.TransactionId);
            }
        }
    }

    public class ChainUpdaterFixture : IFixture<IChainUpdater>
    {
        public ChainUpdaterFixture()
        {
            TimesheetList = Substitute.For<ITimesheetList>();

            Subject = new ChainUpdater(TimesheetList);
        }

        public IChainUpdater Subject { get; }

        public ITimesheetList TimesheetList { get; }
    }
}