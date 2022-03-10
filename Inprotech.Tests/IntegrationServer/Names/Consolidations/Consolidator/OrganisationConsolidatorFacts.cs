using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class OrganisationConsolidatorFacts : FactBase
    {
        [Fact]
        public async Task ShouldDeleteOrganisationIfIndicated()
        {
            const bool keepConsolidatedName = false;

            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);

            var nameFrom = new Name().In(Db);
            var nameTo = new Name().In(Db);

            new Organisation
            {
                Id = nameFrom.Id
            }.In(Db);

            var subject = new OrganisationConsolidator(Db);

            await subject.Consolidate(nameTo, nameFrom, option);

            Assert.Empty(Db.Set<Organisation>().Where(_ => _.Id == nameFrom.Id));
        }

        [Fact]
        public async Task ShouldKeepOrganisationIfIndicated()
        {
            const bool keepConsolidatedName = true;

            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keepConsolidatedName);

            var nameFrom = new Name().In(Db);
            var nameTo = new Name().In(Db);
            
            new Organisation
            {
                Id = nameFrom.Id
            }.In(Db);

            var subject = new OrganisationConsolidator(Db);

            await subject.Consolidate(nameTo, nameFrom, option);

            Assert.Single(Db.Set<Organisation>().Where(_ => _.Id == nameFrom.Id));
        }
    }
}