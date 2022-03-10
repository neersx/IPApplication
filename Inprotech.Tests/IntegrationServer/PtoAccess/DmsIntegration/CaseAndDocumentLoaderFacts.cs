using System;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.DmsIntegration;
using Inprotech.Tests.Fakes;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.DmsIntegration
{
    public class CaseAndDocumentLoaderFacts : FactBase
    {
        [Fact]
        public void ShouldGetAnyDocumentsAtSendToDms()
        {
            var f = new CaseAndDocumentLoaderFixture(Db);

            new Document
            {
                Source = DataSourceType.UsptoPrivatePair,
                ApplicationNumber = "number2",
                Status = DocumentDownloadStatus.SendToDms,
                DocumentObjectId = "doc1",
                Id = 100
            }.In(Db);
            new Document
            {
                Source = DataSourceType.UsptoTsdr,
                ApplicationNumber = "number1",
                Status = DocumentDownloadStatus.SendToDms,
                DocumentObjectId = "doc2",
                Id = 101
            }.In(Db);
            new Document
            {
                Source = DataSourceType.UsptoPrivatePair,
                ApplicationNumber = "number",
                Status = DocumentDownloadStatus.Downloaded,
                DocumentObjectId = "doc3",
                Id = 102
            }.In(Db);
            new Document
            {
                Source = DataSourceType.UsptoPrivatePair,
                ApplicationNumber = "number",
                Status = DocumentDownloadStatus.SentToDms,
                DocumentObjectId = "doc4",
                Id = 103
            }.In(Db);

            var results = f.Subject.GetAnyDocumentsAtSendToDms().ToArray();
            Assert.Equal(2, results.Length);
            Assert.Contains(results, d => d.Id == 100);
            Assert.Contains(results, d => d.Id == 101);
        }

        [Fact]
        public void ShouldGetCaseAndDocumentsForApplicationDownload()
        {
            var f = new CaseAndDocumentLoaderFixture(Db).WithDefaultCase().WithDefaultDocument();

            var appDownload = new ApplicationDownload
            {
                CustomerNumber = "customerNumber",
                Number = f.DefaultCase.ApplicationNumber
            };

            var result = f.Subject.GetCaseAndDocuments(appDownload);
            Assert.Equal(f.DefaultCase.CorrelationId, result.Case.CorrelationId);
            Assert.Equal(f.DefaultDocument.DocumentObjectId, result.Documents.Single().DocumentObjectId);
        }

        [Fact]
        public void ShouldGetCaseAndDocumentsForDataDownload()
        {
            var f = new CaseAndDocumentLoaderFixture(Db).WithDefaultCase(DataSourceType.UsptoTsdr).WithDefaultDocument(DataSourceType.UsptoTsdr);

            var dataDownload = new DataDownload
            {
                Case = new EligibleCase {CaseKey = f.DefaultCase.CorrelationId.Value}
            };

            var result = f.Subject.GetCaseAndDocuments(dataDownload);
            Assert.Equal(f.DefaultCase.CorrelationId, result.Case.CorrelationId);
            Assert.Equal(f.DefaultDocument.DocumentObjectId, result.Documents.Single().DocumentObjectId);
        }

        [Fact]
        public void ShouldGetCaseForMatchingDocument()
        {
            var f = new CaseAndDocumentLoaderFixture(Db).WithDefaultCase().WithDefaultDocument();

            var result = f.Subject.GetCaseFor(f.DefaultDocument);

            Assert.Equal(f.DefaultCase.CorrelationId, result.CorrelationId);
        }

        [Fact]
        public void ShouldThrowIfMoreThanOneCaseMatchesADocument()
        {
            var f = new CaseAndDocumentLoaderFixture(Db).WithDefaultCase().WithDefaultDocument();
            new Case
            {
                ApplicationNumber = f.DefaultCase.ApplicationNumber,
                CorrelationId = 2
            }.In(Db);

            Assert.Throws<InvalidOperationException>(() => f.Subject.GetCaseFor(f.DefaultDocument));
        }
    }

    internal class CaseAndDocumentLoaderFixture : IFixture<CaseAndDocumentLoader>
    {
        const int DefaultCorrelationId = 1;
        const string DefaultApplicationNumber = "number";
        const string DefaultDocumentObjectNumber = "doc1";
        const int DefaultDocumentId = 100;
        const int DefaultCaseId = 200;
        readonly InMemoryDbContext _db;

        public Case DefaultCase = new Case
        {
            CorrelationId = DefaultCorrelationId,
            ApplicationNumber = DefaultApplicationNumber,
            Id = DefaultCaseId,
            Source = DataSourceType.UsptoPrivatePair
        };

        public Document DefaultDocument = new Document
        {
            DocumentObjectId = DefaultDocumentObjectNumber,
            ApplicationNumber = DefaultApplicationNumber,
            Id = DefaultDocumentId,
            Source = DataSourceType.UsptoPrivatePair
        };

        public CaseAndDocumentLoaderFixture(InMemoryDbContext db)
        {
            _db = db;
        }

        public CaseAndDocumentLoader Subject => new CaseAndDocumentLoader(_db);

        public CaseAndDocumentLoaderFixture WithDefaultCase(DataSourceType source = DataSourceType.UsptoPrivatePair)
        {
            DefaultCase.Source = source;
            DefaultCase.In(_db);
            return this;
        }

        public CaseAndDocumentLoaderFixture WithDefaultDocument(DataSourceType source = DataSourceType.UsptoPrivatePair)
        {
            DefaultDocument.Source = source;
            DefaultDocument.In(_db);
            return this;
        }
    }
}