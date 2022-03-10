using System.Threading.Tasks;
using Inprotech.Web.PriorArt.Maintenance;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt.Maintenance
{
    public class PriorArtMaintenanceControllerFacts : FactBase
    {
        public class PriorArtMaintenanceControllerFixture : IFixture<PriorArtMaintenanceController>
        {
            public PriorArtMaintenanceControllerFixture()
            {
                MaintainSourcePriorArt = Substitute.For<IMaintainSourcePriorArt>();
                CreateSourcePriorArt = Substitute.For<ICreateSourcePriorArt>();
                MaintainCitation = Substitute.For<IMaintainCitation>();
                Subject = new PriorArtMaintenanceController(CreateSourcePriorArt, MaintainSourcePriorArt, MaintainCitation);
            }

            public IMaintainSourcePriorArt MaintainSourcePriorArt { get; set; }
            public ICreateSourcePriorArt CreateSourcePriorArt { get; set; }
            public IMaintainCitation MaintainCitation { get; set; }
            public PriorArtMaintenanceController Subject { get; }
        }

        [Fact]
        public async Task SaveDataReturnsAppropriateResponseOnSuccess()
        {
            var fixture = new PriorArtMaintenanceControllerFixture();
            var model = new PriorArtSaveModel
            {
                CreateSource = new CreateSourceSaveModel
                {
                    SourceDocument = new SourceDocumentSaveModel()
                }
            };
            fixture.CreateSourcePriorArt.CreateSource(Arg.Any<bool>(), Arg.Any<SourceDocumentSaveModel>(), Arg.Any<int?>()).Returns(1);

            var response = await fixture.Subject.SaveData(model, PriorArtTypes.Source);

            Assert.Equal(true, response.SavedSuccessfully);
        }

        [Fact]
        public async Task ShouldReturnMatchingSourceDocumentExistsIsTrueIfFails()
        {
            var fixture = new PriorArtMaintenanceControllerFixture();
            var model = new PriorArtSaveModel
            {
                CreateSource = new CreateSourceSaveModel
                {
                    SourceDocument = new SourceDocumentSaveModel()
                }
            };
            fixture.CreateSourcePriorArt.CreateSource(Arg.Any<bool>(), Arg.Any<SourceDocumentSaveModel>(), Arg.Any<int?>()).Returns((int?)null);
            var caseKey = Fixture.Integer();

            var response = await fixture.Subject.SaveData(model, PriorArtTypes.Source, caseKey);

            Assert.Equal(false, response.SavedSuccessfully);
            Assert.Equal(true, response.MatchingSourceDocumentExists);
            await fixture.CreateSourcePriorArt.Received().CreateSource(false, model.CreateSource.SourceDocument, caseKey);
            await fixture.MaintainSourcePriorArt.DidNotReceive().MaintainSource(model.CreateSource.SourceDocument, PriorArtTypes.Source);
        }

        [Fact]
        public async Task ShouldMaintainIfSourceIdProvided()
        {
            var fixture = new PriorArtMaintenanceControllerFixture();
            var sourceId = Fixture.Integer();
            var model = new PriorArtSaveModel
            {
                CreateSource = new CreateSourceSaveModel
                {
                    SourceDocument = new SourceDocumentSaveModel()
                    {
                        SourceId = sourceId
                    }
                }
            };
            fixture.MaintainSourcePriorArt.MaintainSource(Arg.Any<SourceDocumentSaveModel>(), Arg.Any<int>()).Returns(sourceId);
            var caseKey = Fixture.Integer();

            var response = await fixture.Subject.SaveData(model, PriorArtTypes.Source, caseKey);

            Assert.Equal(true, response.SavedSuccessfully);
            Assert.Equal(false, response.MatchingSourceDocumentExists);
            Assert.Equal(sourceId, response.Id);
            await fixture.CreateSourcePriorArt.DidNotReceive().CreateSource(false, model.CreateSource.SourceDocument, caseKey);
            await fixture.MaintainSourcePriorArt.Received().MaintainSource(model.CreateSource.SourceDocument, PriorArtTypes.Source);
        }

        [Fact]
        public async Task ShouldCallDeleteCorrectly()
        {
            var fixture = new PriorArtMaintenanceControllerFixture();
            var priorArtId= Fixture.Integer();
            await fixture.Subject.DeletePriorArt(priorArtId);

            await fixture.MaintainSourcePriorArt.Received(1).DeletePriorArt(priorArtId);
        }
    }
}