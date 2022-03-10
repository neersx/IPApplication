using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Accounting.Time.Search;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class TimeRecordingBatchControllerFacts
    {
        public class Delete
        {
            [Fact]
            public async Task ThrowsExceptionIfFunctionSecurityNotSet()
            {
                var f = new TimeRecordingBatchControllerFixture();
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, Arg.Any<User>(), 100).Returns(false);

                var ex = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.Delete(new BatchSelectionDetails{StaffNameId = 100, EntryNumbers = new []{1}}));
                Assert.IsType<HttpResponseException>(ex);
                Assert.Equal(HttpStatusCode.Forbidden, ex.Response.StatusCode);
            }

            [Fact]
            public void DeletesSelectedEntryNosForStaffOnly()
            {
                var d1 = new Diary {EntryNo = 1, EmployeeNo = 10};
                var d2 = new Diary {EntryNo = 2, EmployeeNo = 10};

                var timeEntries = new[]
                {
                    new TimeEntry {EntryNo = 1, StaffId = 10, StartTime = new DateTime(2010, 1, 1, 1, 0, 0)},
                    new TimeEntry {EntryNo = 2, StaffId = 10, StartTime = new DateTime(2010, 1, 1, 2, 0, 0)}
                };

                var f = new TimeRecordingBatchControllerFixture();
                f.TimesheetList.SearchFor(Arg.Any<int>(), Arg.Any<int[]>()).Returns(_ => timeEntries.AsQueryable());
                f.TimesheetList.DiaryFor(10, new DateTime(2010, 1, 1)).Returns(new[] {d1, d2}.AsQueryable());

                var input = new BatchSelectionDetails {StaffNameId = 10, EntryNumbers = new[] {1, 2}};
                f.Subject.Delete(input).IgnoreAwaitForNSubstituteAssertion();

                f.TimesheetList.Received(1).SearchFor(Arg.Is<int>(x => x == 10), Arg.Is<int[]>(x => x == input.EntryNumbers));
                f.TimesheetList.Received(1).DiaryFor(Arg.Is<int>(x => x == 10), Arg.Is<DateTime>(x => x == new DateTime(2010, 1, 1)));
                f.DiaryUpdate.Received(1).BatchDelete(10, Arg.Is<int[]>(x => x.Contains(1) && x.Contains(2) && x.Length == 2));
            }

            [Fact]
            public void DeletesSelectedEntryNosExcludesPostedItems()
            {
                var d1 = new Diary {EntryNo = 1};

                var timeEntries = new[]
                {
                    new TimeEntry {EntryNo = 1, StartTime = new DateTime(2010, 1, 1, 1, 0, 0)},
                    new TimeEntry {EntryNo = 2, StartTime = new DateTime(2010, 1, 2, 2, 0, 0), TransNo = 1}
                };

                var f = new TimeRecordingBatchControllerFixture();
                f.TimesheetList.SearchFor(Arg.Any<int>(), Arg.Any<int[]>()).Returns(_ => timeEntries.AsQueryable());
                f.TimesheetList.DiaryFor(10, new DateTime(2010, 1, 1)).Returns(new[] {d1}.AsQueryable());

                var input = new BatchSelectionDetails {StaffNameId = 10, EntryNumbers = new[] {1, 2}};
                f.Subject.Delete(input).IgnoreAwaitForNSubstituteAssertion();

                f.TimesheetList.Received(1).SearchFor(Arg.Is<int>(x => x == 10), Arg.Is<int[]>(x => x == input.EntryNumbers));
                f.TimesheetList.Received(1).DiaryFor(Arg.Is<int>(x => x == 10), Arg.Is<DateTime>(x => x == new DateTime(2010, 1, 1)));
                f.DiaryUpdate.Received(1).BatchDelete(10, Arg.Is<int[]>(x => x.Contains(1) && !x.Contains(2) && x.Length == 1));
            }

            [Fact]
            public void DeletesFromSearchCriteria()
            {
                var d1 = new Diary {EntryNo = 1, EmployeeNo = 10};
                var d2 = new Diary {EntryNo = 2, EmployeeNo = 10};

                var timeEntries = new[]
                {
                    new TimeEntry {EntryNo = 1, StaffId = 10, StartTime = new DateTime(2010, 1, 1, 1, 0, 0)},
                    new TimeEntry {EntryNo = 2, StaffId = 10, StartTime = new DateTime(2010, 1, 1, 2, 0, 0)}
                };

                var f = new TimeRecordingBatchControllerFixture();
                f.TimeSearchService.Search(Arg.Any<TimeSearchParams>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(timeEntries.AsQueryable());
                f.TimesheetList.DiaryFor(10, new DateTime(2010, 1, 1)).Returns(new[] {d1, d2}.AsQueryable());

                var queryParams = new CommonQueryParameters {Filters = new[] {new CommonQueryParameters.FilterValue {Field = "caseReference", Value = "1,2"}}};
                var searchParams = new TimeSearchParams {ActivityId = "My Activity Is A"};
                var input = new BatchSelectionDetails {StaffNameId = 10, ReverseSelection = new ReverseSelection() {SearchParams = searchParams, QueryParams = queryParams}};

                f.Subject.Delete(input).IgnoreAwaitForNSubstituteAssertion();

                f.TimeSearchService.Received(1).Search(Arg.Is<TimeSearchParams>(x => x == searchParams), Arg.Is<IEnumerable<CommonQueryParameters.FilterValue>>(x => x.Equals(queryParams.Filters)));
                f.TimesheetList.Received(1).DiaryFor(Arg.Is<int>(x => x == 10), Arg.Is<DateTime>(x => x == new DateTime(2010, 1, 1)));
                f.DiaryUpdate.Received(1).BatchDelete(10, Arg.Is<int[]>(x => x.Contains(1) && x.Contains(2) && x.Length == 2));
            }

            [Fact]
            public void DeletesFromSearchCriteriaExceptDeselectdEntryNos()
            {
                var d2 = new Diary {EntryNo = 2};

                var timeEntries = new[]
                {
                    new TimeEntry {EntryNo = 1, StartTime = new DateTime(2010, 1, 1, 1, 0, 0)},
                    new TimeEntry {EntryNo = 2, StartTime = new DateTime(2010, 1, 2, 2, 0, 0)}
                };

                var f = new TimeRecordingBatchControllerFixture();
                f.TimeSearchService.Search(Arg.Any<TimeSearchParams>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(timeEntries.AsQueryable());
                f.TimesheetList.DiaryFor(10, new DateTime(2010, 1, 2)).Returns(new[] {d2}.AsQueryable());

                var queryParams = new CommonQueryParameters();
                var searchParams = new TimeSearchParams();
                var input = new BatchSelectionDetails {StaffNameId = 10, ReverseSelection = new ReverseSelection {SearchParams = searchParams, QueryParams = queryParams, ExceptEntryNumbers = new[] {1}}};

                f.Subject.Delete(input).IgnoreAwaitForNSubstituteAssertion();

                f.TimeSearchService.Received(1).Search(Arg.Is<TimeSearchParams>(x => x == searchParams), Arg.Is<IEnumerable<CommonQueryParameters.FilterValue>>(x => x.Equals(queryParams.Filters)));
                f.TimesheetList.Received(1).DiaryFor(Arg.Is<int>(x => x == 10), Arg.Is<DateTime>(x => x == new DateTime(2010, 1, 2)));
                f.DiaryUpdate.Received(1).BatchDelete(10, Arg.Is<int[]>(x => !x.Contains(1) && x.Contains(2) && x.Length == 1));
            }

            [Fact]
            public void DeletesWholeContinuedChain()
            {
                var d1 = new Diary {EntryNo = 1, ParentEntryNo = 3};
                var d2 = new Diary {EntryNo = 2};
                var d3 = new Diary {EntryNo = 3, ParentEntryNo = 4};
                var d4 = new Diary {EntryNo = 4};

                var timeEntries = new[]
                {
                    new TimeEntry {EntryNo = 1, StartTime = new DateTime(2010, 1, 1, 1, 0, 0)},
                    new TimeEntry {EntryNo = 2, StartTime = new DateTime(2010, 1, 1, 2, 0, 0)}
                };

                var f = new TimeRecordingBatchControllerFixture();
                f.TimesheetList.SearchFor(Arg.Any<int>(), Arg.Any<int[]>()).Returns(_ => timeEntries.AsQueryable());
                f.TimesheetList.DiaryFor(10, new DateTime(2010, 1, 1)).Returns(new[] {d1, d2, d3, d4}.AsQueryable());

                var input = new BatchSelectionDetails {StaffNameId = 10, EntryNumbers = new[] {1, 2}};
                f.Subject.Delete(input).IgnoreAwaitForNSubstituteAssertion();

                f.TimesheetList.Received(1).SearchFor(Arg.Is<int>(x => x == 10), Arg.Is<int[]>(x => x == input.EntryNumbers));
                f.TimesheetList.Received(1).DiaryFor(Arg.Is<int>(x => x == 10), Arg.Is<DateTime>(x => x == new DateTime(2010, 1, 1)));
                f.DiaryUpdate.Received(1).BatchDelete(10, Arg.Is<int[]>(x => x.Contains(1) && x.Contains(2) && x.Contains(3) && x.Contains(4) && x.Length == 4));
            }
        }

        public class UpdateNarratives : FactBase
        {
            [Fact]
            public async Task ThrowsExceptionIfFunctionSecurityNotSet()
            {
                var f = new TimeRecordingBatchControllerFixture();
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanUpdate, Arg.Any<User>(), 100).Returns(false);
                var request = new TimeRecordingBatchController.BatchNarrativeRequest()
                {
                    SelectionDetails = new BatchSelectionDetails{StaffNameId = 100, EntryNumbers = new []{1}},
                    NewNarrative = new TimeRecordingBatchController.NewNarrative{NarrativeText = Fixture.String()}
                };
                var ex = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.UpdateNarrative(request));
                Assert.IsType<HttpResponseException>(ex);
                Assert.Equal(HttpStatusCode.Forbidden, ex.Response.StatusCode);
            }

            [Fact]
            public void UpdatesNarrativeForSelectedEntryNosForStaffOnly()
            {
                var d1 = new Diary {EntryNo = 1, EmployeeNo = 10};
                var d2 = new Diary {EntryNo = 2, EmployeeNo = 10};

                var timeEntries = new[]
                {
                    new TimeEntry {EntryNo = 1, StaffId = 10, StartTime = new DateTime(2010, 1, 1, 1, 0, 0)},
                    new TimeEntry {EntryNo = 2, StaffId = 10, StartTime = new DateTime(2010, 1, 1, 2, 0, 0)}
                };
                var request = new TimeRecordingBatchController.BatchNarrativeRequest()
                {
                    SelectionDetails = new BatchSelectionDetails{StaffNameId = 10, EntryNumbers = new[] {1, 2}},
                    NewNarrative = new TimeRecordingBatchController.NewNarrative{NarrativeText = Fixture.String("narrative-")}
                };

                var f = new TimeRecordingBatchControllerFixture();
                f.TimesheetList.SearchFor(Arg.Any<int>(), Arg.Any<int[]>()).Returns(_ => timeEntries.AsQueryable());
                f.TimesheetList.DiaryFor(10, new DateTime(2010, 1, 1)).Returns(new[] {d1, d2}.AsQueryable());

                f.Subject.UpdateNarrative(request).IgnoreAwaitForNSubstituteAssertion();

                f.TimesheetList.Received(1).SearchFor(Arg.Is<int>(x => x == 10), Arg.Is<int[]>(x => x == request.SelectionDetails.EntryNumbers));
                f.TimesheetList.Received(1).DiaryFor(Arg.Is<int>(x => x == 10), Arg.Is<DateTime>(x => x == new DateTime(2010, 1, 1)));
                f.DiaryUpdate.Received(1).BatchUpdateNarratives(10, Arg.Is<int[]>(x => x.Contains(1) && x.Contains(2) && x.Length == 2), request.NewNarrative.NarrativeText);
            }

            [Fact]
            public void BatchNarrativeUpdateExcludesPostedItems()
            {
                var d1 = new Diary {EntryNo = 1};

                var timeEntries = new[]
                {
                    new TimeEntry {EntryNo = 1, StartTime = new DateTime(2010, 1, 1, 1, 0, 0)},
                    new TimeEntry {EntryNo = 2, StartTime = new DateTime(2010, 1, 2, 2, 0, 0), TransNo = 1}
                };
                var request = new TimeRecordingBatchController.BatchNarrativeRequest()
                {
                    SelectionDetails = new BatchSelectionDetails{StaffNameId = 10, EntryNumbers = new[] {1, 2}},
                    NewNarrative = new TimeRecordingBatchController.NewNarrative{NarrativeText = Fixture.String("narrative-")}
                };

                var f = new TimeRecordingBatchControllerFixture();
                f.TimesheetList.SearchFor(Arg.Any<int>(), Arg.Any<int[]>()).Returns(_ => timeEntries.AsQueryable());
                f.TimesheetList.DiaryFor(10, new DateTime(2010, 1, 1)).Returns(new[] {d1}.AsQueryable());

                f.Subject.UpdateNarrative(request).IgnoreAwaitForNSubstituteAssertion();

                f.TimesheetList.Received(1).SearchFor(Arg.Is<int>(x => x == 10), Arg.Is<int[]>(x => x == request.SelectionDetails.EntryNumbers));
                f.TimesheetList.Received(1).DiaryFor(Arg.Is<int>(x => x == 10), Arg.Is<DateTime>(x => x == new DateTime(2010, 1, 1)));
                f.DiaryUpdate.Received(1).BatchUpdateNarratives(10, Arg.Is<int[]>(x => x.Contains(1) && !x.Contains(2) && x.Length == 1), request.NewNarrative.NarrativeText);
            }

            [Fact]
            public void UpdatesNarrativeMatchingSearchCriteria()
            {
                var d1 = new Diary {EntryNo = 1, EmployeeNo = 10};
                var d2 = new Diary {EntryNo = 2, EmployeeNo = 10};

                var timeEntries = new[]
                {
                    new TimeEntry {EntryNo = 1, StaffId = 10, StartTime = new DateTime(2010, 1, 1, 1, 0, 0)},
                    new TimeEntry {EntryNo = 2, StaffId = 10, StartTime = new DateTime(2010, 1, 1, 2, 0, 0)}
                };
                var queryParams = new CommonQueryParameters {Filters = new[] {new CommonQueryParameters.FilterValue {Field = "caseReference", Value = "1,2"}}};
                var searchParams = new TimeSearchParams {ActivityId = "My Activity Is A"};
                var request = new TimeRecordingBatchController.BatchNarrativeRequest()
                {
                    SelectionDetails = new BatchSelectionDetails{StaffNameId = 10, ReverseSelection = new ReverseSelection() {SearchParams = searchParams, QueryParams = queryParams}},
                    NewNarrative = new TimeRecordingBatchController.NewNarrative{NarrativeText = Fixture.String("narrative-")}
                };

                var f = new TimeRecordingBatchControllerFixture();
                f.TimeSearchService.Search(Arg.Any<TimeSearchParams>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(timeEntries.AsQueryable());
                f.TimesheetList.DiaryFor(10, new DateTime(2010, 1, 1)).Returns(new[] {d1, d2}.AsQueryable());
                
                f.Subject.UpdateNarrative(request).IgnoreAwaitForNSubstituteAssertion();

                f.TimeSearchService.Received(1).Search(Arg.Is<TimeSearchParams>(x => x == searchParams), Arg.Is<IEnumerable<CommonQueryParameters.FilterValue>>(x => x.Equals(queryParams.Filters)));
                f.TimesheetList.Received(1).DiaryFor(Arg.Is<int>(x => x == 10), Arg.Is<DateTime>(x => x == new DateTime(2010, 1, 1)));
                f.DiaryUpdate.Received(1).BatchUpdateNarratives(10, Arg.Is<int[]>(x => x.Contains(1) && x.Contains(2) && x.Length == 2), request.NewNarrative.NarrativeText);
            }

            [Fact]
            public void ExcludestDeselectdEntryNos()
            {
                var d2 = new Diary {EntryNo = 2};

                var timeEntries = new[]
                {
                    new TimeEntry {EntryNo = 1, StartTime = new DateTime(2010, 1, 1, 1, 0, 0)},
                    new TimeEntry {EntryNo = 2, StartTime = new DateTime(2010, 1, 2, 2, 0, 0)}
                };

                var queryParams = new CommonQueryParameters();
                var searchParams = new TimeSearchParams();
                var request = new TimeRecordingBatchController.BatchNarrativeRequest()
                {
                    SelectionDetails = new BatchSelectionDetails {StaffNameId = 10, ReverseSelection = new ReverseSelection {SearchParams = searchParams, QueryParams = queryParams, ExceptEntryNumbers = new[] {1}}},
                    NewNarrative = new TimeRecordingBatchController.NewNarrative{NarrativeText = Fixture.String("narrative-")}
                };

                var f = new TimeRecordingBatchControllerFixture();
                f.TimeSearchService.Search(Arg.Any<TimeSearchParams>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(timeEntries.AsQueryable());
                f.TimesheetList.DiaryFor(10, new DateTime(2010, 1, 2)).Returns(new[] {d2}.AsQueryable());

                f.Subject.UpdateNarrative(request).IgnoreAwaitForNSubstituteAssertion();

                f.TimeSearchService.Received(1).Search(Arg.Is<TimeSearchParams>(x => x == searchParams), Arg.Is<IEnumerable<CommonQueryParameters.FilterValue>>(x => x.Equals(queryParams.Filters)));
                f.TimesheetList.Received(1).DiaryFor(Arg.Is<int>(x => x == 10), Arg.Is<DateTime>(x => x == new DateTime(2010, 1, 2)));
                f.DiaryUpdate.Received(1).BatchUpdateNarratives(10, Arg.Is<int[]>(x => !x.Contains(1) && x.Contains(2) && x.Length == 1), request.NewNarrative.NarrativeText);
            }

            [Fact]
            public void UpdatesNarrativeForWholeContinuedChain()
            {
                var d1 = new Diary {EntryNo = 1, ParentEntryNo = 3};
                var d2 = new Diary {EntryNo = 2};
                var d3 = new Diary {EntryNo = 3, ParentEntryNo = 4};
                var d4 = new Diary {EntryNo = 4};

                var timeEntries = new[]
                {
                    new TimeEntry {EntryNo = 1, StartTime = new DateTime(2010, 1, 1, 1, 0, 0)},
                    new TimeEntry {EntryNo = 2, StartTime = new DateTime(2010, 1, 1, 2, 0, 0)}
                };

                var request = new TimeRecordingBatchController.BatchNarrativeRequest()
                {
                    SelectionDetails = new BatchSelectionDetails {StaffNameId = 10, EntryNumbers = new[] {1, 2}},
                    NewNarrative = new TimeRecordingBatchController.NewNarrative{NarrativeText = Fixture.String("narrative-")}
                };

                var f = new TimeRecordingBatchControllerFixture();
                f.TimesheetList.SearchFor(Arg.Any<int>(), Arg.Any<int[]>()).Returns(_ => timeEntries.AsQueryable());
                f.TimesheetList.DiaryFor(10, new DateTime(2010, 1, 1)).Returns(new[] {d1, d2, d3, d4}.AsQueryable());

                f.Subject.UpdateNarrative(request).IgnoreAwaitForNSubstituteAssertion();

                f.TimesheetList.Received(1).SearchFor(Arg.Is<int>(x => x == 10), Arg.Is<int[]>(x => x == request.SelectionDetails.EntryNumbers));
                f.TimesheetList.Received(1).DiaryFor(Arg.Is<int>(x => x == 10), Arg.Is<DateTime>(x => x == new DateTime(2010, 1, 1)));
                f.DiaryUpdate.Received(1).BatchUpdateNarratives(10, Arg.Is<int[]>(x => x.Contains(1) && x.Contains(2) && x.Contains(3) && x.Contains(4) && x.Length == 4), request.NewNarrative.NarrativeText);
            }

        }
    }

    public class TimeRecordingBatchControllerFixture : IFixture<TimeRecordingBatchController>
    {
        public TimeRecordingBatchControllerFixture()
        {
            FunctionSecurity = Substitute.For<IFunctionSecurityProvider>();
            FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanDelete, Arg.Any<User>(), 10).Returns(true);
            FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanUpdate, Arg.Any<User>(), 10).Returns(true);
            SecurityContext = Substitute.For<ISecurityContext>();
            TimesheetList = Substitute.For<ITimesheetList>();
            TimeSearchService = Substitute.For<ITimeSearchService>();
            DiaryUpdate = Substitute.For<IDiaryUpdate>();

            Subject = new TimeRecordingBatchController(SecurityContext, FunctionSecurity, TimesheetList, TimeSearchService, DiaryUpdate);
        }

        public TimeRecordingBatchController Subject { get; }

        public IFunctionSecurityProvider FunctionSecurity { get; }

        public ISecurityContext SecurityContext { get; }

        public ITimesheetList TimesheetList { get; }

        public ITimeSearchService TimeSearchService { get; }

        public IDiaryUpdate DiaryUpdate { get; }
    }
}