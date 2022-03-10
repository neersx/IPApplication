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
    public class NameFilesInConsolidatorFacts : FactBase
    {
        public NameFilesInConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        readonly Name _from;

        readonly Name _to;

        [Fact]
        public async Task ShouldConsolidateAllFilesIn()
        {
            new FilesIn {NameId = _from.Id, JurisdictionId = new Country().In(Db).Id}.In(Db);
            new FilesIn {NameId = _from.Id, JurisdictionId = new Country().In(Db).Id}.In(Db);

            var subject = new NameFilesInConsolidator(Db);

            await subject.Consolidate(_to, _from, new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean()));

            Assert.Empty(Db.Set<FilesIn>().Where(_ => _.NameId == _from.Id));
            Assert.Equal(2, Db.Set<FilesIn>().Count(_ => _.NameId == _to.Id));
        }

        [Fact]
        public async Task ShouldNotConsolidateFilesInAlreadyExisted()
        {
            var countryA = new Country().In(Db);
            var countryB = new Country().In(Db);

            new FilesIn {NameId = _from.Id, JurisdictionId = countryA.Id}.In(Db);
            new FilesIn {NameId = _from.Id, JurisdictionId = countryB.Id}.In(Db);

            new FilesIn {NameId = _to.Id, JurisdictionId = countryA.Id}.In(Db);

            var subject = new NameFilesInConsolidator(Db);

            await subject.Consolidate(_to, _from, new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean()));

            Assert.Single(Db.Set<FilesIn>().Where(_ => _.NameId == _to.Id && _.JurisdictionId == countryA.Id));
            Assert.Single(Db.Set<FilesIn>().Where(_ => _.NameId == _to.Id && _.JurisdictionId == countryB.Id));
            // the remaining files in will be deleted in later consolidators.
            Assert.Single(Db.Set<FilesIn>().Where(_ => _.NameId == _from.Id && _.JurisdictionId == countryA.Id));
            Assert.Empty(Db.Set<FilesIn>().Where(_ => _.NameId == _from.Id && _.JurisdictionId == countryB.Id));
        }
    }
}