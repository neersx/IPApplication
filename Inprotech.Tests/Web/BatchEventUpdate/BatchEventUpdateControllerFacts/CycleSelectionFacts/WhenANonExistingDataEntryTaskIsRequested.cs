using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Web.Properties;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    CycleSelectionFacts
{
    public class WhenANonExistingDataEntryTaskIsRequested : FactBase
    {
        [Fact]
        public async Task Http_status_code_is_set_to_not_found()
        {
            var fixture = new CycleSelectionFixture(Db);
            fixture.RequestModel.DataEntryTaskId = Fixture.Integer();

            await fixture.Run();

            Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) fixture.Exception).Response.StatusCode);

            Assert.Equal(Resources.ErrorDataEntryTaskDataEntryTaskNotFound, ((HttpResponseException) fixture.Exception).Response.ReasonPhrase);
        }
    }
}