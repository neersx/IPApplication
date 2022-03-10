using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class NameMarginProfileConsolidatorFacts : FactBase
    {
        public NameMarginProfileConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        readonly Name _from;

        readonly Name _to;

        [Fact]
        public async Task ShouldDeleteOtherwise()
        {
            const bool keepConsolidatedName = false;
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);

            new NameMarginProfile {NameId = _from.Id}.In(Db);

            var subject = new NameMarginProfileConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<NameMarginProfile>());
        }

        [Fact]
        public async Task ShouldKeepNameMarginProfileIfIndicated()
        {
            const bool keepConsolidatedName = true;
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);

            new NameMarginProfile {NameId = _from.Id}.In(Db);

            var subject = new NameMarginProfileConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<NameMarginProfile>());
        }
    }
}