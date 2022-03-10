using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using Inprotech.Web.PriorArt;
using Inprotech.Web.PriorArt.Maintenance;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt.Maintenance
{
    public class CreateSourcePriorArtFacts : FactBase
    {
        [Fact]
        public async Task ShouldThrowExceptionIfSourceIsNull()
        {
            var fixture = new CreateSourcePriorArtFixture(Db);

            Assert.ThrowsAsync<ArgumentNullException>(async () => { fixture.Subject.CreateSource(false, new SourceDocumentSaveModel(), null); });
        }

        [Fact]
        public async Task ShouldReturnTrueIfNoDuplicates()
        {
            var fixture = new CreateSourcePriorArtFixture(Db);
            var sourceDoc = new SourceDocumentSaveModel()
            {
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
            var result = await fixture.Subject.CreateSource(true, sourceDoc, null);

            Assert.NotNull(result);
            await Db.Received().SaveChangesAsync();
        }

        [Fact]
        public async Task ShouldAssociateIfHasCaseKey()
        {
            var fixture = new CreateSourcePriorArtFixture(Db);
            var sourceDoc = new SourceDocumentSaveModel()
            {
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
            var caseKey = Fixture.Integer();
            var result = await fixture.Subject.CreateSource(false, sourceDoc, caseKey);

            fixture.EvidenceImporter.Received(1).AssociatePriorArtWithCase(Arg.Any<InprotechKaizen.Model.PriorArt.PriorArt>(), caseKey);
            Assert.NotNull(result);
            await Db.Received().SaveChangesAsync();
        }
    }

    public class CreateSourcePriorArtFixture : IFixture<CreateSourcePriorArt>
    {
        public CreateSourcePriorArtFixture(IDbContext db)
        {
            EvidenceImporter = Substitute.For<IEvidenceImporter>();
            Subject = new CreateSourcePriorArt(db, EvidenceImporter);
        }

        public IEvidenceImporter EvidenceImporter { get; }

        public CreateSourcePriorArt Subject { get; }
    }
}