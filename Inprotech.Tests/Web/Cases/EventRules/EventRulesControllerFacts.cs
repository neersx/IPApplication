using System.Net;
using System.Web.Http;
using Inprotech.Web.Cases.EventRules;
using NSubstitute;
using Xunit;
using static Inprotech.Web.Cases.EventRules.Models.EventRulesModel;

namespace Inprotech.Tests.Web.Cases.EventRules
{
    public class EventRulesControllerFacts : FactBase
    {
        [Fact]
        public void ShouldThrowExceptionWhenParameterIsNull()
        {
            var f = new EventRulesControllerFixture();
            var exception = Assert.Throws<HttpResponseException>(() => f.Subject.GetEventRulesDetails());

            Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
        }

        [Fact]
        public void ShouldReturnEventInformationWithParameter()
        {
            var q = new EventRulesRequest
            {
                EventNo = Fixture.Integer(),
                CaseId = Fixture.Integer()
            };

            var f = new EventRulesControllerFixture();
            f.Subject.GetEventRulesDetails(q);

            f.EventRulesService.Received(1).GetEventRulesDetails(Arg.Any<EventRulesRequest>());
        }
    }

    public class EventRulesControllerFixture : IFixture<EventRulesController>
    {
        public EventRulesControllerFixture()
        {
            EventRulesService = Substitute.For<IEventRulesService>();
            Subject = new EventRulesController(EventRulesService);
        }

        public IEventRulesService EventRulesService { get; set; }
        public EventRulesController Subject { get; }
    }
}
