using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using AutoMapper;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Security;
using NSubstitute;
using NSubstitute.ExceptionExtensions;
using Xunit;
using ArgumentNullException = System.ArgumentNullException;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class DiaryUpdateFacts
    {
        public class AddEntry : FactBase
        {
            [Fact]
            public void ThrowsExceptionIfStaffIdNotSetOnInput()
            {
                var f = new DiaryUpdateFixture(Db);
                Assert.ThrowsAsync<HttpResponseException>(() => f.Subject.AddEntry(new RecordableTime()));
            }

            [Fact]
            public async Task CallsToValueTime()
            {
                var input = new RecordableTime {StaffId = 10, TotalTime = new DateTime(1899, 1, 1, 6, 0, 0)};
                var f = new DiaryUpdateFixture(Db);
                await f.Subject.AddEntry(input);

                f.Now.Received(1);
                f.ValueTime.Received(1).For(Arg.Is<RecordableTime>(_ => _ == input), "en-US").IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task DoesNotCallToValueTimeIfNotCostableEntry()
            {
                var f = new DiaryUpdateFixture(Db);

                var input = new RecordableTime {StaffId = 10, TotalTime = new DateTime(), isTimer = true};
                await f.Subject.AddEntry(input);
                f.ValueTime.DidNotReceive().For(Arg.Any<RecordableTime>(), Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
                f.ValueTime.ClearReceivedCalls();

                input = new RecordableTime {StaffId = 10, TotalTime = null, isTimer = false};
                await f.Subject.AddEntry(input);
                f.ValueTime.DidNotReceive().For(Arg.Any<RecordableTime>(), Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task SavesEntry()
            {
                var input = new RecordableTime
                {
                    StaffId = 10,
                    ActivityKey = "ABCD",
                    CaseKey = -10,
                    NameKey = -11,
                    Start = new DateTime(2020, 1, 1, 1, 1, 0),
                    Finish = new DateTime(2020, 1, 1, 2, 1, 0),
                    TotalTime = new DateTime(1899, 1, 1, 1, 0, 0),
                    Notes = "Some funny notes!",
                    TotalUnits = 1
                };

                var costedEntry = new TimeEntry
                {
                    StaffId = 10,
                    LocalValue = 10,
                    LocalDiscount = 100,
                    ChargeOutRate = 1,
                    ForeignCurrency = "AUD",
                    ForeignValue = 100,
                    ForeignDiscount = 11,
                    TotalUnits = 1,
                    UnitsPerHour = 6
                };

                var f = new DiaryUpdateFixture(Db, false);
                f.ValueTime.For(Arg.Any<RecordableTime>(), Arg.Any<string>()).ReturnsForAnyArgs(costedEntry);
                await f.Subject.AddEntry(input);

                f.ValueTime.Received(1).For(Arg.Is<RecordableTime>(_ => _ == input), "en-US").IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(1, Db.Set<Diary>().Count());
                var savedEntry = Db.Set<Diary>().Single();
                Assert.Equal(input.StaffId, savedEntry.EmployeeNo);
                Assert.Equal(input.Activity, savedEntry.Activity);
                Assert.Equal(input.CaseKey, savedEntry.CaseId);
                Assert.Null(savedEntry.NameNo);
                Assert.Equal(input.Start, savedEntry.StartTime);
                Assert.Equal(input.Finish, savedEntry.FinishTime);
                Assert.Equal(input.TotalTime, savedEntry.TotalTime);
                Assert.Equal(input.TotalUnits, savedEntry.TotalUnits);
                Assert.Equal(input.Notes, savedEntry.Notes);

                Assert.Equal(costedEntry.LocalValue, savedEntry.TimeValue);
                Assert.Equal(costedEntry.LocalDiscount, savedEntry.DiscountValue);
                Assert.Equal(costedEntry.ChargeOutRate, savedEntry.ChargeOutRate);
                Assert.Equal(costedEntry.ForeignValue, savedEntry.ForeignValue);
                Assert.Equal(costedEntry.ForeignDiscount, savedEntry.ForeignDiscount);
                Assert.Equal(costedEntry.ForeignCurrency, savedEntry.ForeignCurrency);
                Assert.Equal(costedEntry.UnitsPerHour, savedEntry.UnitsPerHour);
            }

            [Fact]
            public async Task SavesDebtorSplitsIfApplicable()
            {
                var input = new RecordableTime
                {
                    StaffId = 10,
                    TotalTime = new DateTime(1899, 1, 1).AddHours(1)
                };
                var debtorSplit1 = new DebtorSplit {SplitPercentage = 10, DebtorNameNo = 91, Narrative = "La la la", NarrativeNo = 99, LocalValue = 100, LocalDiscount = 10, ForeignDiscount = 1, ForeignCurrency = "USD", ForeignValue = 900};
                var debtorSplit2 = new DebtorSplit {SplitPercentage = 90, DebtorNameNo = 1, Narrative = "Ha ha ha", NarrativeNo = 99, LocalValue = 101, LocalDiscount = 110, ForeignDiscount = 11, ForeignCurrency = "AUD", ForeignValue = 1900};

                var costedEntry = new TimeEntry
                {
                    LocalValue = 10,
                    LocalDiscount = 100,
                    StaffId = 10,
                    TotalTime = new DateTime(1899, 1, 1).AddHours(1),
                    DebtorSplits = new List<DebtorSplit> {debtorSplit1, debtorSplit2}
                };

                var f = new DiaryUpdateFixture(Db, false);
                f.ValueTime.For(Arg.Any<RecordableTime>(), Arg.Any<string>()).ReturnsForAnyArgs(costedEntry);
                await f.Subject.AddEntry(input);

                Assert.Equal(1, Db.Set<Diary>().Count());
            }

            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            public async Task NarrativeTextSavedAsShortOrLongText(bool isLongText)
            {
                var f = new DiaryUpdateFixture(Db);
                var narrative = isLongText ? Fixture.RandomString(255) : Fixture.RandomString(100);
                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today().AddHours(1),
                    CaseKey = Fixture.Integer(),
                    Activity = Fixture.String(),
                    NarrativeText = narrative,
                    EntryDate = Fixture.Today(),
                    StaffId = f.CurrentUser.NameId
                };

                var staffId = f.CurrentUser.NameId;
                await f.Subject.AddEntry(input);
                var entry = Db.Set<Diary>().Single(_ => _.EmployeeNo == staffId && _.EntryNo == f.NextEntryNo);
                await f.ValueTime.Received(1).For(Arg.Any<RecordableTime>(), "en-US");
                Assert.True(isLongText ? entry.ShortNarrative == null && entry.LongNarrative == narrative : entry.ShortNarrative == narrative && entry.LongNarrative == null);
            }

            [Fact]
            public async Task NarrativeNoIsSavedWithNarrativeText()
            {
                var f = new DiaryUpdateFixture(Db);

                var narrativeText = Fixture.RandomString(300);
                var narrativeNo = Fixture.Short();
                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today().AddHours(1),
                    CaseKey = Fixture.Integer(),
                    Activity = Fixture.String(),
                    NarrativeText = narrativeText,
                    NarrativeNo = narrativeNo,
                    EntryDate = Fixture.Today(),
                    StaffId = f.CurrentUser.NameId
                };

                var staffId = f.CurrentUser.NameId;
                await f.Subject.AddEntry(input);
                var entry = Db.Set<Diary>().Single(_ => _.EmployeeNo == staffId && _.EntryNo == f.NextEntryNo);
                await f.ValueTime.Received(1).For(Arg.Any<RecordableTime>(), "en-US");

                Assert.Equal(narrativeText, entry.LongNarrative);
                Assert.Equal(narrativeNo, entry.NarrativeNo);
            }
        }

        public class AddEntryForContinuation : FactBase
        {
            [Fact]
            public async Task PropagateChangesToParentEntries()
            {
                var f = new DiaryUpdateFixture(Db);

                var entry1 = new DiaryBuilder(Db) {EntryNo = 1}.Build();
                var entry2 = new DiaryBuilder(Db) {EntryNo = 2, ParentEntryNo = 1, StaffId = entry1.EmployeeNo}.Build();

                var changedEntry = new RecordableTime
                {
                    EntryDate = Fixture.Today(),
                    ParentEntryNo = 2,
                    NarrativeNo = 10,
                    NarrativeText = "Such a short Narrative!!",
                    Notes = "Jack and Jill",
                    StaffId = entry1.EmployeeNo,
                    TotalTime = new DateTime(1899, 1, 1, 1, 1, 1)
                };
                f.ChainUpdator.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).Returns(Task.FromResult(new[] {entry2, entry1}.AsEnumerable()));

                await f.Subject.AddEntry(changedEntry);
                f.ValueTime.Received(1).For(Arg.Any<RecordableTime>(), "en-US").IgnoreAwaitForNSubstituteAssertion();
                f.ChainUpdator.UpdateData(Arg.Is<IEnumerable<Diary>>(_ => _.First() == entry2 && _.Last() == entry1), Arg.Is<Diary>(_ => _.ParentEntryNo == 2));

                var parentEntry = Db.Set<Diary>().Single(_ => _.EntryNo == 2);
                Assert.Null(parentEntry.TimeCarriedForward);
                Assert.Null(parentEntry.TotalTime);
                Assert.Null(parentEntry.TimeValue);

                var entry = Db.Set<Diary>().Single(_ => _.EntryNo == 3);
                Assert.Equal(changedEntry.NarrativeNo, entry.NarrativeNo);
                Assert.Equal(changedEntry.NarrativeText, entry.ShortNarrative);
                Assert.Equal(changedEntry.Notes, entry.Notes);
            }

            [Fact]
            public async Task ClearsParentEntryValues()
            {
                var parentEntryNo = Fixture.Short();
                var f = new DiaryUpdateFixture(Db);
                var parent = new DiaryBuilder(Db) {StaffId = f.CurrentStaffId, EntryNo = parentEntryNo}.BuildWithCase(true);
                f.ChainUpdator.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).Returns(Task.FromResult(new[] {parent}.AsEnumerable()));
                var child = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today().AddHours(1),
                    Activity = Fixture.String(),
                    EntryDate = Fixture.Today(),
                    ParentEntryNo = parentEntryNo,
                    StaffId = f.CurrentStaffId
                };
                await f.Subject.AddEntry(child);
                await f.ValueTime.Received(1).For(Arg.Any<RecordableTime>(), "en-US");
                await Db.Received(1).SaveChangesAsync();
                Assert.NotNull(Db.Set<Diary>()
                                 .Single(_ => _.EmployeeNo == f.CurrentStaffId &&
                                              _.EntryNo == parentEntryNo &&
                                              !_.TotalTime.HasValue &&
                                              !_.TotalUnits.HasValue &&
                                              !_.CostCalculation1.HasValue &&
                                              !_.CostCalculation2.HasValue &&
                                              !_.TimeValue.HasValue &&
                                              !_.DiscountValue.HasValue &&
                                              !_.ForeignValue.HasValue &&
                                              !_.ForeignDiscount.HasValue &&
                                              !_.TimeCarriedForward.HasValue &&
                                              _.ChargeOutRate.HasValue &&
                                              _.ExchRate.HasValue &&
                                              !string.IsNullOrWhiteSpace(_.ForeignCurrency)));
            }

            [Fact]
            public async Task UpdatesAccumulatedTime()
            {
                var parentEntryNo = Fixture.Short();
                var f = new DiaryUpdateFixture(Db, false);
                var parent = new DiaryBuilder(Db) {StaffId = f.CurrentStaffId, EntryNo = parentEntryNo}.BuildWithCase();
                f.ChainUpdator.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).Returns(Task.FromResult(new[] {parent}.AsEnumerable()));
                f.ValueTime.For(Arg.Any<RecordableTime>(), Arg.Any<string>()).ReturnsForAnyArgs(new TimeEntry {TimeCarriedForward = new DateTime(1899, 1, 1).AddMinutes(30), StaffId = f.CurrentStaffId});
                var child = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = new DateTime(1899, 1, 1).AddHours(1),
                    EntryDate = Fixture.Today(),
                    CaseKey = parent.CaseId,
                    Activity = parent.Activity,
                    ParentEntryNo = parentEntryNo,
                    TimeCarriedForward = new DateTime(1899, 1, 1).AddMinutes(30),
                    StaffId = f.CurrentStaffId
                };
                var result = await f.Subject.AddEntry(child);
                await f.ValueTime.Received(1).For(Arg.Any<RecordableTime>(), "en-US");
                await Db.Received(1).SaveChangesAsync();
                var saved = Db.Set<Diary>().Single(_ => _.EmployeeNo == f.CurrentStaffId && _.EntryNo == parentEntryNo + 1 && _.ParentEntryNo == parentEntryNo);
                Assert.Equal(parent.CaseId, saved.CaseId);
                Assert.Equal(parent.Activity, saved.Activity);
                Assert.Equal(new DateTime(1899, 1, 1).AddHours(1).Ticks, saved.TotalTime.GetValueOrDefault().Ticks);
                Assert.Equal(new DateTime(1899, 1, 1).AddMinutes(30).Ticks, saved.TimeCarriedForward.GetValueOrDefault().Ticks);
                Assert.Equal(parentEntryNo + 1, result.EntryNo);
            }
        }

        public class UpdateEntry : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task AlwaysSaveTimeWithCaseWhereCaseHasBeenProvided(bool withName)
            {
                var f = new DiaryUpdateFixture(Db);

                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = new DateTime(1899, 1, 1).AddHours(1),
                    CaseKey = Fixture.Integer(),
                    NameKey = withName ? (int?) Fixture.Integer() : null,
                    Activity = Fixture.String(),
                    EntryDate = Fixture.Today(),
                    EntryNo = f.EntryNo,
                    StaffId = f.CurrentUser.NameId
                };

                var valuedTime = f.Mapper.Map<TimeEntry>( f.Mapper.Map<Diary>(input));
                valuedTime.LocalValue = 100;
                valuedTime.LocalDiscount = 10;
                valuedTime.ForeignValue = 50;
                valuedTime.ForeignDiscount = 500;
                valuedTime.ForeignCurrency = "AUD";

                f.ChainUpdator.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).ReturnsForAnyArgs(Db.Set<Diary>().ToArray());
                f.ValueTime.For(Arg.Any<RecordableTime>(), Arg.Any<string>()).ReturnsForAnyArgs(valuedTime);

                var staffId = f.CurrentUser.NameId;
                var result = await f.Subject.UpdateEntry(input);
                await f.ValueTime.Received(1).For(Arg.Any<RecordableTime>(), "en-US");
                Assert.NotNull(Db.Set<Diary>().Single(_ => _.EmployeeNo == staffId && _.CaseId == input.CaseKey && _.NameNo == null && _.Activity == input.Activity));

                Assert.Equal(input.TotalTime, result.TotalTime);
                Assert.Equal(input.Start, result.StartTime);
                Assert.Equal(input.Finish, result.FinishTime);
                Assert.Equal(input.EntryNo, result.EntryNo);
                Assert.Equal(valuedTime.LocalValue, result.LocalValue);
                Assert.Equal(valuedTime.LocalDiscount, result.LocalDiscount);
                Assert.Equal(valuedTime.ForeignValue, result.ForeignValue);
                Assert.Equal(valuedTime.ForeignDiscount, result.ForeignDiscount);
                Assert.Equal(valuedTime.ForeignCurrency, result.ForeignCurrency);
            }

            [Theory]
            [InlineData(false)]
            [InlineData(true)]
            public async Task NarrativeTextSavedAsShortOrLongText(bool isLongText)
            {
                var narrative = isLongText ? Fixture.RandomString(255) : Fixture.RandomString(100);
                var f = new DiaryUpdateFixture(Db);
                f.ChainUpdator.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).ReturnsForAnyArgs(Db.Set<Diary>().ToArray());
                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today().AddHours(1),
                    CaseKey = Fixture.Integer(),
                    Activity = Fixture.String(),
                    NarrativeText = narrative,
                    EntryDate = Fixture.Today(),
                    EntryNo = f.EntryNo,
                    StaffId = f.CurrentStaffId
                };
                var staffId = f.CurrentUser.NameId;
                await f.Subject.UpdateEntry(input);
                var entry = Db.Set<Diary>().Single(_ => _.EmployeeNo == staffId && _.EntryNo == f.EntryNo);
                await f.ValueTime.Received(1).For(Arg.Any<RecordableTime>(), "en-US");
                Assert.True(isLongText ? entry.ShortNarrative == null && entry.LongNarrative == narrative : entry.ShortNarrative == narrative && entry.LongNarrative == null);
            }

            [Fact]
            public async Task NarrativeNoIsSavedWithNarrativeText()
            {
                var narrativeText = Fixture.RandomString(300);
                var narrativeNo = Fixture.Short();
                var f = new DiaryUpdateFixture(Db);
                f.ChainUpdator.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).ReturnsForAnyArgs(Db.Set<Diary>().ToArray());
                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today().AddHours(1),
                    CaseKey = Fixture.Integer(),
                    Activity = Fixture.String(),
                    NarrativeText = narrativeText,
                    NarrativeNo = narrativeNo,
                    EntryDate = Fixture.Today(),
                    EntryNo = f.EntryNo,
                    StaffId = f.CurrentStaffId
                };
                var staffId = f.CurrentUser.NameId;
                await f.Subject.UpdateEntry(input);
                var entry = Db.Set<Diary>().Single(_ => _.EmployeeNo == staffId && _.EntryNo == f.EntryNo);
                await f.ValueTime.Received(1).For(Arg.Any<RecordableTime>(), "en-US");

                Assert.Equal(narrativeText, entry.LongNarrative);
                Assert.Equal(narrativeNo, entry.NarrativeNo);
            }

            [Fact]
            public async Task ReturnsErrorWhenEntryNotFound()
            {
                var f = new DiaryUpdateFixture(Db);
                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today(),
                    CaseKey = Fixture.Integer(),
                    Activity = Fixture.String(),
                    EntryDate = Fixture.Today(),
                    EntryNo = f.NextEntryNo
                };
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.UpdateEntry(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
                await Db.DidNotReceive().SaveChangesAsync();
                await f.ValueTime.DidNotReceiveWithAnyArgs().For(Arg.Any<RecordableTime>(), Arg.Any<string>());
            }

            [Fact]
            public async Task SaveTimeWithName()
            {
                var nameId = Fixture.Integer();
                var f = new DiaryUpdateFixture(Db);
                f.ChainUpdator.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).ReturnsForAnyArgs(Db.Set<Diary>().ToArray());
                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today(),
                    TotalTime = Fixture.Today().AddHours(1),
                    CaseKey = null,
                    NameKey = nameId,
                    Activity = Fixture.String(),
                    EntryDate = Fixture.Today(),
                    EntryNo = f.EntryNo,
                    StaffId = f.CurrentStaffId
                };
                var staffId = f.CurrentUser.NameId;
                await f.Subject.UpdateEntry(input);

                f.ChainUpdator.GetDownwardChain(Arg.Is<int>(_ => _ == f.CurrentStaffId), Arg.Is<DateTime>(_ => _ == input.EntryDate), Arg.Is<int>(_ => _ == f.EntryNo)).IgnoreAwaitForNSubstituteAssertion();
                f.ValueTime.Received(1).For(Arg.Any<RecordableTime>(), "en-US").IgnoreAwaitForNSubstituteAssertion();
                f.DebtorSplitUpdater.Received(1).UpdateSplits(Arg.Any<Diary>(), Arg.Any<IEnumerable<DebtorSplit>>());
                f.ChainUpdator.Received(1).UpdateData(Arg.Any<IEnumerable<Diary>>(), Arg.Any<Diary>(), Arg.Is<bool>(_ => _), Arg.Is<bool>(_ => _));
                Db.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();
                Assert.NotNull(Db.Set<Diary>().Single(_ => _.EmployeeNo == staffId && _.CaseId == null && _.NameNo == input.NameKey && _.Activity == input.Activity));
            }

            [Fact]
            public async Task ThrowsExceptionIfStaffIdNotProvided()
            {
                var f = new DiaryUpdateFixture(Db);

                var input = new RecordableTime
                {
                    StaffId = null
                };
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.UpdateEntry(input));
                Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ReturnsNullIfNoEntryNo()
            {
                var f = new DiaryUpdateFixture(Db);

                var input = new RecordableTime
                {
                    StaffId = 1,
                    EntryNo = null
                };
                Assert.Null(await f.Subject.UpdateEntry(input));
            }

            [Fact]
            public async Task UpdatesContinuedEntryForTime()
            {
                const short entryNo = 100;

                var f = new DiaryUpdateFixture(Db, false)
                    .WithContinuedEntry(entryNo);

                var input = new RecordableTime
                {
                    Start = Fixture.Today(),
                    Finish = Fixture.Today().AddMinutes(30),
                    TotalTime = Fixture.BaseDate().AddMinutes(30),
                    EntryDate = Fixture.Today(),
                    EntryNo = entryNo,
                    ParentEntryNo = entryNo - 1,
                    StaffId = f.CurrentStaffId
                };

                await f.Subject.UpdateEntry(input);
                f.ChainUpdator.Received(1).GetDownwardChain(input.StaffId.Value, input.EntryDate, input.EntryNo.Value).IgnoreAwaitForNSubstituteAssertion();
                f.ChainUpdator.Received(1).UpdateData(Arg.Is<IEnumerable<Diary>>(_ => _.Count() == 3), Arg.Any<Diary>(), true, true);
            }
        }

        public class UpdateDate : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionIfInvalidInput()
            {
                var input = new RecordableTime();
                var f = new DiaryUpdateFixture(Db);
                f.ChainUpdator.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).ReturnsForAnyArgs(Db.Set<Diary>().ToArray());
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.UpdateDate(input));

                input.StaffId = f.CurrentStaffId;
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.UpdateDate(input));

                input.EntryNo = f.EntryNo;
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.UpdateDate(input));

                input.Start = Fixture.Monday;
                Assert.NotNull(await f.Subject.UpdateDate(input));
            }

            [Fact]
            public async Task ThrowsExceptionIfInnerFunctionThrowsException()
            {
                var f = new DiaryUpdateFixture(Db, false);
                f.ChainUpdator.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>())
                 .ThrowsForAnyArgs(new Exception());

                var args = new RecordableTime {EntryDate = Fixture.Date(), EntryNo = f.NextEntryNo, Start = Fixture.Monday, StaffId = 1};
                await Assert.ThrowsAsync<Exception>(async () => await f.Subject.UpdateDate(args));
            }

            [Fact]
            public async Task UpdatesEntryDateAfterAllRequiredCallsForSingleEntry()
            {
                var f = new DiaryUpdateFixture(Db, false);
                f.WipWarningCheck.For(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(Task.FromResult(true));
                f.ValueTime.For(Arg.Any<RecordableTime>(), Arg.Any<string>()).ReturnsForAnyArgs(new TimeEntry {LocalValue = 100, StaffId = f.CurrentStaffId});

                var entryNo = Fixture.Integer();
                var diary = new DiaryBuilder(Db) {StaffId = f.CurrentStaffId, EntryNo = entryNo}.BuildWithCase();
                var args = new RecordableTime {EntryDate = Fixture.Date(), EntryNo = entryNo, Start = Fixture.Monday, StaffId = f.CurrentStaffId, CaseKey = 9};
                f.ChainUpdator.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).ReturnsForAnyArgs(new[] {diary});
                await f.Subject.UpdateDate(args);

                var newStartTime = args.EntryDate.Add(diary.StartTime.GetValueOrDefault().TimeOfDay);
                var newFinishTime = args.EntryDate.Add(diary.FinishTime.GetValueOrDefault().TimeOfDay);
                f.ChainUpdator.Received(1).GetDownwardChain(args.StaffId.Value, args.Start.Value, args.EntryNo.Value).IgnoreAwaitForNSubstituteAssertion();
                f.WipWarningCheck.Received(1).For(diary.CaseId, diary.NameNo).IgnoreAwaitForNSubstituteAssertion();
                f.ValueTime.Received(1).For(Arg.Is<RecordableTime>(_ => _.EntryNo.Value == diary.EntryNo && _.StaffId == diary.EmployeeNo), "en-US")
                 .IgnoreAwaitForNSubstituteAssertion();
                f.ChainUpdator.DidNotReceive().DateUpdated(Arg.Any<IEnumerable<Diary>>(), Arg.Any<DateTime>());

                var savedDiary = Db.Set<Diary>().Single();
                Assert.Equal(entryNo, savedDiary.EntryNo);
                Assert.Equal(newStartTime, savedDiary.StartTime);
                Assert.Equal(newFinishTime, savedDiary.FinishTime);
                Assert.Equal(100, savedDiary.TimeValue);
            }

            [Fact]
            public async Task UpdatesSplits()
            {
                var f = new DiaryUpdateFixture(Db, false);
                f.WipWarningCheck.For(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(Task.FromResult(true));
                var newSplits = new List<DebtorSplit> {new DebtorSplit {ChargeOutRate = 100, DebtorNameNo = 1, SplitPercentage = 90}, new DebtorSplit {ChargeOutRate = 150, DebtorNameNo = 2, SplitPercentage = 10}};
                f.ValueTime.For(Arg.Any<RecordableTime>(), Arg.Any<string>()).ReturnsForAnyArgs(new TimeEntry {LocalValue = 100, DebtorSplits = newSplits});

                var entryNo = Fixture.Integer();
                var diary = new DiaryBuilder(Db) {StaffId = f.CurrentStaffId, EntryNo = entryNo}.Build();

                var args = new RecordableTime {EntryDate = Fixture.Date(), EntryNo = entryNo, Start = Fixture.Monday, StaffId = f.CurrentStaffId, CaseKey = 9};
                f.ChainUpdator.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).ReturnsForAnyArgs(new[] {diary});
                await f.Subject.UpdateDate(args);

                f.DebtorSplitUpdater.Received(1).UpdateSplits(Arg.Is<Diary>(_ => _ == diary), Arg.Any<IEnumerable<DebtorSplit>>());
            }

            [Fact]
            public async Task CallsToUpdateRestofTheChainIfNeeded()
            {
                var f = new DiaryUpdateFixture(Db, false);
                f.WipWarningCheck.For(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(Task.FromResult(true));

                var diary1 = new DiaryBuilder(Db) {StaffId = f.CurrentStaffId, EntryNo = Fixture.Integer()}.Build();
                var diary2 = new DiaryBuilder(Db) {StaffId = f.CurrentStaffId, EntryNo = Fixture.Integer(), ParentEntryNo = diary1.EntryNo}.Build();
                var args = new RecordableTime {EntryDate = Fixture.Date(), EntryNo = diary2.EntryNo, Start = Fixture.Monday, StaffId = f.CurrentStaffId, CaseKey = 9};
                f.ChainUpdator.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).ReturnsForAnyArgs(new[] {diary2, diary1}.AsEnumerable());
                await f.Subject.UpdateDate(args);

                f.ChainUpdator.Received(1).DateUpdated(Arg.Is<IEnumerable<Diary>>(_ => _.Count() == 2), args.EntryDate);
            }
        }

        public class BatchUpdateNarratives : FactBase
        {
            [Theory]
            [InlineData(true, false)]
            [InlineData(false, true)]
            [InlineData(false, false)]
            [InlineData(true, false, true)]
            [InlineData(false, true, true)]
            [InlineData(false, false, true)]
            public async Task UpdatesNarrativeText(bool withLongNarrative, bool withShortNarrative, bool withSplits = false)
            {
                var narrativeText = withLongNarrative ? Fixture.RandomString(255) : withShortNarrative ? Fixture.RandomString(Fixture.Short(254)) : null;
                var f = new DiaryUpdateFixture(Db, withSplits: withSplits);
                var count = await f.Subject.BatchUpdateNarratives(f.CurrentUser.NameId, new[] {f.EntryNo, f.EntryNo + 1}, narrativeText);
                Assert.Equal(2, count);
                Assert.True(Db.Set<Diary>().All(_ => _.NarrativeNo == null && _.LongNarrative == (withLongNarrative ? narrativeText : null) && _.ShortNarrative == (withShortNarrative ? narrativeText : null)));
                Assert.True(Db.Set<DebtorSplitDiary>().All(_ => _.NarrativeNo == null && (_.Narrative == (withLongNarrative ? narrativeText : null) || _.Narrative == (withShortNarrative ? narrativeText : null))));
            }

            [Theory]
            [InlineData(true, false)]
            [InlineData(false, true)]
            [InlineData(false, false)]
            [InlineData(true, false, true)]
            [InlineData(false, true, true)]
            [InlineData(false, false, true)]
            public async Task UpdatesNarrativeNumber(bool withLongNarrative, bool withShortNarrative, bool withSplits = false)
            {
                var narrativeText = withLongNarrative ? Fixture.RandomString(255) : withShortNarrative ? Fixture.RandomString(Fixture.Short(254)) : null;
                var narrativeNo = Fixture.Short();
                var f = new DiaryUpdateFixture(Db, withSplits: withSplits);
                var count = await f.Subject.BatchUpdateNarratives(f.CurrentUser.NameId, new[] {f.EntryNo, f.EntryNo + 1}, narrativeText, narrativeNo);
                Assert.Equal(2, count);
                Assert.True(Db.Set<Diary>().All(_ => _.NarrativeNo == narrativeNo && _.LongNarrative == (withLongNarrative ? narrativeText : null) && _.ShortNarrative == (withShortNarrative ? narrativeText : null)));
                Assert.True(Db.Set<DebtorSplitDiary>().All(_ => _.NarrativeNo == narrativeNo && (_.Narrative == (withLongNarrative ? narrativeText : null) || _.Narrative == (withShortNarrative ? narrativeText : null))));
            }
        }

        public class DeleteEntry : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionIfInvalidInput()
            {
                var f = new DiaryUpdateFixture(Db);
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.DeleteEntry(new RecordableTime {StaffId = null}));
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.DeleteEntry(new RecordableTime {StaffId = 1, EntryNo = null}));
            }

            [Fact]
            public async Task CallsRelevantFunctions()
            {
                var f = new DiaryUpdateFixture(Db);
                var input = new RecordableTime {StaffId = 1, EntryNo = 1, Start = Fixture.Today(), TotalTime = new DateTime(1899, 1, 1, 1, 0, 0), EntryDate = Fixture.Today()};
                var diary1 = new Diary {EntryNo = 1, EmployeeNo = input.StaffId.Value};
                var diary2 = new Diary {EntryNo = 2, EmployeeNo = input.StaffId.Value, ParentEntryNo = 1};
                f.ChainUpdator.GetWholeChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).ReturnsForAnyArgs(new[] {diary2, diary1}.AsEnumerable());
                f.ChainUpdator.RemoveEntryFromChain(Arg.Any<IEnumerable<Diary>>(), Arg.Any<int>()).ReturnsForAnyArgs(Task.FromResult((diary1, diary2)));

                await f.Subject.DeleteEntry(input);
                f.ChainUpdator.Received(1).GetWholeChain(Arg.Is<int>(_ => _ == input.StaffId), Arg.Is<DateTime>(_ => _ == input.EntryDate), Arg.Is<int>(_ => _ == input.EntryNo)).IgnoreAwaitForNSubstituteAssertion();
                f.ChainUpdator.RemoveEntryFromChain(Arg.Is<IEnumerable<Diary>>(_ => _.First() == diary2 && _.Last() == diary1), Arg.Is<int>(_ => _ == input.EntryNo)).IgnoreAwaitForNSubstituteAssertion();
                f.DebtorSplitUpdater.Received(1).PurgeSplits(Arg.Is<Diary>(_ => _ == diary1));
                f.ValueTime.Received(1).For(Arg.Is<RecordableTime>(_ => _.EntryNo == 2), "en-US").IgnoreAwaitForNSubstituteAssertion();
                f.DebtorSplitUpdater.Received(1).UpdateSplits(Arg.Is<Diary>(_ => _ == diary2), Arg.Any<IEnumerable<DebtorSplit>>());
                Db.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class DeleteChainFor : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionIfInvalidInput()
            {
                var f = new DiaryUpdateFixture(Db);
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.DeleteChainFor(new RecordableTime {StaffId = null}));
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.DeleteChainFor(new RecordableTime {StaffId = 1, EntryNo = null}));
                await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.DeleteChainFor(new RecordableTime {StaffId = 1, EntryNo = 1, Start = null}));
            }

            [Fact]
            public async Task PerformsDataUpdate()
            {
                var f = new DiaryUpdateFixture(Db, false);
                var diary1 = new Diary {EntryNo = 1, EmployeeNo = 11, StartTime = Fixture.Today().AddHours(1)}.In(Db);
                var diary2 = new Diary {EntryNo = 2, EmployeeNo = 11, ParentEntryNo = 1, StartTime = Fixture.Today().AddHours(2)}.In(Db);
                var diary3 = new Diary {EntryNo = 3, EmployeeNo = 11, ParentEntryNo = 2, StartTime = Fixture.Today().AddHours(3)}.In(Db);
                f.ChainUpdator.GetWholeChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).ReturnsForAnyArgs(new[] {diary3, diary2, diary1});

                Assert.Equal(3, Db.Set<Diary>().Count());

                await f.Subject.DeleteChainFor(new RecordableTime {StaffId = 11, EntryDate = Fixture.Today(), EntryNo = 2, Start = Fixture.Today().AddHours(2)});

                Assert.Equal(0, Db.Set<Diary>().Count());
            }
        }

        public class DiaryUpdateFixture : IFixture<DiaryUpdate>
        {
            public DiaryUpdateFixture(InMemoryDbContext db, bool withEntries = true, bool withSplits = false)
            {
                Now = Substitute.For<Func<DateTime>>();
                Now().Returns(Fixture.Today());

                DbContext = db;
                EntryNo = Fixture.Short();
                NextEntryNo = EntryNo + 2;
                CurrentUser = new UserBuilder(db).Build();
                ValueTime = Substitute.For<IValueTime>();
                WipWarningCheck = Substitute.For<IWipWarningCheck>();
                ChainUpdator = Substitute.For<IChainUpdater>();
                DebtorSplitUpdater = Substitute.For<IDebtorSplitUpdater>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                PreferredCultureResolver.Resolve().Returns("en-US");

                var m = new Mapper(new MapperConfiguration(cfg =>
                {
                    cfg.AddProfile(new AccountingProfile());
                    cfg.CreateMissingTypeMaps = true;
                }));
                Mapper = m.DefaultContext.Mapper.DefaultContext.Mapper;

                Subject = new DiaryUpdate(db, Mapper, ValueTime, Now, ChainUpdator, WipWarningCheck, DebtorSplitUpdater, PreferredCultureResolver);

                if (!withEntries) return;
                new DiaryBuilder(db) {StaffId = CurrentUser.NameId, EntryNo = EntryNo}.BuildWithCase();
                var diary2 = new DiaryBuilder(db) {StaffId = CurrentUser.NameId, EntryNo = EntryNo + 1}.BuildWithCase();

                if (!withSplits) return;
                new DebtorSplitDiary {EmployeeNo = diary2.EmployeeNo, EntryNo = diary2.EntryNo, DebtorNameNo = diary2.Case.CaseNames.First().NameId}.In(db);
                new DebtorSplitDiary {EmployeeNo = diary2.EmployeeNo, EntryNo = diary2.EntryNo, DebtorNameNo = diary2.Case.CaseNames.Last().NameId}.In(db);
            }

            InMemoryDbContext DbContext { get; }
            public IValueTime ValueTime { get; }
            public IWipWarningCheck WipWarningCheck { get; }
            public IChainUpdater ChainUpdator { get; }
            public int NextEntryNo { get; }
            public IMapper Mapper { get; }
            public int EntryNo { get; }
            public User CurrentUser { get; }
            public int CurrentStaffId => CurrentUser.NameId;
            public Func<DateTime> Now { get; set; }
            public IDebtorSplitUpdater DebtorSplitUpdater { get; set; }
            public IPreferredCultureResolver PreferredCultureResolver { get; set; }
            public DiaryUpdate Subject { get; }

            public DiaryUpdateFixture WithContinuedEntry(short entryNo)
            {
                var entryParent1 = new DiaryBuilder(DbContext) {StaffId = CurrentUser.NameId, EntryNo = entryNo - 2}.BuildWithCase();

                var entryParent2 = new DiaryBuilder(DbContext) {StaffId = CurrentUser.NameId, EntryNo = entryNo - 1, ParentEntryNo = entryParent1.EntryNo}.BuildWithCase();
                entryParent2.TimeCarriedForward = entryParent1.TotalTime;

                var entryChild = new DiaryBuilder(DbContext) {StaffId = CurrentUser.NameId, EntryNo = entryNo, ParentEntryNo = entryParent2.EntryNo}.BuildWithCase();
                entryChild.TimeCarriedForward = entryParent2.TotalTime.GetValueOrDefault().Add(entryParent2.TimeCarriedForward.GetValueOrDefault().TimeOfDay);

                ChainUpdator.GetDownwardChain(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>()).ReturnsForAnyArgs(new[] {entryChild, entryParent2, entryParent1});

                return this;
            }
        }
    }
}