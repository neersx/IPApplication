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
    public class IndividualConsolidatorFacts : FactBase
    {
        public IndividualConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        readonly Name _from;

        readonly Name _to;

        [Fact]
        public async Task ShouldConsolidateIndividual()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var fromIndividual = new Individual(_from.Id)
            {
                Gender = Fixture.String(),
                FormalSalutation = Fixture.String(),
                CasualSalutation = Fixture.String()
            }.In(Db);

            _to.UsedAs = (short) NameUsedAs.Individual;
            _from.UsedAs = (short) NameUsedAs.Individual;

            var subject = new IndividualConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<Individual>().Where(_ => _.NameId == _to.Id));
            Assert.Equal(fromIndividual.Gender, Db.Set<Individual>().Single(_ => _.NameId == _to.Id).Gender);
            Assert.Equal(fromIndividual.FormalSalutation, Db.Set<Individual>().Single(_ => _.NameId == _to.Id).FormalSalutation);
            Assert.Equal(fromIndividual.CasualSalutation, Db.Set<Individual>().Single(_ => _.NameId == _to.Id).CasualSalutation);
        }

        [Fact]
        public async Task ShouldNotConsolidateIndividualDetailsIfNameIsAlreadyAnIndividualAndDelete()
        {
            const bool keepConsolidatedName = false;

            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);

            var currentIndividual = new Individual(_to.Id)
            {
                Gender = Fixture.String(),
                FormalSalutation = Fixture.String(),
                CasualSalutation = Fixture.String()
            }.In(Db);

            new Individual(_from.Id)
            {
                Gender = Fixture.String(),
                FormalSalutation = Fixture.String(),
                CasualSalutation = Fixture.String()
            }.In(Db);

            _to.UsedAs = (short) NameUsedAs.Individual;
            _from.UsedAs = (short) NameUsedAs.Individual;

            var subject = new IndividualConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<Individual>().Where(_ => _.NameId == _to.Id));
            Assert.Empty(Db.Set<Individual>().Where(_ => _.NameId == _from.Id));
            Assert.Equal(currentIndividual.Gender, Db.Set<Individual>().Single(_ => _.NameId == _to.Id).Gender);
            Assert.Equal(currentIndividual.FormalSalutation, Db.Set<Individual>().Single(_ => _.NameId == _to.Id).FormalSalutation);
            Assert.Equal(currentIndividual.CasualSalutation, Db.Set<Individual>().Single(_ => _.NameId == _to.Id).CasualSalutation);
        }

        [Fact]
        public async Task ShouldNotConsolidateIndividualDetailsIfNameIsAlreadyAnIndividualAndRetain()
        {
            const bool keepConsolidatedName = true;

            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);

            var currentIndividual = new Individual(_to.Id)
            {
                Gender = Fixture.String(),
                FormalSalutation = Fixture.String(),
                CasualSalutation = Fixture.String()
            }.In(Db);

            new Individual(_from.Id)
            {
                Gender = Fixture.String(),
                FormalSalutation = Fixture.String(),
                CasualSalutation = Fixture.String()
            }.In(Db);

            _to.UsedAs = (short) NameUsedAs.Individual;
            _from.UsedAs = (short) NameUsedAs.Individual;

            var subject = new IndividualConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<Individual>().Where(_ => _.NameId == _to.Id));
            Assert.Single(Db.Set<Individual>().Where(_ => _.NameId == _from.Id));
            Assert.Equal(currentIndividual.Gender, Db.Set<Individual>().Single(_ => _.NameId == _to.Id).Gender);
            Assert.Equal(currentIndividual.FormalSalutation, Db.Set<Individual>().Single(_ => _.NameId == _to.Id).FormalSalutation);
            Assert.Equal(currentIndividual.CasualSalutation, Db.Set<Individual>().Single(_ => _.NameId == _to.Id).CasualSalutation);
        }

        [Fact]
        public async Task ShouldChangeAssociatedNameContact()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());

            var fromIndividual = new Individual(_from.Id).In(Db);
            
            var contact = new AssociatedName{ ContactId = fromIndividual.NameId }.In(Db);

            var subject = new IndividualConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Equal(_to.Id, contact.ContactId);
        }
    }
}