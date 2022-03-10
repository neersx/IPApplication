using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Web.Properties;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    MenuFacts
{
    public class WhenACaseListIsPassedIsNull : FactBase
    {
        [Fact]
        public async Task It_should_return_an_error()
        {
            var fixture = new MenuFixture(Db) {TempStorageId = 1};

            await fixture.Run();

            Assert.Equal(HttpStatusCode.BadRequest, ((HttpResponseException) fixture.Exception).Response.StatusCode);
        }

        [Fact]
        public async Task Meaningful_message_is_returned_to_the_client()
        {
            var fixture = new MenuFixture(Db) {TempStorageId = 1};

            await fixture.Run();

            Assert.Equal(Resources.ValidationAtLeastOneCaseIdMustBeSpecified, ((HttpResponseException) fixture.Exception).Response.ReasonPhrase);
        }
    }
}