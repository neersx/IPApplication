using System;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.AssignmentRecordal;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Search;
using NSubstitute;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class AffectedCasesControllerFacts : FactBase
    {
        class AffectedCasesControllerFixture : IFixture<AffectedCasesController>
        {
            public AffectedCasesControllerFixture(InMemoryDbContext db)
            {
                AffectedCases = Substitute.For<IAffectedCases>();
                AffectedCasesMaintenance = Substitute.For<IAffectedCasesMaintenance>();
                SetAgent = Substitute.For<IAffectedCasesSetAgent>();
                Subject = new AffectedCasesController(db, AffectedCases, SetAgent, AffectedCasesMaintenance);
            }
            public AffectedCasesController Subject { get; }
            public IAffectedCases AffectedCases { get; }
            public IAffectedCasesSetAgent SetAgent { get; }
            public IAffectedCasesMaintenance AffectedCasesMaintenance { get; }
        }

        [Fact]
        public async Task GetAffectedCasesColumnsShouldThrowExceptionIfCaseNotFound()
        {
            var f = new AffectedCasesControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetAffectedCasesColumns(Fixture.Integer()));
            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public async Task GetAffectedCasesColumnsShouldReturnColumns()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var f = new AffectedCasesControllerFixture(Db);
            var cols = new List<SearchResult.Column>();
            f.AffectedCases.GetAffectedCasesColumns(@case.Id).Returns(cols);
            var result = await f.Subject.GetAffectedCasesColumns(@case.Id);
            Assert.Equal(result, cols);
        }

        [Fact]
        public async Task GetAffectedCasesShouldThrowExceptionIfCaseNotFound()
        {
            var f = new AffectedCasesControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetAffectedCases(Fixture.Integer()));
            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public async Task GetAffectedCasesShouldReturnData()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var f = new AffectedCasesControllerFixture(Db);
            var data = new SearchResult();
            f.AffectedCases.GetAffectedCases(@case.Id, Arg.Any<CommonQueryParameters>()).Returns(data);
            var result = await f.Subject.GetAffectedCases(@case.Id);
            Assert.Equal(data, result);
        }

        [Fact]
        public async Task SetAgentShouldThrowExceptionIfNoData()
        {
            var f = new AffectedCasesControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () => await f.Subject.SetAgentForAffectedCases(null));
            Assert.NotNull(exception);
        }

        [Fact]
        public async Task SetAgentShouldSaveAgentsForAffectedCases()
        {
            var f = new AffectedCasesControllerFixture(Db);
            var model = new AffectedCasesAgentModel();
            await f.Subject.SetAgentForAffectedCases(model);
            await f.SetAgent.Received(1).SetAgentForAffectedCases(model);
        }

        [Fact]
        public async Task DeleteAffectedCasesShouldThrowExceptionIfNoCase()
        {
            var f = new AffectedCasesControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.DeleteAffectedCases(0, null));
            Assert.NotNull(exception);
        }

        [Fact]
        public async Task CallDeleteAffectedCasesMethod()
        {
            var f = new AffectedCasesControllerFixture(Db);
            var @case = new CaseBuilder().Build().In(Db);
            f.AffectedCasesMaintenance.DeleteAffectedCases(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(new { Result = "success" });
            var r = await f.Subject.DeleteAffectedCases(@case.Id, null);

            Assert.NotNull(r);
            Assert.Equal("success", r.Result);
        }

        [Fact]
        public async Task ClearAgentsForAffectedCasesShouldThrowExceptionIfNoCase()
        {
            var f = new AffectedCasesControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.ClearAffectedCases(0, null));
            Assert.NotNull(exception);
        }

        [Fact]
        public async Task CallClearAgentsForAffectedCasesMethod()
        {
            var f = new AffectedCasesControllerFixture(Db);
            var @case = new CaseBuilder().Build().In(Db);
            f.SetAgent.ClearAgentForAffectedCases(Arg.Any<int>(), Arg.Any<DeleteAffectedCaseModel>()).Returns(new { Result = "success" });
            var r = await f.Subject.ClearAffectedCases(@case.Id, null);

            Assert.NotNull(r);
            Assert.Equal("success", r.Result);
        }

        [Fact]
        public async Task ShouldReturnNullIfCountryOrOfficialNoNotThere()
        {
            var f = new AffectedCasesControllerFixture(Db);
            var result = await f.Subject.AddAffectedCaseValidation(new ExternalAffectedCaseValidateModel());
            Assert.Null(result);

            result = await f.Subject.AddAffectedCaseValidation(new ExternalAffectedCaseValidateModel { Country = Fixture.String() });
            Assert.Null(result);
        }

        [Fact]
        public async Task AffectedCaseValidationShouldNotReturnNull()
        {
            var f = new AffectedCasesControllerFixture(Db);
            var data = new List<Inprotech.Web.Picklists.Case> { new Inprotech.Web.Picklists.Case { Key = 1, Code = "Fixture.String" } };

            f.AffectedCasesMaintenance.AddAffectedCaseValidation(Arg.Any<ExternalAffectedCaseValidateModel>()).Returns(data);
            var result = await f.Subject.AddAffectedCaseValidation(new ExternalAffectedCaseValidateModel { Country = Fixture.String(), OfficialNo = Fixture.String() });
            Assert.NotNull(result);
            Assert.Equal(1, result.Count());
            await f.AffectedCasesMaintenance.Received(1).AddAffectedCaseValidation(Arg.Any<ExternalAffectedCaseValidateModel>());
        }

        [Fact]
        public async Task AffectedCaseDataShouldSubmit()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var f = new AffectedCasesControllerFixture(Db);
            var data = new RecordalAffectedCaseRequest
            {
                CaseId = @case.Id,
                RelatedCases = null,
                Jurisdiction = Fixture.String(),
                OfficialNo = Fixture.String(),
                RecordalSteps = new List<RecordalStepAddModel> { new RecordalStepAddModel { RecordalTypeNo = Fixture.Integer(), RecordalStepSequence = Fixture.Integer() } }
            };

            var result = await f.Subject.SubmitRecordalAffectedCases(data);
            Assert.NotNull(result);
            await f.AffectedCasesMaintenance.Received(1).AddRecordalAffectedCases(data);
        }

        [Fact]
        public async Task AffectedCaseDataShouldReturnBadRequest()
        {
            var f = new AffectedCasesControllerFixture(Db);
            var result = await f.Subject.SubmitRecordalAffectedCases(null);
            Assert.NotNull(result);
            await f.AffectedCasesMaintenance.DidNotReceive().AddRecordalAffectedCases(null);
        }
    }
}
