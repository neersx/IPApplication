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
    public class NameImageConsolidatorFacts : FactBase
    {
        public NameImageConsolidatorFacts()
        {
            _to = new Name().In(Db);
            _from = new Name().In(Db);
        }

        readonly Name _from;

        readonly Name _to;

        [Fact]
        public async Task ShouldConsolidateAllNameImages()
        {
            var imageA = new Image().In(Db);
            var imageB = new Image().In(Db);

            new NameImage {Id = _from.Id, ImageId = imageA.Id}.In(Db);
            new NameImage {Id = _from.Id, ImageId = imageB.Id}.In(Db);

            var subject = new NameImageConsolidator(Db);

            await subject.Consolidate(_to, _from, new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean()));

            Assert.Empty(Db.Set<NameImage>().Where(_ => _.Id == _from.Id));
            Assert.Equal(2, Db.Set<NameImage>().Count(_ => _.Id == _to.Id));
        }

        [Fact]
        public async Task ShouldNotConsolidateNameImagesAlreadyExisted()
        {
            var imageA = new Image().In(Db);
            var imageB = new Image().In(Db);

            new NameImage {Id = _from.Id, ImageId = imageA.Id}.In(Db);
            new NameImage {Id = _from.Id, ImageId = imageB.Id}.In(Db);

            new NameImage {Id = _to.Id, ImageId = imageA.Id}.In(Db);

            var subject = new NameImageConsolidator(Db);

            await subject.Consolidate(_to, _from, new ConsolidationOption(Fixture.Boolean(), Fixture.Boolean(), Fixture.Boolean()));

            Assert.Single(Db.Set<NameImage>().Where(_ => _.Id == _to.Id && _.ImageId == imageA.Id));
            Assert.Single(Db.Set<NameImage>().Where(_ => _.Id == _to.Id && _.ImageId == imageB.Id));
            // the remaining images in will be deleted in later consolidators.
            Assert.Single(Db.Set<NameImage>().Where(_ => _.Id == _from.Id && _.ImageId == imageA.Id));
            Assert.Empty(Db.Set<NameImage>().Where(_ => _.Id == _from.Id && _.ImageId == imageB.Id));
        }
    }
}