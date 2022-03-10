using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class ClientDetailsConsolidatorFacts : FactBase
    {
        readonly Name _from;

        readonly Name _to;

        public ClientDetailsConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        [Fact]
        public async Task ShouldNotConsolidateIfNameWasNotClient()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            _to.UsedAs = NameUsedAs.StaffMember | NameUsedAs.Individual;
            _from.UsedAs = NameUsedAs.Individual;

            _from.ClientDetail = null;

            var subject = new ClientDetailsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<ClientDetail>().Where(_ => _.Id == _to.Id));
            Assert.Empty(Db.Set<ClientDetail>().Where(_ => _.Id == _from.Id));
            Assert.NotEqual(NameUsedAs.Client, _to.UsedAs & NameUsedAs.Client);
        }

        [Theory]
        [InlineData(NameUsedAs.Individual)]
        [InlineData(NameUsedAs.Organisation)]
        public async Task ShouldConsolidateIpName(short usedAs)
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var fromClientDetail = new ClientDetail(_from.Id, _from)
            {
                AirportCode = Fixture.String(),
                CreditLimit = Fixture.Decimal()
            }.In(Db);

            _to.UsedAs = usedAs;
            _from.UsedAs = NameUsedAs.Client;

            var subject = new ClientDetailsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<ClientDetail>().Where(_ => _.Id == _to.Id));
            Assert.Empty(Db.Set<ClientDetail>().Where(_ => _.Id == _from.Id));
            Assert.Equal(fromClientDetail.AirportCode, Db.Set<ClientDetail>().Single(_ => _.Id == _to.Id).AirportCode);
            Assert.Equal(fromClientDetail.CreditLimit, Db.Set<ClientDetail>().Single(_ => _.Id == _to.Id).CreditLimit);
            Assert.Equal(NameUsedAs.Client, _to.UsedAs & NameUsedAs.Client);
        }

        [Theory]
        [InlineData(NameUsedAs.Individual)]
        [InlineData(NameUsedAs.Organisation)]
        public async Task ShouldNotConsolidateIpNameDetailsIfNameIsAlreadyAnIpNameAndRetain(short usedAs)
        {
            const bool keepConsolidatedName = true;

            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);

            var currentClientDetail = new ClientDetail(_to.Id, _to)
            {
                AirportCode = Fixture.String(),
                CreditLimit = Fixture.Decimal()
            }.In(Db);

            var fromClientDetail = new ClientDetail(_from.Id, _from)
            {
                AirportCode = Fixture.String(),
                CreditLimit = Fixture.Decimal()
            }.In(Db);

            _to.UsedAs = usedAs;
            _from.UsedAs = NameUsedAs.Client;

            var subject = new ClientDetailsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<ClientDetail>().Where(_ => _.Id == _to.Id));
            Assert.Single(Db.Set<ClientDetail>().Where(_ => _.Id == _from.Id));
            Assert.Equal(currentClientDetail.AirportCode, Db.Set<ClientDetail>().Single(_ => _.Id == _to.Id).AirportCode);
            Assert.Equal(currentClientDetail.CreditLimit, Db.Set<ClientDetail>().Single(_ => _.Id == _to.Id).CreditLimit);
            Assert.Equal(NameUsedAs.Client, _to.UsedAs & NameUsedAs.Client);
        }

        [Theory]
        [InlineData(NameUsedAs.Individual)]
        [InlineData(NameUsedAs.Organisation)]
        public async Task ShouldNotConsolidateIpNameDetailsIfNameIsAlreadyAnIpNameAndDelete(short usedAs)
        {
            const bool keepConsolidatedName = false;

            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);

            var currentClientDetail = new ClientDetail(_to.Id, _to)
            {
                AirportCode = Fixture.String(),
                CreditLimit = Fixture.Decimal()
            }.In(Db);

            new ClientDetail(_from.Id, _from)
            {
                AirportCode = Fixture.String(),
                CreditLimit = Fixture.Decimal()
            }.In(Db);

            _to.UsedAs = usedAs;
            _from.UsedAs = NameUsedAs.Client;

            var subject = new ClientDetailsConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<ClientDetail>().Where(_ => _.Id == _to.Id));
            Assert.Empty(Db.Set<ClientDetail>().Where(_ => _.Id == _from.Id));
            Assert.Equal(currentClientDetail.AirportCode, Db.Set<ClientDetail>().Single(_ => _.Id == _to.Id).AirportCode);
            Assert.Equal(currentClientDetail.CreditLimit, Db.Set<ClientDetail>().Single(_ => _.Id == _to.Id).CreditLimit);
            Assert.Equal(NameUsedAs.Client, _to.UsedAs & NameUsedAs.Client);
        }
    }
}