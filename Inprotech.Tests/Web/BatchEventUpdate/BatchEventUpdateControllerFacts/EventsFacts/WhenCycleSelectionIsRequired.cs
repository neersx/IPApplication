using System.Net;
using System.Threading.Tasks;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    EventsFacts
{
    public class WhenCycleSelectionIsRequired : FactBase
    {
        [Fact]
        public async Task ItShouldThrowAnHttpResponseExceptionWithAmbiguousStatusCode()
        {
            var fixture = new EventsFixture(Db);
            fixture.CycleSelection.IsRequired(null, null).ReturnsForAnyArgs(true);
            await fixture.Run();

            Assert.Equal(HttpStatusCode.Ambiguous, fixture.Exception.Response.StatusCode);
        }
    }
}