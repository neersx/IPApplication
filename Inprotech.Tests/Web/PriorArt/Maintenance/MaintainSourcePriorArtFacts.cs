using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.PriorArt.Maintenance;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt.Maintenance
{
    public class MaintainSourcePriorArtFacts : FactBase
    {
        [Fact]
        public async Task ShouldMaintain()
        {
            var fixture = new MaintainSourcePriorArtFixture(Db);
            var sourceDoc = new SourceDocumentSaveModel
            {
                SourceId = Fixture.Integer(),
                SourceType = new TableCodeBuilder().Build(),
                Classes = Fixture.String(),
                Comments = Fixture.String(),
                Description = Fixture.String(),
                IssuingJurisdiction = new KeyValuePair<string, string>(Fixture.String(), Fixture.String()),
                Publication = Fixture.String(),
                SubClasses = Fixture.String(),
                ReportIssued = Fixture.Date(),
                ReportReceived = Fixture.Date()
            };
            var priorArt = new InprotechKaizen.Model.PriorArt.PriorArt()
            {
                Id = sourceDoc.SourceId.Value
            }.In(Db);
            var result = await fixture.Subject.MaintainSource(sourceDoc, PriorArtTypes.Source);

            Assert.NotNull(result);
            Assert.Equal(sourceDoc.Classes, priorArt.Classes);
            Assert.Equal(sourceDoc.SubClasses, priorArt.SubClasses);
            Assert.Equal(sourceDoc.ReportIssued, priorArt.ReportIssued);
            Assert.Equal(sourceDoc.ReportReceived, priorArt.ReportReceived);
            Assert.Equal(sourceDoc.Publication, priorArt.Publication);

            await Db.Received().SaveChangesAsync();
        }

        [Fact]
        public async Task ShouldThrowExceptionIfSourceIsNull()
        {
            var fixture = new MaintainSourcePriorArtFixture(Db);

            await Assert.ThrowsAsync<ArgumentNullException>(async () => { await fixture.Subject.MaintainSource(new SourceDocumentSaveModel(), PriorArtTypes.Source); });
        }

        [Fact]
        public async Task ShouldDeletePriorArtCorrectly()
        {
            var fixture = new MaintainSourcePriorArtFixture(Db);
            var priorArt1 = new InprotechKaizen.Model.PriorArt.PriorArt
            {
                Id = Fixture.Integer()
            }.In(Db);
            var priorArt2 = new InprotechKaizen.Model.PriorArt.PriorArt
            {
                Id = Fixture.Integer()
            }.In(Db);
            var result = await fixture.Subject.DeletePriorArt(priorArt2.Id);

            Assert.True(result);
            Assert.True(Db.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Any(v => v.Id == priorArt1.Id));
            Assert.False(Db.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Any(v => v.Id == priorArt2.Id));
        }
    }

    public class MaintainSourcePriorArtFixture : IFixture<MaintainSourcePriorArt>
    {
        public MaintainSourcePriorArtFixture(IDbContext db)
        {
            Subject = new MaintainSourcePriorArt(db);
        }

        public MaintainSourcePriorArt Subject { get; }
    }
}