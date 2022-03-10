using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Accounting;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class TimesheetListFacts
    {
        public class ForMethod : FactBase
        {
            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task FlagsIncompleteWhenCaseOnlySiteControlOnAndNoCase(bool isCaseOnlyTime)
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();
                var entry = new Diary
                {
                    StartTime = today.AddHours(8),
                    FinishTime = today.AddHours(8).AddMinutes(30),
                    TotalTime = DateTime.MinValue.AddMinutes(30),
                    ShortNarrative = Fixture.String(),
                    Notes = Fixture.String(),
                    EmployeeNo = staffId,
                    EntryNo = Fixture.Short(),
                    Name = new NameBuilder(Db).Build().In(Db),
                    ActivityDetail = new WipTemplate {Description = Fixture.String(), WipCode = Fixture.RandomString(6)}.In(Db),
                    DebtorSplits = new List<DebtorSplitDiary>()
                }.In(Db);
                new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer()}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, TransNo = Fixture.Integer()}.BuildWithCase();
                var f = new TimesheetListFixture(Db).WithDisplayNamesFor(new[] {entry.Name});
                f.SiteControlReader.Read<bool>(SiteControls.CASEONLY_TIME).Returns(isCaseOnlyTime);
                var result = await f.Subject.For(staffId, today);
                var timeEntries = result as TimeEntry[] ?? result.ToArray();
                Assert.Equal(isCaseOnlyTime, timeEntries.Any(_ => _.IsIncomplete));
            }

            [Fact]
            public async Task ChecksCaseOnlyTimeSiteControl()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();
                var f = new TimesheetListFixture(Db);
                await f.Subject.For(staffId, today);
                f.SiteControlReader.Received(1).Read<bool>(SiteControls.CASEONLY_TIME);
            }

            [Fact]
            public async Task EnsurePreferredCultureIsUsed()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();
                var f = new TimesheetListFixture(Db);
                await f.Subject.For(staffId, today);
                f.PreferredCultureResolver.Received(1).Resolve();
            }

            [Fact]
            public async Task FlagsIncompleteWhenNoActivity()
            {
                var staffId = Fixture.Integer();    
                var today = Fixture.Today();
                var incompleteDiary = new Diary
                {
                    StartTime = today.AddHours(8),
                    FinishTime = today.AddHours(8).AddMinutes(30),
                    TotalTime = DateTime.MinValue.AddMinutes(30),
                    ShortNarrative = Fixture.String(),
                    Notes = Fixture.String(),
                    EmployeeNo = staffId,
                    EntryNo = Fixture.Short(),
                    Name = new NameBuilder(Db).Build().In(Db),
                    DebtorSplits = new List<DebtorSplitDiary>()
                }.In(Db);
                new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer()}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, TransNo = Fixture.Integer()}.BuildWithCase();
                var debtorDiary = new DiaryBuilder(Db) {StaffId = staffId}.Build();

                var f = new TimesheetListFixture(Db).WithDisplayNamesFor(new[] {incompleteDiary.Name, debtorDiary.Name});
                var result = await f.Subject.For(staffId, today);
                var match = result.Single(_ => _.IsIncomplete);
                Assert.Equal(incompleteDiary.EntryNo, match.EntryNo);
            }

            [Fact]
            public async Task FlagsIncompleteWhenNoCaseOrName()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();
                var incompleteDiary = new Diary
                {
                    StartTime = today.AddHours(8),
                    FinishTime = today.AddHours(8).AddMinutes(30),
                    TotalTime = DateTime.MinValue.AddMinutes(30),
                    ShortNarrative = Fixture.String(),
                    Notes = Fixture.String(),
                    EmployeeNo = staffId,
                    EntryNo = Fixture.Short(),
                    ActivityDetail = new WipTemplate {Description = Fixture.String(), WipCode = Fixture.RandomString(6)}.In(Db),
                    DebtorSplits = new List<DebtorSplitDiary>()
                }.In(Db);
                new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer()}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, TransNo = Fixture.Integer()}.BuildWithCase();
                var debtorDiary = new DiaryBuilder(Db) {StaffId = staffId}.Build();

                var f = new TimesheetListFixture(Db).WithDisplayNamesFor(new[] {debtorDiary.Name});
                var result = await f.Subject.For(staffId, today);
                var match = result.Single(_ => _.IsIncomplete);
                Assert.Equal(incompleteDiary.EntryNo, match.EntryNo);
            }

            [Fact]
            public async Task FlagsIncompleteWhenNoTotalTime()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();

                var incompleteDiary = new Diary
                {
                    StartTime = today.AddHours(8),
                    FinishTime = today.AddHours(8).AddMinutes(30),
                    TotalTime = today.AddHours(0).AddMinutes(0).AddSeconds(0),
                    ShortNarrative = Fixture.String(),
                    Notes = Fixture.String(),
                    EmployeeNo = staffId,
                    EntryNo = Fixture.Short(),
                    Name = new NameBuilder(Db).Build().In(Db),
                    ActivityDetail = new WipTemplate {Description = Fixture.String(), WipCode = Fixture.RandomString(6)}.In(Db),
                    DebtorSplits = new List<DebtorSplitDiary>()
                }.In(Db);
                new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer()}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, TransNo = Fixture.Integer()}.BuildWithCase();
                var debtorDiary = new DiaryBuilder(Db) {StaffId = staffId}.Build();

                var f = new TimesheetListFixture(Db).WithDisplayNamesFor(new[] {incompleteDiary.Name, debtorDiary.Name});
                var result = await f.Subject.For(staffId, today);
                var timeEntries = result as TimeEntry[] ?? result.ToArray();
                var match = timeEntries.Single(_ => _.IsIncomplete);
                Assert.Equal(incompleteDiary.EntryNo, match.EntryNo);
            }

            [Fact]
            public async Task FlagsPostedTime()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();
                var postedDiary = new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer(), TransNo = Fixture.Integer(), EntryNo = Fixture.Short()}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntityId = Fixture.Integer()}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, TransNo = Fixture.Integer()}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId}.BuildWithCase();

                var f = new TimesheetListFixture(Db);
                var result = await f.Subject.For(staffId, today);
                var timeEntries = result as TimeEntry[] ?? result.ToArray();
                var match = timeEntries.Single(_ => _.IsPosted);
                Assert.Equal(postedDiary.EntryNo, match.EntryNo);
                Assert.True(timeEntries.All(_ => !_.IsIncomplete));
            }

            [Fact]
            public async Task ReturnsCaseInstructor()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();

                var activity = new WipTemplate {Description = Fixture.String(), WipCode = Fixture.RandomString(6)}.In(Db);
                var @case = new CaseBuilder().Build().In(Db);
                var name = new NameBuilder(Db).Build().In(Db);
                new DiaryBuilder(Db).BuildWithCase();
                var diary = new DiaryBuilder(Db)
                {
                    Activity = activity,
                    Case = @case,
                    Instructor = name,
                    StaffId = staffId
                }.BuildWithCase();
                var f = new TimesheetListFixture(Db).WithDisplayNamesFor(new[] {name});
                var result = await f.Subject.For(staffId, today);
                var match = result.Single();
                Assert.Equal(activity.Description, match.Activity);
                Assert.Equal(@case.Irn, match.CaseReference);
                Assert.Equal(name.Formatted(), match.Name);
                Assert.Equal(diary.ShortNarrative, match.NarrativeText);
                Assert.Equal(diary.Notes, match.Notes);
            }

            [Fact]
            public async Task ReturnsDebtorWhereNoCase()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();

                var activity = new WipTemplate {Description = Fixture.String(), WipCode = Fixture.RandomString(6)}.In(Db);
                var debtor = new NameBuilder(Db).Build().In(Db);
                new DiaryBuilder(Db).Build();
                var diary = new DiaryBuilder(Db)
                {
                    Activity = activity,
                    Debtor = debtor,
                    StaffId = staffId
                }.Build();
                var f = new TimesheetListFixture(Db).WithDisplayNamesFor(new[] {debtor});
                var result = await f.Subject.For(staffId, today);
                var match = result.Single();
                Assert.Equal(activity.Description, match.Activity);
                Assert.Null(match.CaseReference);
                Assert.Equal(debtor.Formatted(), match.Name);
                Assert.Equal(diary.ShortNarrative, match.NarrativeText);
                Assert.Equal(diary.Notes, match.Notes);
            }

            [Fact]
            public async Task ReturnsDiaryForSpecifiedDate()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();

                var activity = new WipTemplate {Description = Fixture.String(), WipCode = Fixture.RandomString(6)}.In(Db);
                var debtor = new NameBuilder(Db).Build().In(Db);
                var diary = new DiaryBuilder(Db) {StaffId = staffId}.BuildWithCase();
                new Diary
                {
                    StartTime = Fixture.PastDate(),
                    FinishTime = Fixture.PastDate().AddHours(8).AddMinutes(30),
                    TotalTime = DateTime.MinValue.AddMinutes(30),
                    Name = debtor,
                    ActivityDetail = activity,
                    ShortNarrative = Fixture.String(),
                    Notes = Fixture.String(),
                    EmployeeNo = staffId
                }.In(Db);

                var f = new TimesheetListFixture(Db);
                var result = await f.Subject.For(staffId, today);
                var match = result.Single();
                Assert.Equal(staffId, match.StaffId);
                Assert.Equal(today.Date, match.StartTime.GetValueOrDefault().Date);
                Assert.Equal(diary.ActivityDetail.Description, match.Activity);
                Assert.Equal(diary.ShortNarrative, match.NarrativeText);
                Assert.Equal(diary.Notes, match.Notes);
                Assert.Equal(today.Date, match.EntryDate);
            }

            [Fact]
            public async Task ReturnsDiaryForSpecifiedStaff()
            {
                var staffId = Fixture.Integer();
                var otherStaff = Fixture.Integer();
                var today = Fixture.Today();

                var diary = new DiaryBuilder(Db) {StaffId = staffId}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = otherStaff}.BuildWithCase();

                var f = new TimesheetListFixture(Db);
                var result = await f.Subject.For(staffId, today);
                var match = result.Single();
                Assert.Equal(staffId, match.StaffId);
                Assert.Equal(diary.ActivityDetail.Description, match.Activity);
                Assert.Equal(diary.ShortNarrative, match.NarrativeText);
                Assert.Equal(diary.Notes, match.Notes);
            }

            [Fact]
            public async Task DisplayDefaultNarrativeTextFromSelectedNarrative()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();
                var f = new TimesheetListFixture(Db);
                new Diary
                {
                    StartTime = today.AddHours(8),
                    FinishTime = today.AddHours(8).AddMinutes(30),
                    TotalTime = DateTime.MinValue.AddMinutes(30),
                    Narrative = f.Narrative,
                    Notes = Fixture.String(),
                    EmployeeNo = staffId,
                    EntryNo = Fixture.Short(),
                    Name = new NameBuilder(Db).Build().In(Db),
                    DebtorSplits = new List<DebtorSplitDiary>()
                }.In(Db);

                var result = await f.Subject.For(staffId, today);
                var match = result.Single();
                Assert.Equal(f.Narrative.NarrativeText, match.NarrativeText);
            }

            [Fact]
            public async Task DisplaysSavedNarrativeTextWhereAvailable()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();
                var narrativeText = Fixture.RandomString(100);
                var f = new TimesheetListFixture(Db);
                new Diary
                {
                    Case = null,
                    StartTime = today.AddHours(8),
                    FinishTime = today.AddHours(8).AddMinutes(30),
                    TotalTime = DateTime.MinValue.AddMinutes(30),
                    NarrativeNo = f.Narrative.NarrativeId,
                    ShortNarrative = narrativeText,
                    Notes = Fixture.String(),
                    EmployeeNo = staffId,
                    EntryNo = Fixture.Short(),
                    Name = new NameBuilder(Db).Build().In(Db),
                    DebtorSplits = new List<DebtorSplitDiary>()
                }.In(Db);

                var result = await f.Subject.For(staffId, today);
                var match = result.Single();
                Assert.Equal(narrativeText, match.NarrativeText);
            }

            [Fact]
            public async Task ReturnsDiaryEntriesInCorrectOrder()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();

                new DiaryBuilder(Db) {StaffId = staffId, StartTime = today.AddHours(2), NarrativeText = "first"}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, StartTime = today.AddHours(1), NarrativeText = "second"}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, StartTime = today.Date, FinishTime = today.Date, NarrativeText = "fourth"}.BuildWithCase(asHoursOnlyTime: true);
                new DiaryBuilder(Db) {StaffId = staffId, StartTime = today.Date, FinishTime = today.Date, NarrativeText = "fifth"}.BuildWithCase(asHoursOnlyTime: true);
                new DiaryBuilder(Db) {StaffId = staffId, StartTime = today.AddMinutes(30), NarrativeText = "third"}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, StartTime = today.Date, FinishTime = today.Date, NarrativeText = "last"}.BuildWithCase(asHoursOnlyTime: true);

                var f = new TimesheetListFixture(Db);
                var result = await f.Subject.For(staffId, today);
                var timeEntries = result as TimeEntry[] ?? result.ToArray();
                Assert.Equal(6, timeEntries.Length);
                Assert.Equal("first", timeEntries[0].NarrativeText);
                Assert.Equal("second", timeEntries[1].NarrativeText);
                Assert.Equal("third", timeEntries[2].NarrativeText);
                Assert.Equal("fourth", timeEntries[3].NarrativeText);
                Assert.Equal("fifth", timeEntries[4].NarrativeText);
                Assert.Equal("last", timeEntries[5].NarrativeText);
            }
        }

        public class DiaryForMethod : FactBase
        {
            [Fact]
            public void ReturnsEmptyIfNoDiaryEntries()
            {
                var f = new TimesheetListFixture(Db);
                var result = f.Subject.DiaryFor(10, Fixture.Today()).AsEnumerable();

                Assert.Empty(result);
            }

            [Fact]
            public void ReturnsQueryableForSpecifiedStaffOnly()
            {
                var staffId = Fixture.Integer();
                var otherStaff = Fixture.Integer();
                var today = Fixture.Today();

                new DiaryBuilder(Db) {StaffId = staffId}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = otherStaff}.BuildWithCase();

                var f = new TimesheetListFixture(Db);
                var result = f.Subject.DiaryFor(staffId, today);
                var match = result.Single();

                Assert.Equal(staffId, match.EmployeeNo);
            }

            [Fact]
            public void ReturnsQueryableForSpecifiedDateOnly()
            {
                var staffId = Fixture.Integer();

                var diary1 = new DiaryBuilder(Db) {StaffId = staffId}.BuildWithCase();
                diary1.StartTime = Fixture.Monday;
                diary1.FinishTime = Fixture.Monday.AddHours(1);

                var diary2 = new DiaryBuilder(Db) {StaffId = staffId}.BuildWithCase();
                diary2.StartTime = Fixture.Tuesday;
                diary2.FinishTime = Fixture.Tuesday.AddHours(1);

                var f = new TimesheetListFixture(Db);
                var result = f.Subject.DiaryFor(staffId, Fixture.Monday);

                Assert.Equal(1, result.Count());
            }
        }

        public class TimeGapForMethod : FactBase
        {
            [Fact]
            public async Task ReturnsGapsForSelectedStaffOnly()
            {
                var staffId = Fixture.Integer();
                var otherStaff = Fixture.Integer();
                var today = Fixture.Today();

                new DiaryBuilder(Db) {StaffId = otherStaff, StartTime = today.AddHours(1), FinishTime = today.AddHours(4)}.Build();

                var f = new TimesheetListFixture(Db);
                var gaps = await f.Subject.TimeGapFor(staffId, today);
                Assert.Equal(1, gaps.Count());

                var gapsForOther = await f.Subject.TimeGapFor(otherStaff, today);
                Assert.Equal(2, gapsForOther.Count());
            }

            [Fact]
            public async Task ReturnsGapsForSelectedDateOnly()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();

                new DiaryBuilder(Db) {StaffId = staffId, StartTime = today.AddHours(1), FinishTime = today.AddHours(4)}.Build();

                var f = new TimesheetListFixture(Db);
                var gapsForToday = await f.Subject.TimeGapFor(staffId, today);
                Assert.Equal(2, gapsForToday.Count());

                var gapsForYesterday = await f.Subject.TimeGapFor(staffId, today.AddDays(-1));
                Assert.Equal(1, gapsForYesterday.Count());
            }

            [Fact]
            public async Task ReturnsCorrectGaps()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();

                var entry1 = new DiaryBuilder(Db) {StaffId = staffId, StartTime = today.AddHours(1), FinishTime = today.AddHours(4)}.Build();
                var entry2 = new DiaryBuilder(Db) {StaffId = staffId, StartTime = today.AddHours(6), FinishTime = today.AddHours(7)}.Build();
                var entry3 = new DiaryBuilder(Db) {StaffId = staffId, StartTime = today.AddHours(7), FinishTime = today.Add(new TimeSpan(8, 30, 30))}.Build();

                var f = new TimesheetListFixture(Db);
                var gaps = (await f.Subject.TimeGapFor(staffId, today)).ToList();

                Assert.Equal(3, gaps.Count);
                Assert.Equal(entry1.FinishTime, gaps.Skip(1).First().StartTime);
                Assert.Equal(entry2.StartTime, gaps.Skip(1).First().FinishTime);

                Assert.Equal(entry3.FinishTime, gaps.Last().StartTime);
            }

            [Fact]
            public async Task ConsidersBeforeAndAfterGapsFromDiaryEntries()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();

                var entryStartTime = today.AddHours(1);
                var entryFinishTime = today.AddHours(4);
                new DiaryBuilder(Db) {StaffId = staffId, StartTime = entryStartTime, FinishTime = entryFinishTime}.Build();

                var f = new TimesheetListFixture(Db);
                var gaps = (await f.Subject.TimeGapFor(staffId, today)).ToList();

                Assert.Equal(2, gaps.Count);
                Assert.Equal(today, gaps.First().StartTime);
                Assert.Equal(entryStartTime, gaps.First().FinishTime);

                Assert.Equal(entryFinishTime, gaps.Last().StartTime);
                Assert.Equal(today.Add(new TimeSpan(23, 59, 59)), gaps.Last().FinishTime);
            }

            [Fact]
            public async Task ReturnsSingleGapIfNoDiaryEntries()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();

                var f = new TimesheetListFixture(Db);
                var gaps = await f.Subject.TimeGapFor(staffId, today);
                Assert.Equal(1, gaps.Count());
            }

            [Fact]
            public async Task IgnoresGapsLessThanOneMinute()
            {
                var staffId = Fixture.Integer();
                var today = Fixture.Today();

                var entry1 = new DiaryBuilder(Db) {StaffId = staffId, StartTime = today.AddHours(1), FinishTime = today.Add(new TimeSpan(2, 30, 30))}.Build();
                var entry2 = new DiaryBuilder(Db) {StaffId = staffId, StartTime = today.Add(new TimeSpan(2, 31, 00)), FinishTime = today.AddHours(10)}.Build();

                var f = new TimesheetListFixture(Db);
                var gaps = (await f.Subject.TimeGapFor(staffId, today)).ToList();

                Assert.Equal(2, gaps.Count);
                Assert.Equal(entry1.StartTime, gaps.First().FinishTime);
                Assert.Equal(entry2.FinishTime, gaps.Last().StartTime);
            }
        }

        public class SearchForMethod : FactBase
        {
            [Fact]
            public void ReturnsForSpecificStaff()
            {
                var staffId = Fixture.Integer();
                var entryNo = Fixture.Short();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId + 1, EntryNo = entryNo + 1}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId + 1, EntryNo = entryNo + 2}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 3}.BuildWithCase();
                var f = new TimesheetListFixture(Db);
                var result = f.Subject.SearchFor(new TimeSearchParams {StaffId = staffId});
                var timeEntries = result.ToArray();
                Assert.Equal(2, timeEntries.Length);
                Assert.NotNull(timeEntries.Single(_ => _.StaffId == staffId && _.EntryNo == entryNo));
                Assert.NotNull(timeEntries.Single(_ => _.StaffId == staffId && _.EntryNo == entryNo + 3));
            }

            [Theory]
            [InlineData(true, true, 3)]
            [InlineData(false, true, 4)]
            [InlineData(true, false, 4)]
            [InlineData(false, false, 5)]
            public void ReturnsForSpecificDates(bool withFromDate, bool withToDate, int expected)
            {
                var staffId = Fixture.Integer();
                var entryNo = Fixture.Short();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo, StartTime = Fixture.PastDate().AddHours(8)}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 1, StartTime = Fixture.Today().AddHours(8)}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 2, StartTime = Fixture.FutureDate().AddHours(8)}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId + 1, EntryNo = entryNo + 3}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId + 1, EntryNo = entryNo + 4}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 5, StartTime = Fixture.PastDate().AddDays(-1)}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 6, StartTime = Fixture.FutureDate().AddDays(1)}.BuildWithCase();
                var f = new TimesheetListFixture(Db);
                var result = f.Subject.SearchFor(new TimeSearchParams
                {
                    StaffId = staffId,
                    FromDate = withFromDate ? Fixture.PastDate() : (DateTime?) null,
                    ToDate = withToDate ? Fixture.FutureDate() : (DateTime?) null
                });
                Assert.Equal(expected, result.Count());
            }

            [Theory]
            [InlineData(true, false, 2)]
            [InlineData(true, true, 3)]
            [InlineData(false, true, 1)]
            public void ReturnsForPostedOrUnpostedTime(bool isPosted, bool isUnposted, int expected)
            {
                var staffId = Fixture.Integer();
                var entryNo = Fixture.Short();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo, StartTime = Fixture.PastDate().AddHours(8)}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 1, StartTime = Fixture.Today().AddHours(8), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 2, StartTime = Fixture.FutureDate().AddHours(8), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId + 1, EntryNo = entryNo + 3}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId + 1, EntryNo = entryNo + 4}.BuildWithCase();
                var f = new TimesheetListFixture(Db);
                var result = f.Subject.SearchFor(new TimeSearchParams
                {
                    StaffId = staffId,
                    IsPosted = isPosted,
                    IsUnposted = isUnposted
                });
                Assert.Equal(expected, result.Count());
            }

            [Fact]
            public void ReturnsForEntity()
            {
                var entityId = Fixture.Integer();
                var staffId = Fixture.Integer();
                var entryNo = Fixture.Short();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo, EntityId = entityId}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 1, StartTime = Fixture.Today().AddHours(8), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 2, StartTime = Fixture.FutureDate().AddHours(8), EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId + 1, EntryNo = entryNo + 3, EntityId = entityId}.BuildWithCase();
                var f = new TimesheetListFixture(Db);
                var result = f.Subject.SearchFor(new TimeSearchParams
                {
                    StaffId = staffId,
                    Entity = entityId
                });
                var timeEntries = result.ToList();
                Assert.Equal(1, timeEntries.Count);
                Assert.Equal(entryNo, timeEntries.First().EntryNo);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public void ReturnsForCases(bool hasCases)
            {
                var case1 = new CaseBuilder().Build().In(Db);
                var case2 = new CaseBuilder().Build().In(Db);
                var case3 = new CaseBuilder().Build().In(Db);
                var staffId = Fixture.Integer();
                var entryNo = Fixture.Short();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo, Case = case1}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 1, Case = case2}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 2, Case = case3}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 3}.Build();
                new DiaryBuilder(Db) {StaffId = staffId + 1, EntryNo = entryNo + 4, Case = case1}.BuildWithCase();
                var f = new TimesheetListFixture(Db);
                var result = f.Subject.SearchFor(new TimeSearchParams
                {
                    StaffId = staffId,
                    CaseIds = hasCases ? new[] {case1.Id, case2.Id, (int?) case3.Id} : null
                });
                var timeEntries = result.ToList();
                Assert.Equal(hasCases ? 3 : 4, timeEntries.Count);
                Assert.NotNull(timeEntries.SingleOrDefault(_ => _.CaseKey == case1.Id && _.EntryNo == entryNo));
                Assert.NotNull(timeEntries.SingleOrDefault(_ => _.CaseKey == case2.Id && _.EntryNo == entryNo + 1));
                Assert.NotNull(timeEntries.SingleOrDefault(_ => _.CaseKey == case3.Id && _.EntryNo == entryNo + 2));
                if (!hasCases)
                {
                    Assert.NotNull(timeEntries.SingleOrDefault(_ => _.EntryNo == entryNo + 3));
                }
            }

            [Theory]
            [InlineData(false, true, 1)]
            [InlineData(true, false, 2)]
            [InlineData(true, true, 3)]
            public void ReturnsForNameAsDebtorAndInstructor(bool asDebtor, bool asInstructor, int expected)
            {
                var staffId = Fixture.Integer();
                var entryNo = Fixture.Short();
                var debtor = new NameBuilder(Db).Build().In(Db);
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo, Debtor = debtor}.Build();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 1, Debtor = debtor}.Build();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 2, Instructor = debtor}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId + 1, EntryNo = entryNo + 3, Debtor = debtor}.Build();
                new DiaryBuilder(Db) {StaffId = staffId + 1, EntryNo = entryNo + 4, Instructor = debtor}.BuildWithCase();
                var f = new TimesheetListFixture(Db);
                var result = f.Subject.SearchFor(new TimeSearchParams
                {
                    StaffId = staffId,
                    NameId = debtor.Id,
                    AsDebtor = asDebtor,
                    AsInstructor = asInstructor
                });
                var timeEntries = result.ToList();
                Assert.Equal(expected, timeEntries.Count);
                Assert.True(timeEntries.All(_ => _.NameKey == debtor.Id));
            }

            [Fact]
            public void ReturnsForActivity()
            {
                var staffId = Fixture.Integer();
                var entryNo = Fixture.Short();
                var activity = new WipTemplate {Description = Fixture.String(), WipCode = Fixture.RandomString(6)}.In(Db);
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo, Activity = activity}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 1, Activity = activity}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 2}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId + 1, EntryNo = entryNo + 3, Activity = activity}.Build();
                var f = new TimesheetListFixture(Db);
                var result = f.Subject.SearchFor(new TimeSearchParams
                {
                    StaffId = staffId,
                    ActivityId = activity.WipCode
                });
                var timeEntries = result.ToList();
                Assert.Equal(2, timeEntries.Count);
                Assert.True(timeEntries.All(_ => _.ActivityKey == activity.WipCode));
                Assert.NotNull(timeEntries.SingleOrDefault(_ => _.ActivityKey == activity.WipCode && _.EntryNo == entryNo));
                Assert.NotNull(timeEntries.SingleOrDefault(_ => _.ActivityKey == activity.WipCode && _.EntryNo == entryNo + 1));
            }

            [Theory]
            [InlineData(true, true, 4)]
            [InlineData(true, false, 2)]
            [InlineData(false, true, 2)]
            public void SkipsTimerAndParentEntries(bool posted, bool unposted, int total)
            {
                var staffId = Fixture.Integer();
                var entryNo = Fixture.Short();
                var activity = new WipTemplate {Description = Fixture.String(), WipCode = Fixture.RandomString(6)}.In(Db);
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo, IsTimer = true, Activity = activity}.Build();
                new Diary
                {
                    StartTime = Fixture.Today().AddHours(8),
                    TotalTime = null,
                    EntryNo = entryNo + 1,
                    IsTimer = 0,
                    ActivityDetail = activity,
                    Name = new NameBuilder(Db).Build().In(Db)
                }.In(Db);
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 2, Activity = activity}.Build();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 3, Activity = activity}.BuildWithCase();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 4, Activity = activity, EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.Build();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 5, Activity = activity, EntityId = Fixture.Integer(), TransNo = Fixture.Integer()}.BuildWithCase();
                var f = new TimesheetListFixture(Db);
                var result = f.Subject.SearchFor(new TimeSearchParams
                {
                    StaffId = staffId,
                    ActivityId = activity.WipCode,
                    IsPosted = posted,
                    IsUnposted = unposted
                });
                var timeEntries = result.ToList();
                Assert.Equal(total, timeEntries.Count);
                Assert.True(timeEntries.All(_ => _.ActivityKey == activity.WipCode));
                Assert.NotNull(timeEntries.SingleOrDefault(_ => _.ActivityKey == activity.WipCode && _.EntryNo == entryNo + (posted ? 4 : 2)));
                Assert.NotNull(timeEntries.SingleOrDefault(_ => _.ActivityKey == activity.WipCode && _.EntryNo == entryNo + (posted ? 5 : 3)));
            }

            [Fact]
            public void ReturnsForNarrative()
            {
                var staffId = Fixture.Integer();
                var narrativeSearch = Fixture.String();
                var entryNo = Fixture.Short();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo, NarrativeText = narrativeSearch}.Build();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 1, NarrativeText = $"ABC - xyz {narrativeSearch} 123-450"}.Build();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 2, LongNarrativeText = Fixture.String(narrativeSearch)}.Build();
                new DiaryBuilder(Db) {StaffId = staffId, EntryNo = entryNo + 3}.BuildWithCase();
                var f = new TimesheetListFixture(Db);
                var result = f.Subject.SearchFor(new TimeSearchParams
                {
                    StaffId = staffId,
                    NarrativeSearch = narrativeSearch
                });
                var timeEntries = result.ToList();
                Assert.Equal(3, timeEntries.Count);
                Assert.NotNull(timeEntries.SingleOrDefault(_ => _.EntryNo == entryNo));
                Assert.NotNull(timeEntries.SingleOrDefault(_ => _.EntryNo == entryNo + 1));
                Assert.NotNull(timeEntries.SingleOrDefault(_ => _.EntryNo == entryNo + 2));
            }

            [Fact]
            public void ReturnsAllEntries()
            {
                var entryNo = Fixture.Short();
                new DiaryBuilder(Db) {StaffId = Fixture.Integer(), EntryNo = entryNo}.Build();
                new DiaryBuilder(Db) {StaffId = Fixture.Integer(), EntryNo = entryNo + 1, IsTimer = true}.Build();
                new DiaryBuilder(Db) {StaffId = Fixture.Integer(), EntryNo = entryNo + 2}.Build();
                new DiaryBuilder(Db) {StaffId = Fixture.Integer(), EntryNo = entryNo + 3}.Build();
                new DiaryBuilder(Db) {StaffId = Fixture.Integer(), EntryNo = entryNo + 4}.Build();
                new DiaryBuilder(Db) {StaffId = Fixture.Integer(), EntryNo = entryNo + 5}.Build();
                new DiaryBuilder(Db) {StaffId = Fixture.Integer(), EntryNo = entryNo + 6}.Build();
                new DiaryBuilder(Db) {StaffId = Fixture.Integer(), EntryNo = entryNo + 7, IsTimer = true}.Build();
                new DiaryBuilder(Db) {StaffId = Fixture.Integer(), EntryNo = entryNo + 8}.Build();
                new DiaryBuilder(Db) {StaffId = Fixture.Integer(), EntryNo = entryNo + 9}.Build();
                new DiaryBuilder(Db) {StaffId = Fixture.Integer(), EntryNo = entryNo + 10}.Build();
                new DiaryBuilder(Db) {StaffId = Fixture.Integer(), EntryNo = entryNo + 11}.Build();
                new DiaryBuilder(Db) {StaffId = Fixture.Integer(), EntryNo = entryNo + 12}.Build();
                var f = new TimesheetListFixture(Db);
                var result = f.Subject.SearchForAll();
                var timeEntries = result.ToList();
                Assert.Equal(11, timeEntries.Count);
                Assert.Null(timeEntries.SingleOrDefault(_ => _.EntryNo == entryNo + 1));
                Assert.Null(timeEntries.SingleOrDefault(_ => _.EntryNo == entryNo + 7));
            }
        }

        public class FormatNamesForDisplayMethod : FactBase
        {
            [Fact]
            public void FormatsNamesInTimeEntriesList()
            {
                var instructor = new NameBuilder(Db).Build().In(Db);
                var debtor = new NameBuilder(Db).Build().In(Db);
                var f = new TimesheetListFixture(Db).WithDisplayNamesFor(new[] {instructor, debtor});
                var entries = new List<TimeEntry> {new TimeEntry {DebtorName = debtor}, new TimeEntry {InstructorName = instructor}, new TimeEntry()};
                f.Subject.FormatNamesForDisplay(entries);

                Assert.Equal(debtor.Formatted(), entries.First().Name);
                Assert.Equal(instructor.Formatted(), entries[1].Name);
                Assert.Null(entries[2].Name);
            }

            [Fact]
            public void FormatsNamesForSeparateDebtors()
            {
                var instructor = new NameBuilder(Db).Build().In(Db);
                var debtor1 = new NameBuilder(Db).Build().In(Db);
                var debtor2 = new NameBuilder(Db).Build().In(Db);
                var f = new TimesheetListFixture(Db).WithDisplayNamesFor(new[] {instructor, debtor1, debtor2});
                var entries = new List<TimeEntry>
                {
                    new TimeEntry
                    {
                        DebtorName = debtor1
                    },
                    new TimeEntry
                    {
                        InstructorName = instructor
                    },
                    new TimeEntry
                    {
                        DebtorSplits =
                        {
                            new DebtorSplit {DebtorNameNo = debtor1.Id},
                            new DebtorSplit {DebtorNameNo = debtor2.Id}
                        }
                    }
                };
                f.Subject.FormatNamesForDisplay(entries);

                Assert.Equal(debtor1.Formatted(), entries.First().Name);
                Assert.Equal(instructor.Formatted(), entries[1].Name);
                Assert.Equal(debtor1.Formatted(), entries[2].DebtorSplits[0].DebtorName);
                Assert.Equal(debtor2.Formatted(), entries[2].DebtorSplits[1].DebtorName);
            }
        }

        public class GetWholeChainForMethod : FactBase
        {
            void SetDiaryEntriesForTheDay(int staffNameId = 10)
            {
                new DiaryBuilder(Db) {StaffId = staffNameId, EntryNo = 1, ParentEntryNo = null, StartTime = Fixture.Monday.Date.AddHours(1), FinishTime = Fixture.Monday.Date.AddHours(2)}.Build();
                new DiaryBuilder(Db) {StaffId = staffNameId, EntryNo = 2, ParentEntryNo = 1, StartTime = Fixture.Monday.Date.AddHours(2), FinishTime = Fixture.Monday.Date.AddHours(4)}.Build();
                new DiaryBuilder(Db) {StaffId = staffNameId, EntryNo = 3, ParentEntryNo = 2, StartTime = Fixture.Monday.Date.AddHours(4), FinishTime = Fixture.Monday.Date.AddHours(7)}.Build();
                new DiaryBuilder(Db) {StaffId = staffNameId, EntryNo = 4, ParentEntryNo = 3, StartTime = Fixture.Monday.Date.AddHours(7), FinishTime = Fixture.Monday.Date.AddHours(11)}.Build();
                new DiaryBuilder(Db) {StaffId = staffNameId, EntryNo = 99, ParentEntryNo = null, StartTime = Fixture.Monday.Date.AddHours(11), FinishTime = Fixture.Monday.Date.AddHours(12)}.Build();
            }

            [Fact]
            public async Task ReturnsEmptyIfNoEntryFound()
            {
                var f = new TimesheetListFixture(Db);
                Assert.Empty(await f.Subject.GetWholeChainFor(10, 10, null));
            }

            [Fact]
            public async Task ReturnsEntryIfSingleEntryFound()
            {
                SetDiaryEntriesForTheDay();
                var f = new TimesheetListFixture(Db);

                var result = await f.Subject.GetWholeChainFor(10, 99, null);
                Assert.Equal(1, result.Count());
            }

            [Fact]
            public async Task ReturnsChainFromLastChild()
            {
                SetDiaryEntriesForTheDay();
                var f = new TimesheetListFixture(Db);

                var result = (await f.Subject.GetWholeChainFor(10, 4, null)).ToArray();
                Assert.Equal(4, result.Count());
                Assert.Equal(4, result[0].EntryNo);
                Assert.Equal(3, result[1].EntryNo);
                Assert.Equal(2, result[2].EntryNo);
                Assert.Equal(1, result[3].EntryNo);
            }

            [Fact]
            public async Task ReturnsChainFromFirstParent()
            {
                SetDiaryEntriesForTheDay();
                var f = new TimesheetListFixture(Db);

                var result = (await f.Subject.GetWholeChainFor(10, 4, null)).ToArray();
                Assert.Equal(4, result.Count());
                Assert.Equal(4, result[0].EntryNo);
                Assert.Equal(3, result[1].EntryNo);
                Assert.Equal(2, result[2].EntryNo);
                Assert.Equal(1, result[3].EntryNo);
            }

            [Fact]
            public async Task ReturnsChainFromMiddleParent()
            {
                SetDiaryEntriesForTheDay();
                var f = new TimesheetListFixture(Db);

                var result = (await f.Subject.GetWholeChainFor(10, 4, null)).ToArray();
                Assert.Equal(4, result.Count());
                Assert.Equal(4, result[0].EntryNo);
                Assert.Equal(3, result[1].EntryNo);
                Assert.Equal(2, result[2].EntryNo);
                Assert.Equal(1, result[3].EntryNo);
            }
        }

        public class TimesheetListFixture : IFixture<TimesheetList>
        {
            public TimesheetListFixture(InMemoryDbContext db)
            {
                Now = Substitute.For<Func<DateTime>>();
                Now().Returns(Fixture.Today());
                Db = db;
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                DisplayFormattedName = Substitute.For<IDisplayFormattedName>();
                DisplayFormattedName.For(Arg.Any<int[]>()).Returns(new Dictionary<int, NameFormatted>());
                new DebtorSplitDiary() {Id = 1, EntryNo = 1, EmployeeNo = 0}.In(db);
                new DebtorSplitDiary() {Id = 2, EntryNo = 1, EmployeeNo = 0}.In(db);

                var profile = new AccountingProfile();
                var m = new Mapper(new MapperConfiguration(cfg =>
                {
                    cfg.AddProfile(profile);
                    cfg.CreateMissingTypeMaps = true;
                }));

                Subject = new TimesheetList(Db, PreferredCultureResolver, SiteControlReader, DisplayFormattedName, Now, m);
                Narrative = new Narrative {NarrativeId = Fixture.Short(), NarrativeTitle = Fixture.String(), NarrativeText = Fixture.String()}.In(db);
            }

            IDbContext Db { get; }
            public IPreferredCultureResolver PreferredCultureResolver { get; }
            public ISiteControlReader SiteControlReader { get; }
            public Narrative Narrative { get; }
            public IDisplayFormattedName DisplayFormattedName { get; }
            Func<DateTime> Now { get; }

            public TimesheetList Subject { get; }
        }
    }

    public static class TimesheetListFixtureExt
    {
        public static TimesheetListFacts.TimesheetListFixture WithDisplayNamesFor(this TimesheetListFacts.TimesheetListFixture subject, IEnumerable<Name> names)
        {
            var displayNames = names.ToDictionary(name => name.Id, name => new NameFormatted {Name = name.Formatted()});
            subject.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(displayNames);

            return subject;
        }
    }
}