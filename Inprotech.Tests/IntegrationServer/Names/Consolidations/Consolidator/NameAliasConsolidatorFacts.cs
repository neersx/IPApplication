using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class NameAliasConsolidatorFacts : FactBase
    {
        readonly Name _from;

        readonly Name _to;

        public NameAliasConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        [Fact]
        public async Task ShouldConsolidateAllNameAliases()
        {
            new NameAlias {NameId = _from.Id, AliasType = new NameAliasType().In(Db), Alias = Fixture.String()}.In(Db);
            new NameAlias {NameId = _from.Id, AliasType = new NameAliasType().In(Db), Alias = Fixture.String(), Country = new Country().In(Db)}.In(Db);
            new NameAlias {NameId = _from.Id, AliasType = new NameAliasType().In(Db), Alias = Fixture.String(), Country = new Country().In(Db), PropertyType = new PropertyType().In(Db)}.In(Db);

            var subject = new NameAliasConsolidator(Db);

            await subject.Consolidate(_to, _from, new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean()));

            Assert.Empty(Db.Set<NameAlias>().Where(_ => _.NameId == _from.Id));
            Assert.Equal(3, Db.Set<NameAlias>().Count(_ => _.NameId == _to.Id));
        }

        [Fact]
        public async Task ShouldNotConsolidateNameAliasesAlreadyExisted()
        {
            var typeA = new NameAliasType().In(Db);
            var typeB = new NameAliasType().In(Db);
            var typeC = new NameAliasType().In(Db);

            var aliasA = Fixture.String();
            var aliasB = Fixture.String();
            var aliasC = Fixture.String();

            var countryA = new Country().In(Db);
            var countryB = new Country().In(Db);

            var propertyType = new PropertyType().In(Db);
            
            new NameAlias { NameId = _from.Id, AliasType = typeA, Alias = aliasA }.In(Db);
            new NameAlias { NameId = _from.Id, AliasType = typeB, Alias = aliasB, Country = countryA }.In(Db);
            new NameAlias { NameId = _from.Id, AliasType = typeC, Alias = aliasC, Country = countryB, PropertyType = propertyType }.In(Db);

            new NameAlias { NameId = _to.Id, AliasType = typeA, Alias = aliasA }.In(Db);
            new NameAlias { NameId = _to.Id, AliasType = typeB, Alias = aliasB, Country = countryA }.In(Db);
            new NameAlias { NameId = _to.Id, AliasType = typeC, Alias = aliasC, Country = countryB, PropertyType = propertyType }.In(Db);

            var subject = new NameAliasConsolidator(Db);

            await subject.Consolidate(_to, _from, new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean()));

            Assert.Equal(3, Db.Set<NameAlias>().Count(_ => _.NameId == _to.Id));
            // the name aliases will be deleted in later consolidators.
            Assert.Equal(3, Db.Set<NameAlias>().Count(_ => _.NameId == _from.Id));
        }
    }
}