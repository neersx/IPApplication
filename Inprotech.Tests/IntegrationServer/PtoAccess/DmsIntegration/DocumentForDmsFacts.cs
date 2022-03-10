using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.DmsIntegration;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.DmsIntegration
{
    public class DocumentForDmsFacts
    {
        public class MoveDocumentWithItsMetadataMethod
        {
            const string Destination = "destinationlocation";
            const string Source = @"absolute\_document\file\path\_document.pdf";

            readonly byte[] _documentData = Encoding.UTF8.GetBytes("thedocumentcontent");
            readonly byte[] _metadataData = Encoding.UTF8.GetBytes("themetadadatacontent");

            readonly Document _document = new Document
            {
                FileStore = new FileStore
                {
                    Path = "relative document path"
                }
            };

            readonly int _caseId = Fixture.Integer();

            [Fact]
            public async Task ShouldDeleteSourceFileOnceWriteIsComplete()
            {
                using (var documentStream = new MemoryStream(_documentData))
                using (var metadataStream = new MemoryStream(_metadataData))
                {
                    var f = new DocumentForDmsFixture()
                            .GivenSourceDestination(Source, Destination)
                            .FileHelperReturns(documentStream)
                            .MetadataBuilderReturns(metadataStream, _document, _caseId);

                    f.DocWriter.Write(documentStream, metadataStream, Destination)
                     .Returns(Task.FromResult("success"));

                    await f.Subject.MoveDocumentWithItsMetadata(_document, _caseId);

                    f.FileHelpers.Received(1).DeleteFile(Source);
                }
            }

            [Fact]
            public async Task ShouldNotDeleteIfExceptionOccursHappens()
            {
                using (var documentStream = new MemoryStream(_documentData))
                using (var metadataStream = new MemoryStream(_metadataData))
                {
                    var f = new DocumentForDmsFixture()
                            .GivenSourceDestination(Source, Destination)
                            .FileHelperReturns(documentStream)
                            .MetadataBuilderReturns(metadataStream, _document, _caseId);

                    f.DocWriter
                     .When(x => x.Write(Arg.Any<MemoryStream>(), Arg.Any<MemoryStream>(), Destination))
                     .Do(x => throw new Exception("bummer!"));

                    await Assert.ThrowsAsync<Exception>(() =>
                                                            f.Subject.MoveDocumentWithItsMetadata(_document, _caseId)
                                                       );

                    f.FileHelpers.DidNotReceive().DeleteFile(Source);
                }
            }

            [Fact]
            public async Task ShouldWriteDocumentToDms()
            {
                using (var documentStream = new MemoryStream(_documentData))
                using (var metadataStream = new MemoryStream(_metadataData))
                {
                    var f = new DocumentForDmsFixture()
                            .GivenSourceDestination(Source, Destination)
                            .FileHelperReturns(documentStream)
                            .MetadataBuilderReturns(metadataStream, _document, _caseId);

                    f.DocWriter.Write(documentStream, metadataStream, Destination)
                     .Returns(Task.FromResult("success"));

                    await f.Subject.MoveDocumentWithItsMetadata(_document, _caseId);

                    f.DocWriter
                     .Received(1).Write(documentStream, metadataStream, Arg.Any<string>())
                     .IgnoreAwaitForNSubstituteAssertion();
                }
            }
        }

        public class DocumentForDmsFixture : IFixture<DocumentForDms>
        {
            public DocumentForDmsFixture()
            {
                DocWriter = Substitute.For<IWriteDocumentAndMetadataToDestination>();

                DmsLocationResolver = Substitute.For<IResolveDmsLocationForDataSourceType>();

                MetadataBuilder = Substitute.For<IBuildXmlMetadata>();

                FileHelpers = Substitute.For<IFileHelpers>();

                PtoDocLocationResolver = Substitute.For<IResolveStorageLocationForPtoAccessDocument>();

                DmsLocationResolver
                    .ResolveDestinationPath(Arg.Any<Document>())
                    .Returns("destinationlocation");

                PtoDocLocationResolver
                    .Resolve(Arg.Any<Document>())
                    .Returns(@"absolute\_document\file\path\_document.pdf");

                Subject = new DocumentForDms(
                                             DmsLocationResolver, DocWriter, MetadataBuilder, FileHelpers, PtoDocLocationResolver);
            }

            public IWriteDocumentAndMetadataToDestination DocWriter { get; set; }

            public IResolveDmsLocationForDataSourceType DmsLocationResolver { get; set; }

            public IBuildXmlMetadata MetadataBuilder { get; set; }

            public IFileHelpers FileHelpers { get; set; }

            public IResolveStorageLocationForPtoAccessDocument PtoDocLocationResolver { get; set; }

            public DocumentForDms Subject { get; set; }

            public DocumentForDmsFixture FileHelperReturns(MemoryStream stream,
                                                           string path = @"absolute\_document\file\path\_document.pdf")
            {
                FileHelpers.OpenRead(path).Returns(stream);
                return this;
            }

            public DocumentForDmsFixture MetadataBuilderReturns(MemoryStream stream, Document document, int caseId)
            {
                MetadataBuilder.Build(caseId, document).Returns(stream);
                return this;
            }

            public DocumentForDmsFixture GivenSourceDestination(string source, string destionation)
            {
                DmsLocationResolver.ResolveDestinationPath(Arg.Any<Document>()).Returns(destionation);
                PtoDocLocationResolver.Resolve(Arg.Any<Document>()).Returns(source);
                return this;
            }
        }
    }
}