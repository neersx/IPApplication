using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Properties;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    MenuFacts
{
    public class WhenNoneOfTheCasesPassedInAreAccessible : FactBase
    {
        [Fact]
        public async Task It_should_return_an_error()
        {
            var fixture = new MenuFixture(Db);
            fixture.CaseAuthorization.Authorize(Arg.Any<int>(), AccessPermissionLevel.Update).Returns(x =>
            {
                var caseId = (int) x[0];
                return new AuthorizationResult(caseId, true, true, "NotAccessible");
            });

            await fixture.Run();

            Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) fixture.Exception).Response.StatusCode);
            Assert.Equal(Resources.ErrorCasesOneOrMoreSpecifiedCasesNotFoundOrNotUpdatable, ((HttpResponseException) fixture.Exception).Response.ReasonPhrase);
        }
    }
}