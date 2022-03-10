using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Search.Export;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Accounting;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Accounting.Time.Search;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;
using static Inprotech.Infrastructure.Web.CommonQueryParameters;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class TimeSearchControllerFacts
    {
        public class Search : FactBase
        {
            [Fact]
            public async Task ReturnsErrorIfUnauthorised()
            {
                var query = new TimeSearchParams
                {
                    FromDate = Fixture.Monday,
                    ToDate = Fixture.Tuesday,
                    IsPosted = Fixture.Boolean(),
                    IsUnposted = Fixture.Boolean(),
                    StaffId = Fixture.Integer()
                };
                var f = new TimeSearchControllerFixture(Db);
                f.FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, Arg.Any<User>(), Arg.Any<int>()).Returns(false);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Search(query, Default));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
            }

            [Fact]
            public async Task UsesParametersInSearch()
            {
                var query = new TimeSearchParams
                {
                    FromDate = Fixture.Monday,
                    ToDate = Fixture.Tuesday,
                    IsPosted = Fixture.Boolean(),
                    IsUnposted = Fixture.Boolean(),
                    StaffId = Fixture.Integer(),
                    CaseIds = new int?[] {Fixture.Integer(), Fixture.Integer()},
                    NameId = Fixture.Integer(),
                    ActivityId = Fixture.String(),
                    Entity = Fixture.Integer()
                };

                var f = new TimeSearchControllerFixture(Db);
                f.TimeSearchService.Search(query, Arg.Any<IEnumerable<FilterValue>>()).ReturnsForAnyArgs(new TimeEntry[] { }.AsDbAsyncEnumerble());

                await f.Subject.Search(query, new CommonQueryParameters {SortBy = "start", SortDir = "asc", Skip = 0});
                f.TimeSearchService.Received(1).Search(query, Arg.Any<IEnumerable<FilterValue>>());
                f.TimeSummaryProvider.Received(1).Get(Arg.Any<IQueryable<TimeEntry>>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ReturnsCountAndSummaryForFirstPage()
            {
                var query = new TimeSearchParams();
                var summary = new TimeSummary {TotalHours = 10, TotalDiscount = 900};
                var f = new TimeSearchControllerFixture(Db);
                f.TimeSearchService.Search(query, Arg.Any<IEnumerable<FilterValue>>()).ReturnsForAnyArgs(new TimeEntry[] { }.AsDbAsyncEnumerble());
                f.TimeSummaryProvider.Get(Arg.Any<IQueryable<TimeEntry>>()).ReturnsForAnyArgs((summary, 100));

                var result = await f.Subject.Search(query, new CommonQueryParameters {SortBy = "start", SortDir = "asc", Skip = 0});
                f.TimeSummaryProvider.Received(1).Get(Arg.Any<IQueryable<TimeEntry>>()).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(summary, result.Summary);
                Assert.Equal(100, result.Data.Pagination.Total);
            }

            [Fact]
            public async Task DoesNotReturnsCountAndSummaryForSecondPage()
            {
                var query = new TimeSearchParams();
                var f = new TimeSearchControllerFixture(Db);
                f.TimeSearchService.Search(query, Arg.Any<IEnumerable<FilterValue>>()).ReturnsForAnyArgs(new TimeEntry[] { }.AsDbAsyncEnumerble());

                var result = await f.Subject.Search(query, new CommonQueryParameters {SortBy = "start", SortDir = "asc", Skip = 10});
                f.TimeSummaryProvider.DidNotReceive().Get(Arg.Any<IQueryable<TimeEntry>>()).IgnoreAwaitForNSubstituteAssertion();

                Assert.Null(result.Summary);
                Assert.Equal(0, result.Data.Data.Count);
            }

            [Theory]
            [InlineData("start")]
            [InlineData("caseReference")]
            [InlineData("name")]
            [InlineData("activity")]
            [InlineData("totalDuration")]
            [InlineData("localValue")]
            [InlineData("localDiscount")]
            [InlineData("foreignValue")]
            [InlineData("foreignDiscount")]
            [InlineData("narrativeText")]
            public async Task AppliesSortOrderAndSkipTake(string field)
            {
                var data = new[]
                {
                    new TimeEntry
                    {
                        CaseKey = 101,
                        CaseReference = "B",
                        StartTime = new DateTime(2010, 02, 02, 10, 11, 12),
                        Instructor = "Z",
                        Debtor = "A",
                        Activity = "Z",
                        LocalValue = 100,
                        LocalDiscount = 100,
                        ForeignValue = 100,
                        ForeignDiscount = 100,
                        TotalTime = new DateTime(1899, 1, 1, 1, 0, 0),
                        TimeCarriedForward = new DateTime(1899, 1, 1, 0, 2, 0),
                        NarrativeText = "Z1"
                    },
                    new TimeEntry
                    {
                        CaseKey = 100,
                        CaseReference = "A",
                        StartTime = new DateTime(2010, 01, 01, 10, 11, 12),
                        Debtor = "C",
                        Activity = "B",
                        LocalValue = 10,
                        LocalDiscount = 10,
                        ForeignValue = 10,
                        ForeignDiscount = 10,
                        TotalTime = new DateTime(1899, 1, 1, 1, 1, 0),
                        NarrativeText = "C1"
                    },
                    new TimeEntry {StartTime = new DateTime(2009, 01, 02, 10, 11, 12), TotalTime = new DateTime(1899, 1, 1, 1, 0, 0)},
                    new TimeEntry
                    {
                        CaseKey = 101,
                        CaseReference = "B",
                        StartTime = new DateTime(2010, 02, 02, 10, 11, 12),
                        Instructor = "Z",
                        Debtor = "A",
                        Activity = "Z",
                        LocalValue = 100,
                        LocalDiscount = 100,
                        ForeignValue = 100,
                        ForeignDiscount = 100,
                        TotalTime = new DateTime(1899, 1, 1, 2, 0, 0),
                        NarrativeText = "Z1"
                    },
                };
                var query = new TimeSearchParams();
                var f = new TimeSearchControllerFixture(Db);
                f.TimeSearchService.Search(query, Arg.Any<IEnumerable<FilterValue>>()).ReturnsForAnyArgs(data.AsDbAsyncEnumerble());
                
                var result = await f.Subject.Search(query,
                                                    new CommonQueryParameters
                                                    {
                                                        SortBy = field,
                                                        SortDir = "asc",
                                                        Skip = 0,
                                                        Take = 3,
                                                    });
                var resultArray = (List<TimeEntry>) result.Data.Data;
                Assert.NotNull(resultArray);
                Assert.Equal(3, resultArray.Count);

                Assert.Equal(data[2].StartTime, resultArray[0].StartTime);
                Assert.Null(resultArray[0].CaseReference);
                Assert.Null(resultArray[0].NameKey);
                Assert.Null(resultArray[0].Activity);

                Assert.Equal(data[1].StartTime, resultArray[1].StartTime);
                Assert.Equal(data[1].CaseReference, resultArray[1].CaseReference);
                Assert.Equal(data[1].NameKey, resultArray[1].NameKey);
                Assert.Equal(data[1].ActivityKey, resultArray[1].ActivityKey);

                Assert.Equal(data[0].StartTime, resultArray[2].StartTime);
                Assert.Equal(data[0].CaseReference, resultArray[2].CaseReference);
                Assert.Equal(data[0].NameKey, resultArray[2].NameKey);
                Assert.Equal(data[0].ActivityKey, resultArray[2].ActivityKey);
            }

            [Theory]
            [InlineData("start", "2010-01-01T00:00:00.000Z,2010-02-02T00:00:00.000Z")]
            [InlineData("caseReference", "100,101,")]
            [InlineData("name", "100,101,")]
            [InlineData("activity", "A,B,")]
            public async Task CallsSearchWithFilters(string field, string filterValue)
            {
                var data = new[]
                {
                    new TimeEntry {CaseKey = 101, CaseReference = "B", StartTime = new DateTime(2010, 01, 01, 10, 11, 12), InstructorName = new Name(100), DebtorName = new Name(200), ActivityKey = "A"},
                    new TimeEntry {CaseKey = 100, CaseReference = "A", StartTime = new DateTime(2010, 02, 02, 10, 11, 12), DebtorName = new Name(101), ActivityKey = "B"},
                    new TimeEntry {CaseKey = 102, CaseReference = "C", StartTime = new DateTime(2015, 01, 01, 10, 11, 12), InstructorName = new Name(30), ActivityKey = "C"},
                    new TimeEntry {StartTime = new DateTime(2010, 02, 02, 10, 11, 12)}
                };
                var query = new TimeSearchParams();
                var f = new TimeSearchControllerFixture(Db);
                f.TimeSearchService.Search(query, Arg.Any<IEnumerable<FilterValue>>()).ReturnsForAnyArgs(data.AsDbAsyncEnumerble());

                await f.Subject.Search(query,
                                       new CommonQueryParameters
                                       {
                                           SortBy = "caseReference",
                                           SortDir = "asc",
                                           Skip = 0,
                                           Take = 10,
                                           Filters = new[] {new FilterValue {Field = field, Operator = "In", Value = filterValue}}
                                       });

                f.TimeSearchService.Received(1).Search(query, Arg.Is<IEnumerable<FilterValue>>(_ => _.All(__ => __.Field == field &&
                                                                                                                __.Operator == "In" &&
                                                                                                                __.Value == filterValue)));
            }
        }

        public class View : FactBase
        {
            [Fact]
            public async Task ReturnsHomeNameNoForAutomaticWipEntity()
            {
                var homeName = new NameBuilder(Db).Build().In(Db);
                var f = new TimeSearchControllerFixture(Db);
                f.SiteControlReader.Read<bool>(SiteControls.AutomaticWIPEntity).Returns(true);
                f.SiteControlReader.Read<int>(SiteControls.HomeNameNo).Returns(homeName.Id);
                f.DisplayFormattedName.For(homeName.Id).Returns($"Formatted, {homeName.LastName}");
                var result = await f.Subject.ViewData();
                var entities = (List<TimeSearchController.EntityName>)result.Entities;
                Assert.Equal(1, entities.Count);
                Assert.Equal(homeName.Id, entities[0].Id);
                Assert.Equal($"Formatted, {homeName.LastName}", entities[0].DisplayName);
            }

            [Fact]
            public async Task ReturnsAllAvailableEntities()
            {
                var name1 = new NameBuilder(Db) {LastName = "XYZ"}.Build().In(Db);
                var name2 = new NameBuilder(Db) {LastName = "QED"}.Build().In(Db);
                var name3 = new NameBuilder(Db) {LastName = "ABC"}.Build().In(Db);
                var entity1 = new SpecialNameBuilder(Db) {EntityFlag = true, EntityName = name1}.Build().In(Db);
                var entity3 = new SpecialNameBuilder(Db) {EntityFlag = true, EntityName = name3}.Build().In(Db);
                new SpecialNameBuilder(Db) {EntityFlag = false, EntityName = name2}.Build().In(Db);

                var f = new TimeSearchControllerFixture(Db);
                f.SiteControlReader.Read<bool>(SiteControls.AutomaticWIPEntity).Returns(false);
                var formatted = new Dictionary<int, NameFormatted>
                {
                    {
                        entity3.Id, new NameFormatted {Name = $"Formatted, ABC"}
                    },
                    {
                        entity1.Id, new NameFormatted {Name = $"Formatted, XYZ"}
                    }
                };
                f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(formatted);
                var result = await f.Subject.ViewData();
                var entities = (List<TimeSearchController.EntityName>)result.Entities;
                Assert.Equal(2, entities.Count);
                Assert.Equal(entity3.Id, entities[0].Id);
                Assert.Equal(entity1.Id, entities[1].Id);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ReturnsDisplaySecondsPreference(bool preference)
            {
                var f = new TimeSearchControllerFixture(Db);
                f.UserPreferenceManager.GetPreference<bool>(Arg.Any<int>(), KnownSettingIds.DisplayTimeWithSeconds).Returns(preference);
                f.DisplayFormattedName.For(Arg.Any<int[]>()).Returns(new Dictionary<int, NameFormatted>());
                var result = await f.Subject.ViewData();
                var settings = (TimeRecordingSettings)result.Settings;
                Assert.Equal(preference, settings.DisplaySeconds);
                Assert.Equal(f.CurrentUser.NameId, result.UserInfo.NameId);
            }
        }

        public class GetFilterDataForColumn : FactBase
        {
            [Fact]
            public async Task AppliesQueryWhileSearching()
            {
                var query = new TimeSearchParams {ActivityId = "A", CaseIds = new[] {(int?) 100}};

                var f = new TimeSearchControllerFixture(Db);
                f.TimeSearchService.Search(query, new List<FilterValue>()).ReturnsForAnyArgs(new TimeEntry[] { }.AsDbAsyncEnumerble());

                await f.Subject.GetFilterDataForColumn("start", query, new CommonQueryParameters());
                f.TimeSearchService.Received(1).Search(Arg.Is(query), Arg.Is<IEnumerable<FilterValue>>(_ => _.All(__ => __.Field == "start")));
            }

            [Fact]
            public async Task ReturnsFilterSetForStart()
            {
                var query = new TimeSearchParams {ActivityId = "A", CaseIds = new[] {(int?) 100}};

                var f = new TimeSearchControllerFixture(Db);
                var data = new[]
                {
                    new TimeEntry {StartTime = new DateTime(2010, 11, 1, 10, 10, 10)},
                    new TimeEntry {StartTime = new DateTime(2010, 1, 1, 10, 10, 10)},
                    new TimeEntry {StartTime = new DateTime(2010, 1, 1, 10, 10, 10)},
                    new TimeEntry {StartTime = new DateTime(2010, 2, 2, 10, 10, 10)},
                    new TimeEntry {StartTime = new DateTime(2010, 10, 10, 10, 10, 10)}
                }.AsDbAsyncEnumerble();

                f.TimeSearchService.Search(Arg.Any<TimeSearchParams>(), new List<FilterValue>()).ReturnsForAnyArgs(data);

                var filterForDates = (await f.Subject.GetFilterDataForColumn("entryDate", query, new CommonQueryParameters())).ToArray();
                Assert.Equal(4, filterForDates.Length);
                Assert.Equal(new DateTime(2010, 1, 1), filterForDates[0].Description);
                Assert.Equal(new DateTime(2010, 2, 2), filterForDates[1].Description);
                Assert.Equal(new DateTime(2010, 10, 10), filterForDates[2].Description);
                Assert.Equal(new DateTime(2010, 11, 1), filterForDates[3].Description);
            }

            [Fact]
            public async Task ReturnsFilterSetForCaseReference()
            {
                var f = new TimeSearchControllerFixture(Db);
                var data = new[]
                {
                    new TimeEntry {CaseKey = 100, CaseReference = "Santa"},
                    new TimeEntry {CaseKey = 101, CaseReference = "Banta"},
                    new TimeEntry {CaseKey = 101, CaseReference = "Banta"},
                    new TimeEntry()
                }.AsDbAsyncEnumerble();
                f.TimeSearchService.Search(Arg.Any<TimeSearchParams>(), new List<FilterValue>()).ReturnsForAnyArgs(data);

                var filterForCaseRef = (await f.Subject.GetFilterDataForColumn("caseReference", new TimeSearchParams(), new CommonQueryParameters())).ToArray();
                Assert.Equal(3, filterForCaseRef.Length);
                Assert.Equal(null, filterForCaseRef[0].Description);
                Assert.Equal(null, filterForCaseRef[0].Code);
                Assert.Equal("Banta", filterForCaseRef[1].Description);
                Assert.Equal(101.ToString(), filterForCaseRef[1].Code);
                Assert.Equal("Santa", filterForCaseRef[2].Description);
                Assert.Equal(100.ToString(), filterForCaseRef[2].Code);
            }

            [Fact]
            public async Task ReturnsFilterSetForName()
            {
                var f = new TimeSearchControllerFixture(Db);

                var formattedNames = new Dictionary<int, NameFormatted>
                {
                    {100, new NameFormatted {Name = "Santa"}},
                    {103, new NameFormatted {Name = "Dumpty The Great"}},
                };
                f.DisplayFormattedName.For(Arg.Any<int[]>()).ReturnsForAnyArgs(formattedNames);
                var data = new[]
                {
                    new TimeEntry {InstructorName = new Name(100), DebtorName = new Name(101)},
                    new TimeEntry {InstructorName = new Name(100)},
                    new TimeEntry {DebtorName = new Name(103)},
                    new TimeEntry()
                }.AsDbAsyncEnumerble();
                f.TimeSearchService.Search(Arg.Any<TimeSearchParams>(), new List<FilterValue>()).ReturnsForAnyArgs(data);

                var filterForNames = (await f.Subject.GetFilterDataForColumn("name", new TimeSearchParams(), new CommonQueryParameters())).ToArray();
                f.DisplayFormattedName.Received(1).For(Arg.Is<int[]>(p => p.Contains(103) && p.Contains(100) && p.Length == 2)).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(3, filterForNames.Length);
                Assert.Equal(null, filterForNames[0].Description);
                Assert.Equal(null, filterForNames[0].Code);
                Assert.Equal("Dumpty The Great", filterForNames[1].Description);
                Assert.Equal(103.ToString(), filterForNames[1].Code);
                Assert.Equal("Santa", filterForNames[2].Description);
                Assert.Equal(100.ToString(), filterForNames[2].Code);
            }

            [Fact]
            public async Task ReturnsFilterSetForActivity()
            {
                var f = new TimeSearchControllerFixture(Db);
                var data = new[]
                {
                    new TimeEntry {ActivityKey = "A", Activity = "Santa"},
                    new TimeEntry {ActivityKey = "B", Activity = "Banta"},
                    new TimeEntry {ActivityKey = "B", Activity = "Banta"},
                    new TimeEntry()
                }.AsDbAsyncEnumerble();
                f.TimeSearchService.Search(Arg.Any<TimeSearchParams>(), new List<FilterValue>()).ReturnsForAnyArgs(data);

                var filterForActivity = (await f.Subject.GetFilterDataForColumn("activity", new TimeSearchParams(), new CommonQueryParameters())).ToArray();
                Assert.Equal(3, filterForActivity.Length);
                Assert.Equal(null, filterForActivity[0].Description);
                Assert.Equal(null, filterForActivity[0].Code);
                Assert.Equal("Banta", filterForActivity[1].Description);
                Assert.Equal("B", filterForActivity[1].Code);
                Assert.Equal("Santa", filterForActivity[2].Description);
                Assert.Equal("A", filterForActivity[2].Code);
            }
        }

        public class Export : FactBase
        {
            [Fact]
            public async Task ReturnsErrorIfUnauthorised()
            {
                var exportParams = new TimeSearchController.TimeSearchExportParams
                {
                    SearchParams = new TimeSearchParams
                    {
                        FromDate = Fixture.Monday,
                        ToDate = Fixture.Tuesday,
                        IsPosted = Fixture.Boolean(),
                        IsUnposted = Fixture.Boolean(),
                        StaffId = Fixture.Integer()
                    }
                };
                var f = new TimeSearchControllerFixture(Db);
                f.FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, Arg.Any<User>(), Arg.Any<int>()).Returns(false);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Export(exportParams));
                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
            }

            [Theory]
            [InlineData(ReportExportFormat.Pdf)]
            [InlineData(ReportExportFormat.Excel)]
            [InlineData(ReportExportFormat.Word)]
            [InlineData(ReportExportFormat.Pdf, false)]
            [InlineData(ReportExportFormat.Excel, false)]
            [InlineData(ReportExportFormat.Word, false)]
            public async Task CreatesCorrectExportJob(ReportExportFormat exportFormat, bool displaySeconds = true)
            {
                var data = new[]
                {
                    new TimeEntry {CaseKey = 101, CaseReference = "B", StartTime = new DateTime(2010, 02, 02, 10, 11, 12), Instructor = "Z", Debtor = "A", Activity = "Z", LocalValue = 100, LocalDiscount = 100, ForeignValue = 100, ForeignDiscount = 100, TotalTime = new DateTime(2010, 1, 1), NarrativeText = "Z1"},
                    new TimeEntry {CaseKey = 100, CaseReference = "A", StartTime = new DateTime(2010, 01, 01, 10, 11, 12), Debtor = "C", Activity = "B", LocalValue = 10 , LocalDiscount = 10, ForeignValue = 10, ForeignDiscount = 10, TotalTime = new DateTime(2009, 1, 1), NarrativeText = "C1"},
                    new TimeEntry {CaseKey = 102, CaseReference = "C", StartTime = new DateTime(2009, 01, 02, 10, 11, 12)},
                    new TimeEntry {CaseKey = 101, CaseReference = "B", StartTime = new DateTime(2010, 02, 02, 10, 11, 12), Instructor = "Z", Debtor = "A", Activity = "Z", LocalValue = 100, LocalDiscount = 100, ForeignValue = 100, ForeignDiscount = 100, TotalTime = new DateTime(2010, 1, 1), NarrativeText = "Z1"},
                };
                var query = new TimeSearchController.TimeSearchExportParams()
                {
                    SearchParams = new TimeSearchParams(),
                    QueryParams = new CommonQueryParameters
                    {
                        SortBy = "caseReference",
                        SortDir = "asc",
                        Skip = 0,
                        Take = 3,
                    },
                    Columns = new[]
                    {
                        new Column{Name = "Start", Title = "Date"},
                        new Column{Name = "LocalValue", Title = "Value"},
                        new Column{Name = "TotalDuration", Title = "Time"},
                        new Column{Name = "ElapsedTimeInSeconds", Title = "Time"},
                        new Column{Name = "ForeignValue", Title = "Foreign"},
                        new Column{Name = "TotalUnits", Title = "Units"}
                    },
                    ContentId = Fixture.Integer(),
                    ExportFormat = exportFormat
                };
                var f = new TimeSearchControllerFixture(Db);
                var localCurrency = Fixture.RandomString(3);
                f.SiteControlReader.Read<string>(SiteControls.CURRENCY).Returns(localCurrency);
                f.ExportSettings.Load(Arg.Any<string>(), QueryContext.TimeEntrySearch).Returns(new SearchResultsSettings {ReportTitle = "localised-title"});
                f.StaticTranslator.TranslateWithDefault(Arg.Any<string>(), Arg.Any<IEnumerable<string>>()).Returns("localised-label");
                f.TimeSearchService.Search(query.SearchParams, Arg.Any<IEnumerable<FilterValue>>()).ReturnsForAnyArgs(data.AsDbAsyncEnumerble());
                f.UserPreferenceManager.GetPreference<bool>(Arg.Any<int>(), KnownSettingIds.DisplayTimeWithSeconds).Returns(displaySeconds);
                
                await f.Subject.Export(query);
                f.StaticTranslator.Received(1).TranslateWithDefault("accounting.time.query.reportTitle", Arg.Any<IEnumerable<string>>());
                await f.Bus.Received()
                       .PublishAsync(Arg.Is<ExportExecutionJobArgs>(_ =>
                                                                        _.Settings.LocalCurrencyCode == localCurrency &&
                                                                        _.Settings.ReportTitle == "localised-title" &&
                                                                        _.ExportRequest.ExportFormat == exportFormat &&
                                                                        _.ExportRequest.SearchExportContentId == query.ContentId &&
                                                                        _.ExportRequest.Rows.Count == 4 &&
                                                                        _.ExportRequest.SearchPresentation == null && 
                                                                        _.ExportRequest.RunBy == f.CurrentUser.Id &&
                                                                        _.ExportRequest.Columns.All(c => c.Title == "localised-label") &&
                                                                        _.ExportRequest.Columns.Any(c => c.Name == "Start" && c.Format == ColumnFormats.Date) &&
                                                                        _.ExportRequest.Columns.Any(c => c.Name == "LocalValue" && c.Format == ColumnFormats.LocalCurrency) &&
                                                                        _.ExportRequest.Columns.Any(c => c.Name == "TotalDuration" && c.Format == (displaySeconds ? ColumnFormats.HoursWithSeconds : ColumnFormats.HoursWithMinutes)) &&
                                                                        _.ExportRequest.Columns.Any(c => c.Name == "TotalUnits" && c.Format == ColumnFormats.Integer) &&
                                                                        _.ExportRequest.Columns.Any(c => c.Name == "ForeignValue" && c.Format == ColumnFormats.Currency && c.CurrencyCodeColumnName == "ForeignCurrency")));
            }
        }

        public class TimeSearchControllerFixture : IFixture<TimeSearchController>
        {
            public TimeSearchControllerFixture(InMemoryDbContext db)
            {
                FunctionSecurityProvider = Substitute.For<IFunctionSecurityProvider>();
                FunctionSecurityProvider.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanRead, Arg.Any<User>(), Arg.Any<int>()).Returns(true);
                SecurityContext = Substitute.For<ISecurityContext>();
                CurrentUser = new UserBuilder(db).Build();
                SecurityContext.User.Returns(CurrentUser);
                TimeSheetList = Substitute.For<ITimesheetList>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                DisplayFormattedName = Substitute.For<IDisplayFormattedName>();
                TimeSummaryProvider = Substitute.For<ITimeSummaryProvider>();
                UserPreferenceManager = Substitute.For<IUserPreferenceManager>();
                Substitute.For<ISearchResultsExport>();
                ExportSettings = Substitute.For<IExportSettings>();
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                StaticTranslator = Substitute.For<IStaticTranslator>();
                Bus = Substitute.For<IBus>();
                TimeSearchService = Substitute.For<ITimeSearchService>();

                Subject = new TimeSearchController(TimeSheetList,
                                                   FunctionSecurityProvider,
                                                   SecurityContext,
                                                   SiteControlReader,
                                                   db,
                                                   TimeSummaryProvider,
                                                   DisplayFormattedName,
                                                   UserPreferenceManager,
                                                   PreferredCultureResolver,
                                                   StaticTranslator,
                                                   Bus,
                                                   ExportSettings,
                                                   TimeSearchService);
            }

            public User CurrentUser {get; }
            public IUserPreferenceManager UserPreferenceManager { get; }
            public ITimeSummaryProvider TimeSummaryProvider { get; }
            public ISiteControlReader SiteControlReader { get; }
            public IFunctionSecurityProvider FunctionSecurityProvider { get; }
            ISecurityContext SecurityContext { get; }
            ITimesheetList TimeSheetList { get; }
            public IDisplayFormattedName DisplayFormattedName { get; }
            public IExportSettings ExportSettings { get; }
            IPreferredCultureResolver PreferredCultureResolver { get; }
            public IBus Bus { get; }
            public IStaticTranslator StaticTranslator { get; }
            public ITimeSearchService TimeSearchService { get; }
            public TimeSearchController Subject { get; }
        }
    }
}