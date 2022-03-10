using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class AssociatedNameConsolidatorFacts : FactBase
    {
        public AssociatedNameConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
            _other = new Name().In(Db);
        }
        
        readonly Name _to;
        readonly Name _from;
        readonly Name _other;

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ShouldConsolidateAssociatedName(bool keep)
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keep);

            new AssociatedName(_from, _other, Fixture.String(), 1).In(Db);

            var subject = new AssociatedNameConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<AssociatedName>().Where(_ => _.Id == _from.Id));

            Assert.Single(Db.Set<AssociatedName>().Where(_ => _.Id == _to.Id));
        }

        [Theory]
        [InlineData(true)]
        [InlineData(false)]
        public async Task ShouldConsolidateAssociatedNameAndRetainName(bool keep)
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), keep);

            new AssociatedName(_other, _from, Fixture.String(), 1).In(Db);

            var subject = new AssociatedNameConsolidator(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Empty(Db.Set<AssociatedName>().Where(_ => _.RelatedNameId == _from.Id));

            Assert.Single(Db.Set<AssociatedName>().Where(_ => _.RelatedNameId == _to.Id));
        }
    }
}