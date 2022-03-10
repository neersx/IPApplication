using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.PriorArt;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.PriorArt;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt
{
    public class EvidenceImporterFacts
    {
        public class ImportMatch : FactBase
        {
            public ImportMatch()
            {
                var steConfiguration = Substitute.For<ISiteConfiguration>();
                var transactionRecordal = Substitute.For<ITransactionRecordal>();
                var componentResolver = Substitute.For<IComponentResolver>();
                _exstingCountry = new Country("au", "au").In(Db);
                _model = new ImportEvidenceModel
                {
                    Country = _exstingCountry.Id,
                    OfficialNumber = "on",
                    Source = "source"
                }.In(Db);

                _evidenceImporter = new EvidenceImporter(Db, steConfiguration, transactionRecordal, componentResolver);
            }

            readonly IEvidenceImporter _evidenceImporter;
            readonly Country _exstingCountry;
            readonly ImportEvidenceModel _model;

            [Fact]
            public void AssociatesNewPriorArtToValidCaseKey()
            {
                var @case = new CaseBuilder().Build().In(Db);
                _model.CaseKey = @case.Id;
                _evidenceImporter.ImportMatch(_model, new Match());

                var caseSearchResult =
                    Db.Set<CaseSearchResult>().SingleOrDefault(x => x.CaseId == @case.Id);
                Assert.NotNull(caseSearchResult);
                Assert.True(caseSearchResult.CaseId == @case.Id);
            }

            [Fact]
            public void CreatesPriorArtInDb()
            {
                _evidenceImporter.ImportMatch(_model, new Match());

                var pa = Db.Set<InprotechKaizen.Model.PriorArt.PriorArt>().Single();
                Assert.Equal(_exstingCountry, pa.Country);
                Assert.Equal(_model.OfficialNumber, pa.OfficialNumber);
                Assert.Equal(_model.Source, pa.ImportedFrom);
            }

            [Fact]
            public void LinksNewPriorArtToSourceDocument()
            {
                var sourceDocument = new InprotechKaizen.Model.PriorArt.PriorArt {IsSourceDocument = true}.In(Db);
                _model.SourceDocumentId = sourceDocument.Id;
                _evidenceImporter.ImportMatch(_model, new Match());
                Assert.True(sourceDocument.CitedPriorArt.Any());
            }
        }
    }
}