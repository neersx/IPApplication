using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Web.Accounting.Time;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class DiaryDatesReaderFacts : FactBase
    {
        [Fact]
        public async Task ReturnsNUllIfNoRecordsinDiary()
        {
            var f = new DiaryDatesReaderFixture(Db).WithSiteControls();

            var result = await f.Subject.GetDiaryDatesFor(10, Fixture.Today());

            Assert.Empty(result);
        }

        [Fact]
        public async Task ReturnsCorrectEntriesForSelectedEmployee()
        {
            var f = new DiaryDatesReaderFixture(Db).WithSiteControls()
                                                   .WithCompletedEntries(10)
                                                   .WithCompletedEntries(11);

            var result = (await f.Subject.GetDiaryDatesFor(10, Fixture.Today().AddDays(1))).OrderByDescending(_ => _.Date).ToList();

            Assert.Equal(2, result.Count);

            Assert.Equal(Fixture.Today().Date, result.First().Date);
            Assert.Equal(1 * 60 * 60, result.First().TotalTimeInSeconds);
            Assert.Equal(1 * 60 * 60, result.First().TotalChargableTimeInSeconds);

            Assert.Equal(Fixture.Today().AddDays(-1).Date, result.Last().Date);
            Assert.Equal(3 * 60 * 60, result.Last().TotalTimeInSeconds);
            Assert.Equal(2 * 60 * 60, result.Last().TotalChargableTimeInSeconds);
        }

        [Fact]
        public async Task DoesNotIncludeDataForFutureDates()
        {
            var f = new DiaryDatesReaderFixture(Db).WithSiteControls()
                                                   .WithCompletedEntries(10)
                                                   .WithCompletedEntries(11);

            var result = (await f.Subject.GetDiaryDatesFor(10, Fixture.Today())).ToList();

            Assert.Equal(0, result.Count(_ => _.Date > Fixture.Today()));
        }

        [Fact]
        public async Task DoesNotReturnIncompleteAndPostedEntries()
        {
            var f = new DiaryDatesReaderFixture(Db).WithSiteControls(true, true)
                                                   .WithIncompleteEntries(10);

            var result = (await f.Subject.GetDiaryDatesFor(10, Fixture.Today())).ToList();

            Assert.Equal(0, result.Count);
        }

        [Fact]
        public async Task IncludeEntriesWhenCorrSiteControlsNotSet()
        {
            var f = new DiaryDatesReaderFixture(Db).WithSiteControls()
                                                   .WithIncompleteEntries(10);

            var result = (await f.Subject.GetDiaryDatesFor(10, Fixture.Today().AddDays(1))).OrderBy(_ => _.Date).ToList();

            Assert.Equal(2, result.Count);
            Assert.Equal(2 * 60 * 60, result.First().TotalTimeInSeconds);
            Assert.Equal(2 * 60 * 60, result.Last().TotalTimeInSeconds);
        }

        [Fact]
        public async Task ReturnsNUllIfNoRecordsinDiaryForEntryNos()
        {
            var f = new DiaryDatesReaderFixture(Db).WithSiteControls();

            var result = await f.Subject.GetDiaryDatesFor(10, new[] {10});

            Assert.Empty(result);
        }

        [Fact]
        public async Task ReturnsSelectedEntriesForSelectedEmployee()
        {
            var f = new DiaryDatesReaderFixture(Db).WithSiteControls()
                                                   .WithEntry(10, startTime: Fixture.Tuesday)
                                                   .WithEntry(10, 100, startTime: Fixture.Tuesday);

            var result = (await f.Subject.GetDiaryDatesFor(10, new[] {10, 100})).OrderByDescending(_ => _.Date).ToList();

            Assert.Equal(1, result.Count);

            Assert.Equal(Fixture.Tuesday, result.First().Date);
        }

        [Fact]
        public async Task IncludesDataForFutureDates()
        {
            var f = new DiaryDatesReaderFixture(Db).WithSiteControls()
                                                   .WithEntry(10)
                                                   .WithEntry(10, 100, false, Fixture.FutureDate());

            var result = (await f.Subject.GetDiaryDatesFor(10, new[] {10, 100})).ToList();

            Assert.Equal(1, result.Count(_ => _.Date > Fixture.Today()));
        }

        [Fact]
        public async Task DoesNotReturnIncompleteAndPostedSelectedEntries()
        {
            var f = new DiaryDatesReaderFixture(Db).WithSiteControls(true, true)
                                                   .WithEntry(10, 10, startTime: Fixture.Monday)
                                                   .WithEntry(10, 100, true, Fixture.Tuesday);

            var result = (await f.Subject.GetDiaryDatesFor(10, new[] {10, 100})).ToList();

            Assert.Equal(1, result.Count);
            Assert.Equal(Fixture.Monday, result[0]);
        }

        [Fact]
        public async Task IncludesSelectedEntriesWhenCorrSiteControlsNotSet()
        {
            var f = new DiaryDatesReaderFixture(Db).WithSiteControls()
                                                   .WithIncompleteEntries(10);

            var entryNos = Db.Set<Diary>().Select(_ => _.EntryNo).ToArray();

            var result = (await f.Subject.GetDiaryDatesFor(10, entryNos)).OrderBy(_ => _.Date).ToList();

            Assert.Equal(2, result.Count);
        }

        [Fact]
        public async Task ReturnsEntriesBetweenTwoDates()
        {
            var f = new DiaryDatesReaderFixture(Db).WithSiteControls();
            var nameDict = new Dictionary<int, NameFormatted>();

            new DiaryBuilder(Db)
            {
                StaffId = Fixture.Integer(),
                StartTime = Fixture.Today().AddDays(-100).AddHours(8),
                FinishTime = Fixture.Today().AddDays(-100).AddHours(10)
            }.Build();
            var inRange1= new DiaryBuilder(Db)
            {
                StaffId = Fixture.Integer(),
                StartTime = Fixture.Today().AddDays(-2).AddHours(8),
                FinishTime = Fixture.Today().AddDays(-2).AddHours(10)
            }.Build();
            var inRange2 = new DiaryBuilder(Db)
            {
                StaffId = Fixture.Integer(),
                StartTime = Fixture.Today().AddDays(-3).AddHours(8),
                FinishTime = Fixture.Today().AddDays(-3).AddHours(10)
            }.Build();
            new DiaryBuilder(Db)
            {
                StaffId = Fixture.Integer(),
                StartTime = Fixture.Today().AddDays(2).AddHours(8),
                FinishTime = Fixture.Today().AddDays(2).AddHours(10)
            }.Build();
            nameDict.Add(inRange1.EmployeeNo, new NameFormatted {Name = Fixture.String()});
            nameDict.Add(inRange2.EmployeeNo, new NameFormatted {Name = Fixture.String()});
            f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(nameDict);

            var result = (await f.Subject.GetDiaryDatesFor(Fixture.Today().AddDays(-4), Fixture.Today())).ToList();

            Assert.Equal(2, result.Count);
            Assert.Equal(nameDict[inRange1.EmployeeNo].Name, result[0].StaffName);
            Assert.Equal(nameDict[inRange2.EmployeeNo].Name, result[1].StaffName);
        }
    }

    public class DiaryDatesReaderFixture : IFixture<IDiaryDatesReader>
    {
        public DiaryDatesReaderFixture(InMemoryDbContext db)
        {
            _db = db;
            SiteControlReader = Substitute.For<ISiteControlReader>();
            DisplayFormattedName = Substitute.For<IDisplayFormattedName>();

            Subject = new DiaryDatesReader(db, SiteControlReader, DisplayFormattedName);
        }

        public DiaryDatesReaderFixture WithSiteControls(bool caseOnly = false, bool rateMandatory = false)
        {
            SiteControlReader.Read<bool>(Arg.Is<string>(_ => _ == SiteControls.CASEONLY_TIME)).Returns(caseOnly);
            SiteControlReader.Read<bool>(Arg.Is<string>(_ => _ == SiteControls.RateMandatoryOnTimeItems)).Returns(rateMandatory);

            return this;
        }

        public DiaryDatesReaderFixture WithEntry(int employeeNo, int entryNo = 10, bool isIncomplete = false, DateTime? startTime = null)
        {
            var d = new DiaryBuilder(_db)
            {
                EntryNo = entryNo,
                StaffId = employeeNo,
                StartTime = (startTime ?? Fixture.Today().AddDays(-1)).AddHours(7),
                FinishTime = (startTime ?? Fixture.Today().AddDays(-1)).AddHours(8)
            }.BuildWithCase(true);

            if (isIncomplete)
            {
                d.Activity = null;
            }

            return this;
        }

        public DiaryDatesReaderFixture WithCompletedEntries(int employeeNo)
        {
            new DiaryBuilder(_db)
            {
                StaffId = employeeNo,
                StartTime = Fixture.Today().AddDays(-1).AddHours(7),
                FinishTime = Fixture.Today().AddDays(-1).AddHours(8)
            }.Build().TimeValue = null;
            new DiaryBuilder(_db)
            {
                StaffId = employeeNo,
                StartTime = Fixture.Today().AddDays(-1).AddHours(8),
                FinishTime = Fixture.Today().AddDays(-1).AddHours(10)
            }.Build();
            new DiaryBuilder(_db)
            {
                StaffId = employeeNo,
                StartTime = Fixture.Today().AddHours(10),
                FinishTime = Fixture.Today().AddHours(11),
            }.Build();
            new DiaryBuilder(_db)
            {
                StaffId = employeeNo,
                StartTime = Fixture.Today().AddDays(1).AddHours(8),
                FinishTime = Fixture.Today().AddDays(1).AddHours(10)
            }.Build();

            return this;
        }

        public DiaryDatesReaderFixture WithIncompleteEntries(int employeeNo)
        {
            var d = NewDiaryEntry(-1);
            d.StartTime = null;
            d.FinishTime = null;

            d = NewDiaryEntry(-2);
            d.Activity = null;

            d = NewDiaryEntry(-3);
            d.ChargeOutRate = null;

            d = NewDiaryEntry(-4);
            d.TransactionId = 10;

            d = NewDiaryEntry(-5);
            d.IsTimer = 1;

            d = NewDiaryEntry(-6);
            d.TotalTime = new DateTime(1899, 1, 1);

            new DiaryBuilder(_db)
            {
                StaffId = employeeNo,
                StartTime = Fixture.Today().AddDays(-7).AddHours(8),
                FinishTime = Fixture.Today().AddDays(-7).AddHours(10)
            }.Build();

            return this;

            Diary NewDiaryEntry(int addDays)
            {
                return new DiaryBuilder(_db)
                {
                    StaffId = employeeNo,
                    StartTime = Fixture.Today().AddDays(addDays).AddHours(8),
                    FinishTime = Fixture.Today().AddDays(addDays).AddHours(10),
                }.BuildWithCase(true);
            }
        }

        readonly InMemoryDbContext _db;

        public IDiaryDatesReader Subject { get; }

        public ISiteControlReader SiteControlReader { get; }

        public IDisplayFormattedName DisplayFormattedName { get; }
    }
}