using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search.Case;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;
using CaseListItem = InprotechKaizen.Model.Components.Cases.Search.CaseListItem;

namespace Inprotech.Tests.Web.Picklists
{
    public class TimesheetCasesPicklistControllerFacts
    {
        [Fact]
        public async Task ThrowsExceptionIfFunctionSecurityNotProvided()
        {
            var f = new TimesheetCasesPicklistControllerFixture();
            f.FunctionSecurityProvider.FunctionSecurityFor(Arg.Any<BusinessFunction>(), Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<int>()).ReturnsForAnyArgs(false);

            await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.CasesWithInstructor());
        }

        [Fact]
        public async Task CallsToGetCases()
        {
            var f = new TimesheetCasesPicklistControllerFixture();
            f.FunctionSecurityProvider.FunctionSecurityFor(Arg.Any<BusinessFunction>(), Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<int>()).ReturnsForAnyArgs(true);
            var qParams = new CommonQueryParameters {SortBy = Fixture.String(), SortDir = Fixture.String(), Skip = Fixture.Integer(), Take = Fixture.Integer()};
            var searchString = Fixture.String();

            await f.Subject.CasesWithInstructor(qParams, searchString);
            f.ListCase.Received(1).Get(out _, searchString, qParams.SortBy, qParams.SortDir, qParams.Skip, qParams.Take, null, true);
            f.RecentCasesProvider.DidNotReceive().ForTimesheet(Arg.Any<int>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ReturnsCorrectPayloadWhenNoRecentCasesRequired(bool withMatches)
        {
            var f = new TimesheetCasesPicklistControllerFixture();
            var rowCount = withMatches ? 1 : 0;
            f.FunctionSecurityProvider.FunctionSecurityFor(Arg.Any<BusinessFunction>(), Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<int>()).ReturnsForAnyArgs(true);
            f.ListCase.Get(out _, Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<int?>(), true, Arg.Any<CaseSearchFilter>())
             .Returns(x =>
             {
                 x[0] = rowCount;
                 return withMatches ? new List<CaseListItem>
                 {
                     new()
                     {
                         CaseRef = Fixture.RandomString(20),
                         Id = Fixture.Integer()
                     }
                 } 
                     : new List<CaseListItem>();
             });
            
            var qParams = new CommonQueryParameters {SortBy = Fixture.String(), SortDir = Fixture.String(), Skip = Fixture.Integer(), Take = Fixture.Integer()};
            var searchString = Fixture.String();

            var result = await f.Subject.CasesWithInstructor(qParams, searchString);
            f.ListCase.Received(1).Get(out _, searchString, qParams.SortBy, qParams.SortDir, qParams.Skip, qParams.Take, null, true);
            f.RecentCasesProvider.DidNotReceive().ForTimesheet(Arg.Any<int>()).IgnoreAwaitForNSubstituteAssertion();
            Assert.Equal(rowCount, result.Pagination.Total);
        }
        
        [Fact]
        public async Task CallsRecentCasesIfRecentCasesNeedtoBeIncluded()
        {
            var recentCase = new RecentCase {CaseKey = 100, CaseReference = "Abcd", InstructorNameKey = 10, InstructorName = "A", LastUsed = Fixture.Today(), Title = "Some interesting case of Abcd"};
            var f = new TimesheetCasesPicklistControllerFixture();
            f.FunctionSecurityProvider.FunctionSecurityFor(Arg.Any<BusinessFunction>(), Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<int>()).ReturnsForAnyArgs(true);
            f.RecentCasesProvider.ForTimesheet(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>())
             .ReturnsForAnyArgs(new[] {recentCase});

            var qParams = new CommonQueryParameters {SortBy = Fixture.String(), SortDir = Fixture.String(), Skip = Fixture.Integer(), Take = Fixture.Integer()};

            var result = await f.Subject.CasesWithInstructor(qParams, includeRecent: true);
            Assert.True(result.ResultsContainsRecent);
            Assert.NotEmpty(result.RecentResults.Data);
            var data = ((IEnumerable<Case>) result.RecentResults.Data).First();
            Assert.Equal(recentCase.CaseKey, data.Key);
            Assert.Equal(recentCase.CaseReference, data.Code);
            Assert.Equal(recentCase.Title, data.Value);
            Assert.Equal(recentCase.InstructorName, data.InstructorName);
            Assert.Equal(recentCase.InstructorNameKey, data.InstructorNameId);
            f.ListCase.DidNotReceiveWithAnyArgs().Get(out _, Arg.Any<string>(), qParams.SortBy, qParams.SortDir, qParams.Skip, qParams.Take, null, true);
        }

        [Fact]
        public async Task AugmentsRecentCasesWithCasesWhenSearchTextSupplied()
        {
            var recentCase = new RecentCase {CaseKey = 100, CaseReference = "Abcd", InstructorNameKey = 10, InstructorName = "A", LastUsed = Fixture.Today(), Title = "Some interesting case of Abcd"};
            var searchString = Fixture.String();
            var f = new TimesheetCasesPicklistControllerFixture();
            f.FunctionSecurityProvider.FunctionSecurityFor(Arg.Any<BusinessFunction>(), Arg.Any<FunctionSecurityPrivilege>(), Arg.Any<User>(), Arg.Any<int>()).ReturnsForAnyArgs(true);
            f.RecentCasesProvider.ForTimesheet(Arg.Any<int>(), Arg.Any<DateTime>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>())
             .ReturnsForAnyArgs(new[] {recentCase});

            var qParams = new CommonQueryParameters {SortBy = Fixture.String(), SortDir = Fixture.String(), Skip = Fixture.Integer(), Take = Fixture.Integer()};

            var result = await f.Subject.CasesWithInstructor(qParams, searchString, includeRecent: true);
            Assert.True(result.ResultsContainsRecent);
            Assert.NotEmpty(result.RecentResults.Data);
            var data = ((IEnumerable<Case>) result.RecentResults.Data).First();
            Assert.Equal(recentCase.CaseKey, data.Key);
            Assert.Equal(recentCase.CaseReference, data.Code);
            Assert.Equal(recentCase.Title, data.Value);
            Assert.Equal(recentCase.InstructorName, data.InstructorName);
            Assert.Equal(recentCase.InstructorNameKey, data.InstructorNameId);
            f.ListCase.Received(1).Get(out _, searchString, qParams.SortBy, qParams.SortDir, qParams.Skip, qParams.Take, null, true);
        }
    }

    public class TimesheetCasesPicklistControllerFixture : IFixture<TimesheetCasesPicklistController>
    {
        public TimesheetCasesPicklistControllerFixture()
        {
            ListCase = Substitute.For<IListCase>();
            RecentCasesProvider = Substitute.For<IRecentCasesProvider>();
            SecurityContext = Substitute.For<ISecurityContext>();
            FunctionSecurityProvider = Substitute.For<IFunctionSecurityProvider>();

            SecurityContext.User.Returns(new User {NameId = 10});

            Subject = new TimesheetCasesPicklistController(ListCase, RecentCasesProvider, SecurityContext, FunctionSecurityProvider);
        }

        public IListCase ListCase { get; }

        public IRecentCasesProvider RecentCasesProvider { get; }

        public ISecurityContext SecurityContext { get; }

        public IFunctionSecurityProvider FunctionSecurityProvider { get; }

        public TimesheetCasesPicklistController Subject { get; }
    }
}