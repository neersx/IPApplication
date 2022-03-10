using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.TempStorage;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BatchEventUpdate.BatchEventUpdateControllerFacts.
    MenuFacts
{
    public class WhenFirstCaseIsInaccessible : FactBase
    {
        protected Case ExistingCaseWithAccess { get; private set; }

        [Fact]
        public async Task ItShouldBuildMenuUsingFirstAccessibleCase()
        {
            var fixture = new MenuFixture(Db);

            var inaccessibleCase = new CaseBuilder().Build().In(Db);
            inaccessibleCase.OpenActions.Add(OpenActionBuilder.ForCaseAsValid(Db, inaccessibleCase).Build().In(Db));
            fixture.CaseAuthorization.Authorize(inaccessibleCase.Id, AccessPermissionLevel.Update).Returns(x =>
            {
                var caseId = (int) x[0];
                return new AuthorizationResult(caseId, true, true, "NotAccessible");
            });

            var listOfCases = new List<Case>();
            listOfCases.Add(inaccessibleCase);
            listOfCases.Add(fixture.ExistingCase);
            var tempId = new TempStorage(string.Join(",", listOfCases.Select(c => c.Id)));
            tempId.In(Db);
            fixture.TempStorageId = tempId.Id;

            await fixture.Run();

            Assert.True(
                        fixture.Result.Select(oam => oam.Id).SequenceEqual(fixture.ExistingCase.OpenActions.Select(oa => oa.ActionId)));
        }
    }
}