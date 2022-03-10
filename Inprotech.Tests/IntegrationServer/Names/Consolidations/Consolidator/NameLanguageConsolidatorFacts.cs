using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class NameLanguageConsolidatorFacts : FactBase
    {
        public NameLanguageConsolidatorFacts()
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

            new NameLanguage {NameId = _from.Id}.In(Db);

            var subject = new NameLanguageConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<NameLanguage>());
        }

        [Fact]
        public async Task ShouldKeepNameLanguageIfIndicated()
        {
            const bool keepConsolidatedName = true;
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);

            new NameLanguage {NameId = _from.Id}.In(Db);

            var subject = new NameLanguageConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<NameLanguage>());
        }
    }
}