using System.IO;
using System.Threading.Tasks;
using CPAXML.Extensions;
using Inprotech.Contracts;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class ProcessApplicationDocumentsFacts
    {
        [Fact]
        public async Task UpdatesDocumentStatus()
        {
            var application = new ApplicationDownload() { ApplicationId = "1234" };
            var session = new Session();

            var f = new ProcessApplicationDocumentsFixture();
            var files = f.ApplicationFiles(application, out var biblio);
            await f.Subject.ProcessDownloadedDocuments(session, application);

            f.DocumentUpdate.Received().Apply(session, application, Arg.Is<AvailableDocument>(d => files[0].Contains(d.FileNameObjectId))).IgnoreAwaitForNSubstituteAssertion();
            f.DocumentUpdate.Received().Apply(session, application, Arg.Is<AvailableDocument>(d => files[1].Contains(d.FileNameObjectId))).IgnoreAwaitForNSubstituteAssertion();
            f.DocumentUpdate.DidNotReceive().Apply(session, application, Arg.Is<AvailableDocument>(d => biblio.Contains(d.FileNameObjectId))).IgnoreAwaitForNSubstituteAssertion();
        }

        class ProcessApplicationDocumentsFixture : IFixture<ProcessApplicationDocuments>
        {
            public ProcessApplicationDocumentsFixture()
            {
                var artifactsLocationResolver = Substitute.For<IArtifactsLocationResolver>();
                DocumentUpdate = Substitute.For<IDocumentUpdate>();
                _fileSystem = Substitute.For<IFileSystem>();
                _biblioStorage = Substitute.For<IBiblioStorage>();

                _fileSystem.OpenWrite(Arg.Any<string>()).Returns(new MemoryStream());

                Subject = new ProcessApplicationDocuments(artifactsLocationResolver, _fileSystem, DocumentUpdate, PrivatePairCommonMocks.FileNameExtractor, _biblioStorage);
            }

            public ProcessApplicationDocuments Subject { get; }
            readonly IFileSystem _fileSystem;
            public readonly IDocumentUpdate DocumentUpdate;
            readonly IBiblioStorage _biblioStorage;

            public string[] ApplicationFiles(ApplicationDownload application, out string biblioFile)
            {
                biblioFile = $"biblio_{application.ApplicationId}.json";
                var mailDate = Fixture.PastDate().Iso8601OrNull();
                var files = new[]
                {
                    "abc.pdf",
                    "def.pdf"
                };
                var biblio = new BiblioFile();
                biblio.ImageFileWrappers.Add(new ImageFileWrapper() { FileName = files[0], MailDate = mailDate, ObjectId = Fixture.String() });
                biblio.ImageFileWrappers.Add(new ImageFileWrapper() { FileName = files[1], MailDate = mailDate, ObjectId = Fixture.String() });

                _fileSystem.Files(Arg.Any<string>(), "*.pdf").Returns(files);
                _biblioStorage.Read(Arg.Any<ApplicationDownload>()).Returns(biblio);
                _biblioStorage.GetFileStoreBiblioInfo(Arg.Any<string>()).Returns((new FileStore(), Fixture.PastDate()));
                return files;
            }
        }
    }
}