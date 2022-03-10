using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Integration.DmsIntegration;
using Inprotech.IntegrationServer.PtoAccess.DmsIntegration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.DmsIntegration
{
    public class WriteDocumentsToDestinationFacts
    {
        public WriteDocumentsToDestinationFacts()
        {
            _fixture = new WriteDocumentsToDestinationFixture();
        }

        readonly WriteDocumentsToDestinationFixture _fixture;
        const string DestinationPath = @"\destination\file\path";
        const string DestinationDocumentFilePath = DestinationPath + @"\document.pdf";
        const string DestinationMetadataFilePath = DestinationPath + @"\document.xml";

        const string DocumentContent = "documentcontent";
        const string MetadataContent = "metadatacontent";

        [Fact]
        public async Task ShouldCleanUpFilesIfThereIsAnError()
        {
            var documentContentData = Encoding.UTF8.GetBytes(DocumentContent);
            var metadataContentData = Encoding.UTF8.GetBytes(MetadataContent);

            _fixture.FileHelpers.ChangeExtension(DestinationDocumentFilePath, ".xml")
                    .Returns(DestinationMetadataFilePath);

            _fixture.FileHelpers.GetDirectoryName(DestinationDocumentFilePath).Returns(DestinationPath);
            _fixture.FileHelpers.DirectoryExists(DestinationPath).Returns(true);

            _fixture.FileHelpers.Exists(DestinationDocumentFilePath).Returns(false, true);
            _fixture.FileHelpers.Exists(DestinationMetadataFilePath).Returns(true);

            using (var documentStream = new MemoryStream(documentContentData))
            using (var metadataStream = new MemoryStream(metadataContentData))
            using (var documentOutputStream = new MemoryStream())
            {
                _fixture.FileHelpers.OpenWrite(DestinationDocumentFilePath).Returns(documentOutputStream);
                _fixture.FileHelpers.OpenWrite(DestinationMetadataFilePath)
                        .Returns(x => throw new Exception("some file exception"));

                var ex = await Assert.ThrowsAsync<Exception>(
                                                             () => _fixture.Subject.Write(documentStream, metadataStream, DestinationDocumentFilePath));

                Assert.Equal("some file exception", ex.Message);

                _fixture.FileHelpers.Received(1).DeleteFile(DestinationDocumentFilePath);
                _fixture.FileHelpers.Received(1).DeleteFile(DestinationMetadataFilePath);
            }
        }

        [Fact]
        public async Task ShouldCreateDirectoryIfDirectoryDoesntExist()
        {
            var documentContentData = Encoding.UTF8.GetBytes(DocumentContent);
            var metadataContentData = Encoding.UTF8.GetBytes(MetadataContent);

            _fixture.FileHelpers.ChangeExtension(DestinationDocumentFilePath, ".xml")
                    .Returns(DestinationMetadataFilePath);

            _fixture.FileHelpers.DirectoryExists(DestinationPath).Returns(false);
            _fixture.FileHelpers.GetDirectoryName(DestinationDocumentFilePath).Returns(DestinationPath);

            using (var documentStream = new MemoryStream(documentContentData))
            using (var metadataStream = new MemoryStream(metadataContentData))
            using (var documentOutputStream = new MemoryStream())
            using (var metadataOutputStream = new MemoryStream())
            {
                _fixture.FileHelpers.OpenWrite(DestinationDocumentFilePath).Returns(documentOutputStream);
                _fixture.FileHelpers.OpenWrite(DestinationMetadataFilePath).Returns(metadataOutputStream);

                await _fixture.Subject.Write(documentStream, metadataStream, DestinationDocumentFilePath);

                _fixture.FileHelpers.Received(1).CreateDirectory(DestinationPath);
            }
        }

        [Fact]
        public async Task ShouldNotCreateDirectoryIfDirectoryNameIsRoot()
        {
            var documentContentData = Encoding.UTF8.GetBytes(DocumentContent);
            var metadataContentData = Encoding.UTF8.GetBytes(MetadataContent);

            const string destinationDocumentPath = @"C:\document.pdf";
            const string destinationMetadataPath = @"C:\document.xml";
            const string destinationPath = @"C:\";

            _fixture.FileHelpers.ChangeExtension(destinationDocumentPath, ".xml")
                    .Returns(destinationMetadataPath);

            _fixture.FileHelpers.DirectoryExists(destinationPath).Returns(false);
            _fixture.FileHelpers.GetDirectoryName(destinationDocumentPath).Returns((string) null);

            using (var documentStream = new MemoryStream(documentContentData))
            using (var metadataStream = new MemoryStream(metadataContentData))
            using (var documentOutputStream = new MemoryStream())
            using (var metadataOutputStream = new MemoryStream())
            {
                _fixture.FileHelpers.OpenWrite(destinationDocumentPath).Returns(documentOutputStream);
                _fixture.FileHelpers.OpenWrite(destinationMetadataPath).Returns(metadataOutputStream);

                await _fixture.Subject.Write(documentStream, metadataStream, destinationDocumentPath);

                _fixture.FileHelpers.DidNotReceive().CreateDirectory(destinationPath);
            }
        }

        [Fact]
        public async Task ShouldThrowFileAlreadyExistsExceptionIfDestinationFileExists()
        {
            var documentContentData = Encoding.UTF8.GetBytes(DocumentContent);
            var metadataContentData = Encoding.UTF8.GetBytes(MetadataContent);

            _fixture.FileHelpers.ChangeExtension(DestinationDocumentFilePath, ".xml")
                    .Returns(DestinationMetadataFilePath);

            _fixture.FileHelpers.GetDirectoryName(DestinationDocumentFilePath).Returns(DestinationPath);
            _fixture.FileHelpers.DirectoryExists(DestinationPath).Returns(true);

            _fixture.FileHelpers.Exists(DestinationDocumentFilePath).Returns(true);
            _fixture.FileHelpers.Exists(DestinationMetadataFilePath).Returns(true);

            using (var documentStream = new MemoryStream(documentContentData))
            using (var metadataStream = new MemoryStream(metadataContentData))
            {
                var ex = await Assert.ThrowsAsync<FileAlreadyExistsException>(
                                                                              () => _fixture.Subject.Write(documentStream, metadataStream, DestinationDocumentFilePath));

                Assert.Equal(DestinationDocumentFilePath, ex.Filepath);
            }
        }

        [Fact]
        public async Task ShouldWriteBothStreamsToDestination()
        {
            var documentContentData = Encoding.UTF8.GetBytes(DocumentContent);
            var metadataContentData = Encoding.UTF8.GetBytes(MetadataContent);

            _fixture.FileHelpers.ChangeExtension(DestinationDocumentFilePath, ".xml")
                    .Returns(DestinationMetadataFilePath);

            _fixture.FileHelpers.GetDirectoryName(DestinationDocumentFilePath).Returns(DestinationPath);
            _fixture.FileHelpers.DirectoryExists(DestinationPath).Returns(true);

            using (var documentStream = new MemoryStream(documentContentData))
            using (var metadataStream = new MemoryStream(metadataContentData))
            using (var documentOutputStream = new MemoryStream())
            using (var metadataOutputStream = new MemoryStream())
            {
                _fixture.FileHelpers.OpenWrite(DestinationDocumentFilePath).Returns(documentOutputStream);
                _fixture.FileHelpers.OpenWrite(DestinationMetadataFilePath).Returns(metadataOutputStream);

                await _fixture.Subject.Write(documentStream, metadataStream, DestinationDocumentFilePath);

                Assert.Equal(DocumentContent, Encoding.UTF8.GetString(documentOutputStream.ToArray()));
                Assert.Equal(MetadataContent, Encoding.UTF8.GetString(metadataOutputStream.ToArray()));
            }
        }
    }

    internal class WriteDocumentsToDestinationFixture : IFixture<WriteDocumentsToDestination>
    {
        public IFileHelpers FileHelpers = Substitute.For<IFileHelpers>();

        public WriteDocumentsToDestination Subject => new WriteDocumentsToDestination(FileHelpers);
    }
}