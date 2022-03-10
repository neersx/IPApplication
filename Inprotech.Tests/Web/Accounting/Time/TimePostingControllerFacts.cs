using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Accounting;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Accounting.Time.Search;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class TimePostingControllerFacts : FactBase
    {
        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ViewDataReturnsData(bool defaultsFromCaseOffice)
        {
            var entityNames = new[] {new EntityName(), new EntityName()};
            const bool automaticWipEntity = false;

            var f = new TimePostingControllerFixture(Db).WithViewData(entityNames, automaticWipEntity, defaultsFromCaseOffice);

            var result = await f.Subject.ViewData();

            if (defaultsFromCaseOffice)
            {
                f.Entities.DidNotReceive().Get(Arg.Any<int>()).IgnoreAwaitForNSubstituteAssertion();
                Assert.Null(result.Entities);
            }
            else
            {
                f.Entities.Received(1).Get(Arg.Is<int>(_ => _ == f.CurrentUser.NameId)).IgnoreAwaitForNSubstituteAssertion();
                f.SiteControlReader.Received(1).Read<bool>(Arg.Is<string>(_ => _ == SiteControls.AutomaticWIPEntity));
                f.SiteControlReader.Received(1).ReadMany<bool>(Arg.Is<string[]>(_ => _.Contains(SiteControls.EntityDefaultsFromCaseOffice) && _.Contains(SiteControls.RowSecurityUsesCaseOffice)));
                Assert.Equal(entityNames, result.Entities);
            }

            Assert.Equal(automaticWipEntity, result.HasFixedEntity);
            Assert.Equal(defaultsFromCaseOffice, result.PostToCaseOfficeEntity);
        }

        [Fact]
        public async Task RetrievesAllEntitiesInPre14Version()
        {
            var entityNames = new[] {new EntityName(), new EntityName()};
            var f = new TimePostingControllerFixture(Db).WithViewData(entityNames, false, false);
            f.SiteControlReader
             .ReadMany<bool>(Arg.Is<string[]>(_ => _.Contains(SiteControls.EntityDefaultsFromCaseOffice) &&
                                                   _.Contains(SiteControls.RowSecurityUsesCaseOffice)))
             .Returns(new Dictionary<string, bool>
             {
                 {
                     "RowSecurityUsesCaseOffice", true
                 }
             });

            var result = await f.Subject.ViewData();
            f.Entities.Received(1).Get(Arg.Is<int>(_ => _ == f.CurrentUser.NameId)).IgnoreAwaitForNSubstituteAssertion();
            f.SiteControlReader.Received(1).Read<bool>(Arg.Is<string>(_ => _ == SiteControls.AutomaticWIPEntity));
            f.SiteControlReader.Received(1).ReadMany<bool>(Arg.Is<string[]>(_ => _.Contains(SiteControls.EntityDefaultsFromCaseOffice) && _.Contains(SiteControls.RowSecurityUsesCaseOffice)));
            Assert.Equal(entityNames, result.Entities);
            Assert.False(result.HasFixedEntity);
            Assert.False(result.PostToCaseOfficeEntity);
        }

        [Theory]
        [InlineData(true, true)]
        [InlineData(true, false)]
        [InlineData(false)]
        public async Task CallsPostingTimeWithCorrectInputAndReturnsResult(bool hasOfficeEntityError, bool forOtherStaff = false)
        {
            var otherStaff = Fixture.Integer();
            var input = new PostTimeRequest {EntityKey = -1000, SelectedDates = new List<DateTime> {new(2009, 1, 1), new(2010, 2, 2)}, StaffNameId = forOtherStaff ? otherStaff : null};
            var output = new PostTimeResult(10, 100, hasOfficeEntityError);

            var f = new TimePostingControllerFixture(Db).WithPostResult(output);
            var result = await f.Subject.PostTimeEntries(input);

            f.PostTimeCommand
             .Received(1)
             .PostTime(Arg.Is<PostTimeArgs>(_ => _.UserIdentityId == f.CurrentUser.Id &&
                                                 _.EntityKey == input.EntityKey &&
                                                 Equals(_.SelectedDates, input.SelectedDates.AsEnumerable()) && 
                                                 _.StaffNameNo ==
                                                 (forOtherStaff
                                                     ? otherStaff
                                                     : f.SecurityContext.User.NameId)))
             .IgnoreAwaitForNSubstituteAssertion();

            Assert.Equal(output.RowsPosted, result.RowsPosted);
            Assert.Equal(output.RowsIncomplete, result.RowsIncomplete);
            Assert.Equal(output.HasOfficeEntityError, hasOfficeEntityError);
        }

        [Fact]
        public async Task PerformsValidationOnPostDate()
        {
            var input = new PostTimeRequest {EntityKey = -1000, SelectedDates = null, StaffNameId = 10};
            var output = new PostTimeResult(1, 100);

            var f = new TimePostingControllerFixture(Db).WithPostResult(output);

            f.DiaryDatesReader.GetDiaryDatesFor(Arg.Any<int>(), Arg.Any<DateTime>()).ReturnsForAnyArgs(new List<PostableDate> {new PostableDate(Fixture.Monday, 10, 10)});
            f.ValidatePostDates.For(Arg.Any<DateTime>()).ReturnsForAnyArgs((isValid: true, isWarningOnly: false, code: string.Empty));

            await f.Subject.PostTimeEntries(input);

            f.DiaryDatesReader.Received(1).GetDiaryDatesFor(Arg.Is<int>(_ => _ == 10), Arg.Is<DateTime>(_ => _ == Fixture.Today().Date))
             .IgnoreAwaitForNSubstituteAssertion();
            f.ValidatePostDates.Received(1).For(Arg.Is<DateTime>(_ => _ == Fixture.Monday))
             .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task DoesNotCallValidationIfWarningAccepted()
        {
            var input = new PostTimeRequest {EntityKey = -1000, SelectedDates = new List<DateTime> {new DateTime(2009, 1, 1), new DateTime(2010, 2, 2)}, StaffNameId = 10, WarningAccepted = true};
            var output = new PostTimeResult(1, 100);

            var f = new TimePostingControllerFixture(Db).WithPostResult(output);

            f.DiaryDatesReader.GetDiaryDatesFor(Arg.Any<int>(), Arg.Any<int[]>()).ReturnsForAnyArgs(new List<DateTime> {Fixture.Monday});
            f.ValidatePostDates.For(Arg.Any<DateTime>()).ReturnsForAnyArgs((isValid: true, isWarningOnly: false, code: string.Empty));

            await f.Subject.PostTimeEntries(input);

            f.DiaryDatesReader.Received(0).GetDiaryDatesFor(Arg.Any<int>(), Arg.Any<DateTime>())
             .IgnoreAwaitForNSubstituteAssertion();
            f.ValidatePostDates.Received(0).For(Arg.Any<DateTime>())
             .IgnoreAwaitForNSubstituteAssertion();
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task GetDiaryDatesReturnsDataFromReader(bool forOtherStaff)
        {
            var otherStaff = Fixture.Integer();
            var dates = new[] {new PostableDate(Fixture.Today(), 100, 10), new PostableDate(Fixture.Today(), 300, 20)};

            var f = new TimePostingControllerFixture(Db).WithDatesData(dates);

            var result = await f.Subject.GetDateDetails(null, new PostDateRange(), forOtherStaff ? otherStaff : null);

            f.DiaryDatesReader.Received(1)
             .GetDiaryDatesFor(Arg.Is<int>(_ => _ == (forOtherStaff ? otherStaff : f.SecurityContext.User.NameId)), Arg.Is<DateTime>(_ => Fixture.Today().AddDays(1) == _))
             .IgnoreAwaitForNSubstituteAssertion();

            Assert.Equal(dates, result.Data);
        }

        [Theory]
        [InlineData(true, false)]
        [InlineData(false, true)]
        public async Task ThrowsErrorWhenBothDatesAreNotPassedIn(bool hasFromDate, bool hasToDate)
        {
            var f = new TimePostingControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<ArgumentException>(async () => await f.Subject.GetDateDetails(null, new PostDateRange { From = hasFromDate ? DateTime.Today : null, To = hasToDate ? DateTime.Today : null }));

            Assert.Equal("Both From and To dates must be specified.", exception.Message);
        }

        [Fact]
        public async Task ReturnAllEntriesWhenBothDatesPassedIn()
        {
            var f = new TimePostingControllerFixture(Db);
            var fromDate = DateTime.Today.AddDays(-10);
            var toDate = DateTime.Today;
            f.DiaryDatesReader.GetDiaryDatesFor(Arg.Any<DateTime?>(), Arg.Any<DateTime>()).ReturnsForAnyArgs(new List<PostableDate> {new PostableDate(Fixture.Monday, 10, 10)});
            await f.Subject.GetDateDetails(null, new PostDateRange { From = fromDate, To = toDate});

            await f.DiaryDatesReader.Received(1).GetDiaryDatesFor(fromDate, toDate.AddDays(1));
        }

        public class PostSelectedEntries : FactBase
        {
            [Theory]
            [InlineData(true, true)]
            [InlineData(true, false)]
            [InlineData(false)]
            public async Task CallsPostingEntryWithCorrectInputAndReturnsResult(bool hasOfficeEntityError, bool forOtherStaff = false)
            {
                var otherStaff = Fixture.Integer();
                var input = new PostEntry {EntityKey = -1000, EntryNo = 1, StaffNameId = forOtherStaff ? otherStaff : null};
                var output = new PostTimeResult(1, 100, hasOfficeEntityError);

                var f = new TimePostingControllerFixture(Db).WithPostResult(output);

                f.DiaryDatesReader.GetDiaryDatesFor(Arg.Any<int>(), Arg.Any<int[]>()).ReturnsForAnyArgs(new List<DateTime> {Fixture.Monday});
                f.ValidatePostDates.For(Arg.Any<DateTime>()).ReturnsForAnyArgs((isValid: true, isWarningOnly: false, code: string.Empty));

                var result = await f.Subject.PostSelectedEntries(input);

                f.PostTimeCommand
                 .Received(1)
                 .PostTime(Arg.Is<PostTimeArgs>(_ => _.UserIdentityId == f.CurrentUser.Id && _.StaffNameNo == (forOtherStaff ? otherStaff : f.SecurityContext.User.NameId) && _.EntityKey == input.EntityKey && _.SelectedEntryNos.All(e => e.Equals(input.EntryNo))))
                 .IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(output.RowsPosted, result.RowsPosted);
                Assert.Equal(output.RowsIncomplete, result.RowsIncomplete);
                Assert.Equal(output.HasOfficeEntityError, hasOfficeEntityError);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task PostsMultipleSelectedEntries(bool forOtherStaff = false)
            {
                var output = new PostTimeResult(Fixture.Short(), Fixture.Short());
                var f = new TimePostingControllerFixture(Db).WithPostResult(output);
                var otherStaff = f.SecurityContext.User.NameId + 1;
                var input = new PostEntry {EntityKey = Fixture.Integer(), EntryNumbers = new[] {Fixture.Integer(), Fixture.Short()}, StaffNameId = forOtherStaff ? otherStaff : null};
                f.DiaryDatesReader.GetDiaryDatesFor(Arg.Any<int>(), Arg.Any<int[]>()).ReturnsForAnyArgs(new List<DateTime> {Fixture.Monday});
                f.ValidatePostDates.For(Arg.Any<DateTime>()).ReturnsForAnyArgs((isValid: true, isWarningOnly: false, code: string.Empty));

                var result = await f.Subject.PostSelectedEntries(input);

                f.PostTimeCommand
                 .Received(1)
                 .PostTime(Arg.Is<PostTimeArgs>(_ => _.UserIdentityId == f.CurrentUser.Id &&
                                                     _.StaffNameNo == (forOtherStaff ? otherStaff : f.SecurityContext.User.NameId) &&
                                                     _.EntityKey == input.EntityKey &&
                                                     _.SelectedEntryNos == input.EntryNumbers))
                 .IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(output.RowsPosted, result.RowsPosted);
                Assert.Equal(output.RowsIncomplete, result.RowsIncomplete);
            }

            [Theory]
            [InlineData(true, true)]
            [InlineData(false, true)]
            [InlineData(true, false)]
            [InlineData(false, false)]
            public async Task PostsAllResults(bool forOtherStaff, bool withExceptions)
            {
                var output = new PostTimeResult(Fixture.Short(), Fixture.Short());
                var f = new TimePostingControllerFixture(Db).WithPostResult(output);
                var entryNo = Fixture.Integer();
                var data = new[]
                {
                    new TimeEntry {EntryNo = entryNo},
                    new TimeEntry {EntryNo = entryNo + 1},
                    new TimeEntry {EntryNo = entryNo + 2},
                    new TimeEntry {EntryNo = entryNo * 2},
                    new TimeEntry {EntryNo = entryNo * 10}
                };
                f.TimeSearchService.Search(Arg.Any<TimeSearchParams>(), Arg.Any<IEnumerable<CommonQueryParameters.FilterValue>>()).Returns(data.AsDbAsyncEnumerble());
                var otherStaff = f.SecurityContext.User.NameId + 1;
                var input = new PostEntry
                {
                    EntityKey = Fixture.Integer(),
                    IsSelectAll = true,
                    StaffNameId = forOtherStaff
                        ? otherStaff
                        : null,
                    ExceptEntryNumbers = withExceptions ? new[] {entryNo + 2, entryNo * 2} : null,
                    PostingParams = new TimePostingParams
                    {
                        QueryParams = CommonQueryParameters.Default,
                        SearchParams = new TimeSearchParams()
                    }
                };

                f.DiaryDatesReader.GetDiaryDatesFor(Arg.Any<int>(), Arg.Any<int[]>()).ReturnsForAnyArgs(new List<DateTime> {Fixture.Monday});
                f.ValidatePostDates.For(Arg.Any<DateTime>()).ReturnsForAnyArgs((isValid: true, isWarningOnly: false, code: string.Empty));

                var result = await f.Subject.PostSelectedEntries(input);

                f.PostTimeCommand
                 .Received(1)
                 .PostTime(Arg.Is<PostTimeArgs>(_ => _.UserIdentityId == f.CurrentUser.Id &&
                                                     _.StaffNameNo == (forOtherStaff ? otherStaff : f.SecurityContext.User.NameId) &&
                                                     _.EntityKey == input.EntityKey &&
                                                     _.SelectedEntryNos.Count() == (withExceptions ? 3 : 5)))
                 .IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(output.RowsPosted, result.RowsPosted);
                Assert.Equal(output.RowsIncomplete, result.RowsIncomplete);
            }

            [Fact]
            public async Task PerformsValidationOnPostDate()
            {
                var input = new PostEntry {EntityKey = -1000, EntryNo = 1, StaffNameId = 10};
                var output = new PostTimeResult(1, 100);

                var f = new TimePostingControllerFixture(Db).WithPostResult(output);

                f.DiaryDatesReader.GetDiaryDatesFor(Arg.Any<int>(), Arg.Any<int[]>()).ReturnsForAnyArgs(new List<DateTime> {Fixture.Monday});
                f.ValidatePostDates.For(Arg.Any<DateTime>()).ReturnsForAnyArgs((isValid: true, isWarningOnly: false, code: string.Empty));

                await f.Subject.PostSelectedEntries(input);

                f.DiaryDatesReader.Received(1).GetDiaryDatesFor(Arg.Is<int>(_ => _ == 10), Arg.Is<int[]>(_ => _.Length == 1 && _.First() == 1))
                 .IgnoreAwaitForNSubstituteAssertion();
                f.ValidatePostDates.Received(1).For(Arg.Is<DateTime>(_ => _ == Fixture.Monday))
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task DoesNotCallValidationIfWarningAccepted()
            {
                var input = new PostEntry {EntityKey = -1000, EntryNo = 1, StaffNameId = 10, WarningAccepted = true};
                var output = new PostTimeResult(1, 100);

                var f = new TimePostingControllerFixture(Db).WithPostResult(output);

                f.DiaryDatesReader.GetDiaryDatesFor(Arg.Any<int>(), Arg.Any<int[]>()).ReturnsForAnyArgs(new List<DateTime> {Fixture.Monday});
                f.ValidatePostDates.For(Arg.Any<DateTime>()).ReturnsForAnyArgs((isValid: true, isWarningOnly: false, code: string.Empty));

                await f.Subject.PostSelectedEntries(input);

                f.DiaryDatesReader.Received(0).GetDiaryDatesFor(Arg.Any<int>(), Arg.Any<int[]>())
                 .IgnoreAwaitForNSubstituteAssertion();
                f.ValidatePostDates.Received(0).For(Arg.Any<DateTime>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task PostsInBackgroundIfMoreThanAWeek()
            {
                var f = new TimePostingControllerFixture(Db);
                var entryDates = Enumerable.Repeat(0, 8).Select(_ => Fixture.Date()).ToList();
                var input = new PostTimeRequest { EntityKey = Fixture.Integer(), SelectedDates = entryDates};
                f.ValidatePostDates.For(Arg.Any<DateTime>()).ReturnsForAnyArgs((isValid: true, isWarningOnly: false, code: string.Empty));

                var result = await f.Subject.PostTimeEntries(input);

                f.Bus
                 .Received(1)
                 .PublishAsync(Arg.Is<PostTimeArgs>(_ => _.UserIdentityId == f.CurrentUser.Id &&
                                                         _.StaffNameNo == f.SecurityContext.User.NameId &&
                                                         _.EntityKey == input.EntityKey &&
                                                         Equals(_.SelectedDates, input.SelectedDates)))
                 .IgnoreAwaitForNSubstituteAssertion();
                Assert.True(result.IsBackground);
                Assert.Equal("success", result.Result);
            }

            [Fact]
            public async Task PostsInBackgroundIfMoreThan50()
            {
                var f = new TimePostingControllerFixture(Db);
                var entryNos = Enumerable.Repeat(0, 51).Select(_ => Fixture.Integer()).ToArray();
                var input = new PostEntry { EntityKey = Fixture.Integer(), EntryNumbers = entryNos };
                f.DiaryDatesReader.GetDiaryDatesFor(Arg.Any<int>(), Arg.Any<int[]>()).ReturnsForAnyArgs(new List<DateTime> {Fixture.Monday});
                f.ValidatePostDates.For(Arg.Any<DateTime>()).ReturnsForAnyArgs((isValid: true, isWarningOnly: false, code: string.Empty));

                var result = await f.Subject.PostSelectedEntries(input);

                f.Bus
                 .Received(1)
                 .PublishAsync(Arg.Is<PostTimeArgs>(_ => _.UserIdentityId == f.CurrentUser.Id &&
                                                     _.StaffNameNo == f.SecurityContext.User.NameId &&
                                                     _.EntityKey == input.EntityKey &&
                                                     _.SelectedEntryNos == input.EntryNumbers))
                 .IgnoreAwaitForNSubstituteAssertion();
                Assert.True(result.IsBackground);
                Assert.Equal("success", result.Result);
            }

            [Fact]
            public async Task ReturnsZeroResultsIfNoPostableDatesSelected()
            {
                var f = new TimePostingControllerFixture(Db);
                var entryNos = Enumerable.Repeat(0, 10).Select(_ => Fixture.Integer()).ToArray();
                var input = new PostEntry { EntityKey = Fixture.Integer(), EntryNumbers = entryNos };
                f.DiaryDatesReader.GetDiaryDatesFor(Arg.Any<int>(), Arg.Any<int[]>()).ReturnsForAnyArgs(Enumerable.Empty<DateTime>());
                var result = await f.Subject.PostSelectedEntries(input);
                f.Bus.DidNotReceive().PublishAsync(Arg.Any<PostTimeArgs>()).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(0, result.RowsPosted);
                Assert.Null(result.RowsIncomplete);
                Assert.False(result.HasError);
            }
        }

        public class PostForAllStaff : FactBase
        {
            [Fact]
            public async Task ThrowsForbiddenErrorWhenNoFunctionSecurityToPostForALlStaff()
            {
                var f = new TimePostingControllerFixture(Db);
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanPost, Arg.Any<User>()).Returns(false);
                var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.PostForAllStaff(new Inprotech.Web.Accounting.Time.PostForAllStaff()));

                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
            }

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task PostInTheBackGroundWhenPostingForAllStaff(bool postForAllStaff)
            {
                var f = new TimePostingControllerFixture(Db);
                f.FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanPost, Arg.Any<User>()).Returns(true);
                f.ValidatePostDates.For(Arg.Any<DateTime>()).ReturnsForAnyArgs((isValid: true, isWarningOnly: false, code: string.Empty));
                var listOfPostableDates = new List<PostableDate>
                {
                    new(Fixture.Monday, 3, 3, Fixture.String(), Fixture.Integer()),
                    new(Fixture.Tuesday, 4, 4, Fixture.String(), Fixture.Integer())
                };
                var request = new Inprotech.Web.Accounting.Time.PostForAllStaff()
                {
                    EntityKey = Fixture.Integer(),
                    SelectedDates = postForAllStaff ? null : listOfPostableDates
                };
                var result = await f.Subject.PostForAllStaff(request);

                await f.Bus.Received(1).PublishAsync(Arg.Is<PostTimeArgs>(_ => _.UserIdentityId == f.CurrentUser.Id &&
                                                                                    _.EntityKey == request.EntityKey &&
                                                                                    _.SelectedStaffDates == request.SelectedDates &&
                                                                                    _.PostForAllStaff == postForAllStaff));
                Assert.Equal(result.Result, "success");
                Assert.Equal(result.IsBackground, true);
            }
        }
    }

    public class TimePostingControllerFixture : IFixture<TimePostingController>
    {
        public TimePostingControllerFixture(InMemoryDbContext db)
        {
            Entities = Substitute.For<IEntities>();

            SecurityContext = Substitute.For<ISecurityContext>();
            CurrentUser = new UserBuilder(db).Build();
            SecurityContext.User.Returns(CurrentUser);

            SiteControlReader = Substitute.For<ISiteControlReader>();
            PostTimeCommand = Substitute.For<IPostTimeCommand>();
            DiaryDatesReader = Substitute.For<IDiaryDatesReader>();
            FunctionSecurity = Substitute.For<IFunctionSecurityProvider>();
            FunctionSecurity.FunctionSecurityFor(BusinessFunction.TimeRecording, FunctionSecurityPrivilege.CanPost, Arg.Any<User>(), Arg.Any<int?>()).Returns(true);
            TimeSearchService = Substitute.For<ITimeSearchService>();
            ValidatePostDates = Substitute.For<IValidatePostDates>();
            ValidatePostDates.For(Arg.Any<DateTime>()).ReturnsForAnyArgs((isValid: true, isWarningOnly: false, code: string.Empty));
            Bus = Substitute.For<IBus>();
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            Subject = new TimePostingController(Entities, SecurityContext, SiteControlReader, PostTimeCommand, DiaryDatesReader, Fixture.Today, FunctionSecurity, TimeSearchService, ValidatePostDates, Bus, PreferredCultureResolver);
        }

        public TimePostingControllerFixture WithViewData(IEnumerable<EntityName> names, bool automaticWipEntity, bool entityFromCaseOffice)
        {
            Entities.Get(Arg.Any<int>()).Returns(names);

            SiteControlReader.Read<bool>(Arg.Is<string>(_ => _ == SiteControls.AutomaticWIPEntity)).Returns(automaticWipEntity);
            SiteControlReader
                .ReadMany<bool>(Arg.Is<string[]>(_ => _.Contains(SiteControls.EntityDefaultsFromCaseOffice) && _.Contains(SiteControls.RowSecurityUsesCaseOffice)))
                .Returns(new Dictionary<string, bool>
                {
                    {SiteControls.EntityDefaultsFromCaseOffice, entityFromCaseOffice},
                    {SiteControls.RowSecurityUsesCaseOffice, entityFromCaseOffice}
                });

            return this;
        }

        public TimePostingControllerFixture WithDatesData(IEnumerable<PostableDate> postableDates = null)
        {
            DiaryDatesReader.GetDiaryDatesFor(Arg.Any<int>(), Arg.Any<DateTime>()).Returns(postableDates);

            return this;
        }

        public TimePostingControllerFixture WithPostResult(PostTimeResult result)
        {
            PostTimeCommand.PostTime(Arg.Any<PostTimeArgs>())
                           .Returns(result);

            return this;
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public IBus Bus { get; set; }
        public IValidatePostDates ValidatePostDates { get; set; }
        public IEntities Entities { get; }
        public ISecurityContext SecurityContext { get; }
        public ISiteControlReader SiteControlReader { get; }
        public IPostTimeCommand PostTimeCommand { get; }
        public IDiaryDatesReader DiaryDatesReader { get; }
        public IFunctionSecurityProvider FunctionSecurity { get; }
        public ITimeSearchService TimeSearchService { get; set; }
        public User CurrentUser { get; set; }
        public TimePostingController Subject { get; }
    }
}