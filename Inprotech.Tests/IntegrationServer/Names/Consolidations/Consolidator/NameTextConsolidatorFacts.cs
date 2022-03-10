using System.Linq;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.Names.Consolidations;
using Inprotech.IntegrationServer.Names.Consolidations.Consolidators;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.Names.Consolidations.Consolidator
{
    public class NameTextConsolidatorFacts : FactBase
    {
        public NameTextConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        readonly Name _from;

        readonly Name _to;

        [Fact]
        public async Task ShouldCopyNameText()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());
            var subject = new NameTextConsolidator(Db);

            var textType = Fixture.String();

            new NameText {Id = _from.Id, TextType = textType}.In(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<NameText>().Where(_ => _.Id == _to.Id && _.TextType == textType));
            Assert.Empty(Db.Set<NameText>().Where(_ => _.Id == _from.Id && _.TextType == textType));
        }

        [Fact]
        public async Task ShouldNotCopyNameTextIfIdenticalExists()
        {
            var option = new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean());
            var subject = new NameTextConsolidator(Db);

            var textType = Fixture.String();

            new NameText {Id = _from.Id, TextType = textType}.In(Db);
            new NameText {Id = _to.Id, TextType = textType}.In(Db);

            await subject.Consolidate(_to, _from, option);

            Assert.Single(Db.Set<NameText>().Where(_ => _.Id == _to.Id && _.TextType == textType));
            // removal of this happens in later consolidators.
            Assert.Single(Db.Set<NameText>().Where(_ => _.Id == _from.Id && _.TextType == textType));
        }
    }
}