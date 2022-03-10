using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class NameAddressConsolidatorFacts : FactBase
    {
        public NameAddressConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        readonly Name _from;

        readonly Name _to;

        [Fact]
        public async Task ShouldCopyAddressEvenIfNotIndicatedWhenUsedSpecificallyInCase()
        {
            const bool keepAddressHistory = false;

            var option = new ConsolidationOption(keepAddressHistory, Fixture.Boolean(), Fixture.Boolean());
            var subject = new NameAddressConsolidator(Db);

            var address = new Address().In(Db);
            var addressType = new TableCode().In(Db);
            new NameAddress(_from, address, addressType).In(Db);
            new CaseName(new Case().In(Db), new NameType().In(Db), _from, 0, address: address).In(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<NameAddress>().Where(_ => _.NameId == _to.Id && _.AddressId == address.Id));
            Assert.Empty(Db.Set<NameAddress>().Where(_ => _.NameId == _from.Id && _.AddressId == address.Id));
        }

        [Fact]
        public async Task ShouldCopyAddressEvenIfNotIndicatedWhenUsedWithCpa()
        {
            const bool keepAddressHistory = false;

            var option = new ConsolidationOption(keepAddressHistory, Fixture.Boolean(), Fixture.Boolean());
            var subject = new NameAddressConsolidator(Db);

            var address = new Address().In(Db);
            var addressType = new TableCode().In(Db);
            new NameAddress(_from, address, addressType).In(Db);
            new NameAddressCpaClient(_from, address, addressType).In(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<NameAddress>().Where(_ => _.NameId == _to.Id && _.AddressId == address.Id));
            Assert.Empty(Db.Set<NameAddress>().Where(_ => _.NameId == _from.Id && _.AddressId == address.Id));
        }
        
        [Fact]
        public async Task ShouldCopyAddressIfIndicated()
        {
            const bool keepAddressHistory = true;

            var option = new ConsolidationOption(keepAddressHistory, Fixture.Boolean(), Fixture.Boolean());
            var subject = new NameAddressConsolidator(Db);

            var address = new Address().In(Db);
            var addressType = new TableCode().In(Db);
            new NameAddress(_from, address, addressType).In(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<NameAddress>().Where(_ => _.NameId == _to.Id && _.AddressId == address.Id));
            Assert.Empty(Db.Set<NameAddress>().Where(_ => _.NameId == _from.Id && _.AddressId == address.Id));
        }

        [Fact]
        public async Task ShouldNotCopyAddressIfIdenticalExists()
        {
            const bool keepAddressHistory = true;

            var option = new ConsolidationOption(keepAddressHistory, Fixture.Boolean(), Fixture.Boolean());
            var subject = new NameAddressConsolidator(Db);

            var address = new Address().In(Db);
            var addressType = new TableCode().In(Db);
            new NameAddress(_from, address, addressType).In(Db);
            new NameAddress(_to, address, addressType).In(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<NameAddress>().Where(_ => _.NameId == _to.Id && _.AddressId == address.Id));
            // removal of this happens in later consolidators.
            Assert.Single(Db.Set<NameAddress>().Where(_ => _.NameId == _from.Id && _.AddressId == address.Id));
        }

        [Fact]
        public async Task ShouldNotCopyAddressIfNotIndicated()
        {
            const bool keepAddressHistory = false;

            var option = new ConsolidationOption(keepAddressHistory, Fixture.Boolean(), Fixture.Boolean());
            var subject = new NameAddressConsolidator(Db);

            var address = new Address().In(Db);
            var addressType = new TableCode().In(Db);
            new NameAddress(_from, address, addressType).In(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<NameAddress>().Where(_ => _.NameId == _to.Id && _.AddressId == address.Id));
            Assert.Single(Db.Set<NameAddress>().Where(_ => _.NameId == _from.Id && _.AddressId == address.Id));
        }
    }
}