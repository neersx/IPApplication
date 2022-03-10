using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Results;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Cases.AssignmentRecordal;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.AssignmentRecordal;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details.AssignmentRecordal
{
    public class RecordalStepsControllerFacts : FactBase
    {
        class RecordalStepsControllerFixture : IFixture<RecordalStepsController>
        {
            public RecordalStepsControllerFixture(InMemoryDbContext db)
            {
                RecordalSteps = Substitute.For<IRecordalSteps>();
                RecordalStepsUpdater = Substitute.For<IRecordalStepsUpdater>();
                Subject = new RecordalStepsController(db, RecordalSteps, RecordalStepsUpdater);
            }

            public IRecordalSteps RecordalSteps { get; }
            public IRecordalStepsUpdater RecordalStepsUpdater { get; }
            public RecordalStepsController Subject { get; }
        }

        [Fact]
        public async Task GetRecordalStepElementsShouldReturnElementsData()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var rt = new RecordalType().In(Db);
            var rs = new RecordalStep { CaseId = @case.Id, RecordalType = rt, TypeId = rt.Id }.In(Db);
            var f = new RecordalStepsControllerFixture(Db);
            var data = new List<CaseRecordalStepElement> { new CaseRecordalStepElement() };
            f.RecordalSteps.GetRecordalStepElement(Arg.Any<int>(), Arg.Any<RecordalStep>()).Returns(data);
            var result = await f.Subject.GetRecordalStepElement(@case.Id, rs.Id, rt.Id);
            Assert.NotNull(result);
            Assert.Equal(data, result);
        }

        [Fact]
        public async Task GetRecordalStepElementsShouldThrowExceptionIfCaseNotFound()
        {
            var f = new RecordalStepsControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetRecordalStepElement(Fixture.Integer(), Fixture.Integer(), Fixture.Integer()));
            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public async Task GetRecordalStepsShouldReturnStepsData()
        {
            var @case = new CaseBuilder().Build().In(Db);
            var f = new RecordalStepsControllerFixture(Db);
            var data = new List<CaseRecordalStep> { new CaseRecordalStep() };
            f.RecordalSteps.GetRecordalSteps(Arg.Any<int>()).Returns(data);
            var result = await f.Subject.GetRecordalSteps(@case.Id);
            Assert.NotNull(result);
            Assert.Equal(data, result);
        }

        [Fact]
        public async Task GetRecordalStepsShouldThrowExceptionIfCaseNotFound()
        {
            var f = new RecordalStepsControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetRecordalSteps(Fixture.Integer()));
            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public async Task GetCurrentAddressShouldReturnNameAddresses()
        {
            var name = new NameBuilder(Db).Build().In(Db);
            var f = new RecordalStepsControllerFixture(Db);
            var data = new CurrentAddress();
            f.RecordalSteps.GetCurrentAddress(Arg.Any<int>()).Returns(data);
            var result = await f.Subject.GetCurrentAddress(name.Id);
            Assert.NotNull(result);
            Assert.Equal(data, result);
        }

        [Fact]
        public async Task GetCurrentAddressShouldThrowExceptionIfNameNotFound()
        {
            var f = new RecordalStepsControllerFixture(Db);
            var exception = await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.GetCurrentAddress(Fixture.Integer()));
            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }

        [Fact]
        public async Task ShouldValidateBeforeSave()
        {
            var f = new RecordalStepsControllerFixture(Db);
            var steps = new List<CaseRecordalStep> { new CaseRecordalStep() };
            var errors = new[] { new ValidationError(Fixture.String(), Fixture.String()), new ValidationError(Fixture.String(), Fixture.String()) };
            f.RecordalStepsUpdater.Validate(Arg.Any<IEnumerable<CaseRecordalStep>>()).Returns(errors);
            var result = await f.Subject.SubmitRecordalSteps(steps);
            Assert.Equal(result.Errors, errors);
        }

        [Fact]
        public async Task SubmitRecordalStepsShouldSave()
        {
            var f = new RecordalStepsControllerFixture(Db);
            var steps = new List<CaseRecordalStep> { new CaseRecordalStep() };
            f.RecordalStepsUpdater.Validate(Arg.Any<IEnumerable<CaseRecordalStep>>()).Returns(new List<ValidationError>());
            var result = await f.Subject.SubmitRecordalSteps(steps);
            await f.RecordalStepsUpdater.Received(1).SubmitRecordalStep(Arg.Any<CaseRecordalStep[]>());
        }
    }
}