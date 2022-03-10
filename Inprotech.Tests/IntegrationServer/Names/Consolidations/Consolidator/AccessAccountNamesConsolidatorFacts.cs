using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class AccessAccountNamesConsolidatorFacts : FactBase
    {
        [Fact]
        public async Task ShouldConsolidateAccessAccountName()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var nameFrom = new Name().In(Db);
            var nameTo = new Name().In(Db);

            var accessAccount = new AccessAccount().In(Db);

            new AccessAccountName
            {
                AccessAccountId = accessAccount.Id,
                NameId = nameFrom.Id
            }.In(Db);

            new AccessAccountName
            {
                AccessAccountId = accessAccount.Id,
                NameId = nameTo.Id
            }.In(Db);

            var subject = new AccessAccountNamesConsolidator(Db);

            await subject.Consolidate(nameTo, nameFrom, option);

            Assert.Empty(Db.Set<AccessAccountName>().Where(_ => _.NameId == nameFrom.Id));
            Assert.Single(Db.Set<AccessAccountName>().Where(_ => _.AccessAccountId == accessAccount.Id));
        }
    }
}