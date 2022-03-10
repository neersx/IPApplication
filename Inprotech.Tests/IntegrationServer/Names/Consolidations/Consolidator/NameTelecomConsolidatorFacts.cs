using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class NameTelecomConsolidatorFacts : FactBase
    {
        public NameTelecomConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        readonly Name _from;

        readonly Name _to;

        [Fact]
        public async Task ShouldCopyTelecomIfIndicated()
        {
            const bool keepTelecomHistory = true;

            var option = new ConsolidationOption(Fixture.Boolean(), keepTelecomHistory, Fixture.Boolean());
            var subject = new NameTelecomConsolidator(Db);

            var telecommunication = new Telecommunication().In(Db);
            new NameTelecom(_from, telecommunication).In(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<NameTelecom>().Where(_ => _.NameId == _to.Id && _.TeleCode == telecommunication.Id));
            Assert.Empty(Db.Set<NameTelecom>().Where(_ => _.NameId == _from.Id && _.TeleCode == telecommunication.Id));
        }

        [Fact]
        public async Task ShouldNotCopyTelecomIfIdenticalExists()
        {
            const bool keepTelecomHistory = true;

            var option = new ConsolidationOption(Fixture.Boolean(), keepTelecomHistory, Fixture.Boolean());
            var subject = new NameTelecomConsolidator(Db);

            var telecommunication = new Telecommunication().In(Db);

            new NameTelecom(_from, telecommunication).In(Db);
            new NameTelecom(_to, telecommunication).In(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<NameTelecom>().Where(_ => _.NameId == _to.Id && _.TeleCode == telecommunication.Id));
            // removal of this happens in later consolidators.
            Assert.Single(Db.Set<NameTelecom>().Where(_ => _.NameId == _from.Id && _.TeleCode == telecommunication.Id));
        }

        [Fact]
        public async Task ShouldNotCopyTelecomIfNotIndicated()
        {
            const bool keepTelecomHistory = false;

            var option = new ConsolidationOption(Fixture.Boolean(), keepTelecomHistory, Fixture.Boolean());
            var subject = new NameTelecomConsolidator(Db);

            var telecommunication = new Telecommunication().In(Db);
            new NameTelecom(_from, telecommunication).In(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<NameTelecom>().Where(_ => _.NameId == _to.Id && _.TeleCode == telecommunication.Id));
            Assert.Single(Db.Set<NameTelecom>().Where(_ => _.NameId == _from.Id && _.TeleCode == telecommunication.Id));
        }
    }
}