using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.AssignmentRecordal;
using NSubstitute;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details.AssignmentRecordal
{
    public class RecordalMaintenanceControllerFacts : FactBase
    {
        class RecordalMaintenanceControllerFixture : IFixture<RecordalMaintenanceController>
        {
            public RecordalMaintenanceControllerFixture(InMemoryDbContext db)
            {
                RecordalMaintenance = Substitute.For<IRecordalMaintenance>();
                Subject = new RecordalMaintenanceController(db, RecordalMaintenance);
            }
            public RecordalMaintenanceController Subject { get; }
            public IRecordalMaintenance RecordalMaintenance { get; }
        }

        [Fact]
        public async Task GetRequestRecordalShouldThrowExceptionIfCaseNotFound()
        {
            var f = new RecordalMaintenanceControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetRequestRecordal(new RecordalRequest {CaseId = Fixture.Integer()}));
            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public async Task GetRequestRecordalShouldThrowExceptionIfModelNotFound()
        {
            var f = new RecordalMaintenanceControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetRequestRecordal(null));
            Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
        }

        [Fact]
        public async Task ShouldCallGetRequestRecordal()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var model = new RecordalRequest
            {
                CaseId = @case.Id
            };
            var f = new RecordalMaintenanceControllerFixture(Db);
            await f.Subject.GetRequestRecordal(model);
            await f.RecordalMaintenance.Received(1).GetAffectedCasesForRequestRecordal(model);
        }

        [Fact]
        public async Task SaveRequestRecordalShouldThrowExceptionIfCaseNotFound()
        {
            var f = new RecordalMaintenanceControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.SaveRequestRecordal(new SaveRecordalRequest {CaseId = Fixture.Integer()}));
            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public async Task SaveRequestRecordalShouldThrowExceptionIfModelNotFound()
        {
            var f = new RecordalMaintenanceControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.SaveRequestRecordal(null));
            Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
        }

        [Fact]
        public async Task ShouldCallSaveRequestRecordal()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var model = new SaveRecordalRequest
            {
                CaseId = @case.Id
            };
            var f = new RecordalMaintenanceControllerFixture(Db);
            await f.Subject.SaveRequestRecordal(model);
            await f.RecordalMaintenance.Received(1).SaveRequestRecordal(model);
        }
    }
}
