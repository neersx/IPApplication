using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Properties;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.TempStorage;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    CycleSelectionFacts
{
    public class WhenThereAreNoUpdatableCases : FactBase
    {
        [Fact]
        public async Task Http_status_code_is_set_to_not_found()
        {
            var fixture = new CycleSelectionFixture(Db);
            fixture.ExistingCase = new CaseBuilder().Build().In(Db);
            fixture.SetupAnOpenAction(fixture.ExistingCase);

            fixture.CaseAuthorization.Authorize(fixture.ExistingCase.Id, AccessPermissionLevel.Update).Returns(x =>
            {
                var caseId = (int) x[0];
                return new AuthorizationResult(caseId, true, true, "NotUpdatable");
            });

            var tempId = new TempStorage(string.Join(",", new List<Case> {fixture.ExistingCase}.Select(c => c.Id)));
            tempId.In(Db);
            fixture.RequestModel.TempStorageId = tempId.Id;

            await fixture.Run();

            Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) fixture.Exception).Response.StatusCode);

            Assert.Equal(
                         Resources.ErrorCasesOneOrMoreSpecifiedCasesNotFoundOrNotUpdatable,
                         ((HttpResponseException) fixture.Exception).Response.ReasonPhrase);
        }
    }
}