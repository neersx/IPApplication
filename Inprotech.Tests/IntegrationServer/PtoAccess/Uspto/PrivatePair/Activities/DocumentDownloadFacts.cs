using System.IO;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class DocumentDownloadFacts
    {
        [Fact]
        public async Task ShouldNotDownloadAlreadyDownloadedDocuments()
        {
            var f = new DocumentDownloadFixture().WithFileExistsCheck(true);

            await f.Subject.DownloadIfRequired(new ApplicationDownload(), f.GetLink(), Fixture.String());

            f._service.DidNotReceiveWithAnyArgs().DownloadDocumentData(Arg.Any<string>(), Arg.Any<LinkInfo>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task DownloadIfNotAlreadyDownloaded()
        {
            var serviceId = Fixture.String();
            var f = new DocumentDownloadFixture().WithFileExistsCheck(false);
            var application = new ApplicationDownload() { CustomerNumber = string.Empty };
            var link = f.GetLink("newFile.pdf");
            var path = f.SetArtifactsFilePath(application, "newFile.pdf");

            await f.Subject.DownloadIfRequired(application, link, serviceId);

            f._service.Received(1).DownloadDocumentData(serviceId, link).IgnoreAwaitForNSubstituteAssertion();
            f._fileSystem.Received(1).OpenWrite(path);
        }

        class DocumentDownloadFixture : IFixture<DocumentDownload>
        {
            public DocumentDownloadFixture()
            {
                _artifactsLocationResolver = Substitute.For<IArtifactsLocationResolver>();
                _service = Substitute.For<IPrivatePairService>();
                _fileSystem = Substitute.For<IFileSystem>();
                DocumentValidation = Substitute.For<IDocumentValidation>();

                _fileSystem.OpenWrite(Arg.Any<string>()).Returns(new MemoryStream());
                Subject = new DocumentDownload(_artifactsLocationResolver, _service, _fileSystem, PrivatePairCommonMocks.FileNameExtractor, DocumentValidation);
            }

            public DocumentDownload Subject { get; }
            readonly IArtifactsLocationResolver _artifactsLocationResolver;
            public readonly IPrivatePairService _service;
            public readonly IFileSystem _fileSystem;
            public IDocumentValidation DocumentValidation { get; }

            public LinkInfo GetLink(string fileName = "file.pdf") => new LinkInfo() { Link = fileName };
            public LinkInfo GetFailedLink(string fileName = "file.pdf") => new LinkInfo() { Link = fileName, Status = "error", Message = "It never exisits!" };

            public DocumentDownloadFixture WithFileExistsCheck(bool exists)
            {
                _fileSystem.Exists(Arg.Any<string>()).Returns(exists);
                return this;
            }

            public string SetArtifactsFilePath(ApplicationDownload application, string documentName)
            {
                var path = $"Storage/{documentName}";
                _artifactsLocationResolver.ResolveFiles(application, documentName).Returns(path);
                return path;
            }
        }
    }
}