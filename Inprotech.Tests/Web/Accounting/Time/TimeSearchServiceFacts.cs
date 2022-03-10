using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Accounting.Time.Search;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class TimeSearchServiceFacts : FactBase
    {
        [Fact]
        public void AppliesQueryWhileSearching()
        {
            var query = new TimeSearchParams {ActivityId = "A", CaseIds = new[] {(int?) 100}};

            var f = new TimeSearchServiceFixture(Db);
            f.TimesheetList.SearchFor(query).ReturnsForAnyArgs(new TimeEntry[] { }.AsDbAsyncEnumerble());

            f.Subject.Search(query, new []{new CommonQueryParameters.FilterValue {Field = "start", Value = new DateTime().ToShortDateString()}});
            f.TimesheetList.Received(1).SearchFor(Arg.Is(query));
        }

        [Fact]
        public void FiltersByStart()
        {
            var query = new TimeSearchParams { ActivityId = "A", CaseIds = new[] { (int?)100 } };

            var f = new TimeSearchServiceFixture(Db);
            var data = new[]
            {
                new TimeEntry {StartTime = new DateTime(2010, 11, 1, 10, 10, 10)},
                new TimeEntry {StartTime = new DateTime(2010, 1, 1, 10, 10, 10)},
                new TimeEntry {StartTime = new DateTime(2010, 1, 1, 10, 10, 10)},
                new TimeEntry {StartTime = new DateTime(2010, 2, 2, 10, 10, 10)},
                new TimeEntry {StartTime = new DateTime(2010, 10, 10, 10, 10, 10)}
            }.AsDbAsyncEnumerble();
            f.TimesheetList.SearchFor(Arg.Any<TimeSearchParams>()).Returns(data);

            var filterForDates = f.Subject.Search(query, new []{ new CommonQueryParameters.FilterValue {Field = "entryDate", Value = "2010-1-1"}}).ToArray();
            Assert.Equal(2, filterForDates.Length);
            Assert.True(filterForDates.All(_ => _.Start.GetValueOrDefault().Date == new DateTime(2010, 1, 1)));
        }

        [Fact]
        public void FiltersByCaseReference()
        {
            var f = new TimeSearchServiceFixture(Db);
            var data = new[]
            {
                new TimeEntry {CaseKey = 100, CaseReference = "Santa"},
                new TimeEntry {CaseKey = 101, CaseReference = "Banta"},
                new TimeEntry {CaseKey = 101, CaseReference = "Banta"},
                new TimeEntry()
            }.AsDbAsyncEnumerble();
            f.TimesheetList.SearchFor(Arg.Any<TimeSearchParams>()).Returns(data);

            var filterForCaseRef = f.Subject.Search(new TimeSearchParams(), new []{ new CommonQueryParameters.FilterValue {Field = "caseReference", Value = "101"}}).ToArray();
            Assert.Equal(2, filterForCaseRef.Length);
            Assert.True(filterForCaseRef.All(_ => _.CaseReference == "Banta" && _.CaseKey == 101));
        }

        [Fact]
        public void FiltersByName()
        {
            var f = new TimeSearchServiceFixture(Db);
            var data = new[]
            {
                new TimeEntry {EntryNo = 1, InstructorName = new Name(100), DebtorName = new Name(101)},
                new TimeEntry {EntryNo = 2, InstructorName = new Name(100)},
                new TimeEntry {EntryNo = 3, InstructorName = new Name(102), DebtorName = new Name(100)},
                new TimeEntry {EntryNo = 4, DebtorName = new Name(103)},
                new TimeEntry()
            }.AsDbAsyncEnumerble();
            f.TimesheetList.SearchFor(Arg.Any<TimeSearchParams>()).Returns(data);

            var filterForNames = f.Subject.Search(new TimeSearchParams(), new []{ new CommonQueryParameters.FilterValue {Field = "name", Value = "100"}}).ToArray();

            Assert.Equal(2, filterForNames.Length);
            Assert.True(filterForNames.All(_ => _.NameKey == 100));
            Assert.Equal(1, filterForNames[0].EntryNo);
            Assert.Equal(2, filterForNames[1].EntryNo);
        }

        [Fact]
        public void FiltersByActivity()
        {
            var f = new TimeSearchServiceFixture(Db);
            var data = new[]
            {
                new TimeEntry {EntryNo = 1, ActivityKey = "A", Activity = "Santa"},
                new TimeEntry {EntryNo = 2, ActivityKey = "B", Activity = "Banta"},
                new TimeEntry {EntryNo = 3,ActivityKey = "B", Activity = "Banta"},
                new TimeEntry()
            }.AsDbAsyncEnumerble();
            f.TimesheetList.SearchFor(Arg.Any<TimeSearchParams>()).Returns(data);

            var filterForActivity = f.Subject.Search(new TimeSearchParams(), new []{ new CommonQueryParameters.FilterValue {Field = "activity", Value = "B"}}).ToArray();
            Assert.Equal(2, filterForActivity.Length);
            Assert.True(filterForActivity.All(_ => _.ActivityKey == "B"));
            Assert.Equal(2, filterForActivity[0].EntryNo);
            Assert.Equal(3, filterForActivity[1].EntryNo);
        }

        [Fact]
        public void AppliesOnlyOtherFilters()
        {
            var queryParams = new CommonQueryParameters()
            {
                Filters = new List<CommonQueryParameters.FilterValue>
                {
                    new CommonQueryParameters.FilterValue {Field = "activity", Value = "A,C"},
                    new CommonQueryParameters.FilterValue {Field = "caseReference", Value = "100,101"}
                }
            };
            var f = new TimeSearchServiceFixture(Db);
            var data = new[]
            {
                new TimeEntry {EntryNo = 1, ActivityKey = "A", Activity = "Santa", CaseKey = 100},
                new TimeEntry {EntryNo = 2, ActivityKey = "B", Activity = "Banta", CaseKey = 101},
                new TimeEntry {EntryNo = 3, ActivityKey = "C", Activity = "Clause", CaseKey = 105},
                new TimeEntry {EntryNo = 4, ActivityKey = "C", Activity = "Clause", CaseKey = 101},
                new TimeEntry {EntryNo = 5, ActivityKey = "D", Activity = "Clause", CaseKey = 106},
                new TimeEntry()
            }.AsDbAsyncEnumerble();
            f.TimesheetList.SearchFor(Arg.Any<TimeSearchParams>()).ReturnsForAnyArgs(data);

            var filterForActivity = f.Subject.Search(new TimeSearchParams(), new List<CommonQueryParameters.FilterValue>
            {
                new CommonQueryParameters.FilterValue {Field = "activity", Value = "A,C"},
                new CommonQueryParameters.FilterValue {Field = "caseReference", Value = "100,101"}
            }).ToArray();
            Assert.Equal(2, filterForActivity.Length);
            Assert.Equal("Santa", filterForActivity[0].Activity);
            Assert.Equal("A", filterForActivity[0].ActivityKey);
            Assert.Equal(1, filterForActivity[0].EntryNo);
            Assert.Equal("C", filterForActivity[1].ActivityKey);
            Assert.Equal("Clause", filterForActivity[1].Activity);
            Assert.Equal(4, filterForActivity[1].EntryNo);
        }
    }

    public class TimeSearchServiceFixture : IFixture<TimeSearchService>
    {
        public TimeSearchServiceFixture(InMemoryDbContext dbContext)
        {
            TimesheetList = Substitute.For<ITimesheetList>();
            Subject = new TimeSearchService(TimesheetList);
        }

        public ITimesheetList TimesheetList { get; set; }
        public TimeSearchService Subject { get; }
    }
}
