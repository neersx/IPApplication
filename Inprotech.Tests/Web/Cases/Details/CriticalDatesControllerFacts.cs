using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CriticalDatesControllerFacts : FactBase
    {
        readonly ICriticalDatesResolver _criticalDatesResolver = Substitute.For<ICriticalDatesResolver>();

        CriticalDatesController CreateSubject()
        {
            return new CriticalDatesController(Db, _criticalDatesResolver);
        }

        const string CaseViewCriticalDatesTopics = "CaseView.CriticalDates";

        [Fact]
        [Trait("Category", CaseViewCriticalDatesTopics)]
        public async Task ShouldReturnDetailsFromCriticalDatesComponent()
        {
            var @case = new CaseBuilder().Build().In(Db);

            new FilteredEthicalWallCaseBuilder().Build().In(Db).WithKnownId(x => x.CaseId, @case.Id);

            var dates = new[]
            {
                new CriticalDate(),
                new CriticalDate(),
                new CriticalDate()
            };

            _criticalDatesResolver.Resolve(@case.Id)
                                  .Returns(dates);

            var result = await CreateSubject().Get(@case.Id);

            Assert.Equal(dates, result);
        }

        [Fact]
        [Trait("Category", CaseViewCriticalDatesTopics)]
        public async Task ShouldThrowCaseRequestedNotFound()
        {
            var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                            async () => { await CreateSubject().Get(Fixture.Integer()); });

            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }
    }
}