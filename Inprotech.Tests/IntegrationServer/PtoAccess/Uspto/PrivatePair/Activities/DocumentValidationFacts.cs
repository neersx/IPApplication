using System;
using System.Threading.Tasks;
using Castle.Components.DictionaryAdapter;
using Inprotech.Contracts;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities
{
    public class DocumentValidationFacts : FactBase
    {
        [Fact]
        public async Task OnlyChecksPdfFiles()
        {
            var f = new DocumentValidationFixture(Db);
            var r = await f.Subject.MarkIfAlreadyProcessed(new ApplicationDownload(), new LinkInfo() { LinkType = LinkTypes.Biblio });
            Assert.False(r);
            f.BiblioStorage.DidNotReceiveWithAnyArgs().Read(Arg.Any<ApplicationDownload>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task CheckIfFileDoesNotExistsInDb()
        {
            var f = new DocumentValidationFixture(Db).WithBiblio(Fixture.String());
            var r = await f.Subject.MarkIfAlreadyProcessed(new ApplicationDownload(), new LinkInfo() { LinkType = LinkTypes.Pdf });
            Assert.False(r);
            f.BiblioStorage.Received(1).Read(Arg.Any<ApplicationDownload>()).IgnoreAwaitForNSubstituteAssertion();
            f.FileNameExtractor.Received(1).AbsoluteUriName(Arg.Any<string>());
            f.ScheduleRuntimeEvents.DidNotReceiveWithAnyArgs().DocumentProcessed(Arg.Any<Guid>(), Arg.Any<Document>());
        }

        [Fact]
        public async Task CheckIfFileAlreadyProcessed()
        {
            var doc = new Document()
            {
                MailRoomDate = Fixture.Today(),
                Source = DataSourceType.UsptoPrivatePair,
                ApplicationNumber = Fixture.String(),
                DocumentObjectId = Fixture.String(),
                Status = DocumentDownloadStatus.Downloaded,
                FileStore = new FileStore()
            }.In(Db);

            var f = new DocumentValidationFixture(Db)
                    .WithBiblio(doc.DocumentObjectId)
                    .WithFile();
            var r = await f.Subject.MarkIfAlreadyProcessed(new ApplicationDownload()
            {
                Number = doc.ApplicationNumber
            }, new LinkInfo() { LinkType = LinkTypes.Pdf });
            Assert.True(r);
            f.BiblioStorage.Received(1).Read(Arg.Any<ApplicationDownload>()).IgnoreAwaitForNSubstituteAssertion();
            f.FileNameExtractor.Received(1).AbsoluteUriName(Arg.Any<string>());
            f.ScheduleRuntimeEvents.Received(1).DocumentProcessed(Arg.Any<Guid>(), Arg.Any<Document>());
        }

        [Fact]
        public async Task NotProcessedIfMailRoomDateIsDifferent()
        {
            var doc = new Document()
            {
                MailRoomDate = Fixture.FutureDate(),
                Source = DataSourceType.UsptoPrivatePair,
                ApplicationNumber = Fixture.String(),
                DocumentObjectId = Fixture.String(),
                Status = DocumentDownloadStatus.Downloaded,
                FileStore = new FileStore()
            }.In(Db);

            var f = new DocumentValidationFixture(Db)
                    .WithBiblio(doc.DocumentObjectId)
                    .WithFile();
            var r = await f.Subject.MarkIfAlreadyProcessed(new ApplicationDownload()
            {
                Number = doc.ApplicationNumber
            }, new LinkInfo() { LinkType = LinkTypes.Pdf });
            Assert.False(r);
            f.BiblioStorage.Received(1).Read(Arg.Any<ApplicationDownload>()).IgnoreAwaitForNSubstituteAssertion();
            f.FileNameExtractor.Received(1).AbsoluteUriName(Arg.Any<string>());
            f.ScheduleRuntimeEvents.DidNotReceiveWithAnyArgs().DocumentProcessed(Arg.Any<Guid>(), Arg.Any<Document>());
        }

        [Fact]
        public async Task NotProcessedIfApplicationNumberIsDifferent()
        {
            var doc = new Document()
            {
                MailRoomDate = Fixture.Today(),
                Source = DataSourceType.UsptoPrivatePair,
                ApplicationNumber = Fixture.String(),
                DocumentObjectId = Fixture.String(),
                Status = DocumentDownloadStatus.Downloaded,
                FileStore = new FileStore()
            }.In(Db);

            var f = new DocumentValidationFixture(Db)
                    .WithBiblio(doc.DocumentObjectId)
                    .WithFile();
            var r = await f.Subject.MarkIfAlreadyProcessed(new ApplicationDownload()
            {
                Number = Fixture.String("abc")
            }, new LinkInfo() { LinkType = LinkTypes.Pdf });
            Assert.False(r);
            f.BiblioStorage.Received(1).Read(Arg.Any<ApplicationDownload>()).IgnoreAwaitForNSubstituteAssertion();
            f.FileNameExtractor.Received(1).AbsoluteUriName(Arg.Any<string>());
            f.ScheduleRuntimeEvents.DidNotReceiveWithAnyArgs().DocumentProcessed(Arg.Any<Guid>(), Arg.Any<Document>());
        }

        [Fact]
        public async Task NotProcessedIfFileDoesNotExists()
        {
            var doc = new Document()
            {
                MailRoomDate = Fixture.Today(),
                Source = DataSourceType.UsptoPrivatePair,
                ApplicationNumber = Fixture.String(),
                DocumentObjectId = Fixture.String(),
                Status = DocumentDownloadStatus.Downloaded,
                FileStore = new FileStore()
            }.In(Db);

            var f = new DocumentValidationFixture(Db)
                    .WithBiblio(doc.DocumentObjectId)
                    .WithFile(false);
            var r = await f.Subject.MarkIfAlreadyProcessed(new ApplicationDownload()
            {
                Number = doc.ApplicationNumber
            }, new LinkInfo() { LinkType = LinkTypes.Pdf });
            Assert.False(r);
            f.BiblioStorage.Received(1).Read(Arg.Any<ApplicationDownload>()).IgnoreAwaitForNSubstituteAssertion();
            f.FileNameExtractor.Received(1).AbsoluteUriName(Arg.Any<string>());
            f.ScheduleRuntimeEvents.DidNotReceiveWithAnyArgs().DocumentProcessed(Arg.Any<Guid>(), Arg.Any<Document>());
        }

        class DocumentValidationFixture : IFixture<DocumentValidation>
        {
            public DocumentValidationFixture(InMemoryDbContext db)
            {
                Db = db;
                BiblioStorage = Substitute.For<IBiblioStorage>();
                FileNameExtractor = Substitute.For<IFileNameExtractor>();
                FileSystem = Substitute.For<IFileSystem>();
                ScheduleRuntimeEvents = Substitute.For<IScheduleRuntimeEvents>();
                Subject = new DocumentValidation(Db, BiblioStorage, FileNameExtractor, FileSystem, ScheduleRuntimeEvents);
            }

            public DocumentValidation Subject { get; }
            InMemoryDbContext Db { get; }
            public IBiblioStorage BiblioStorage { get; }
            public IFileNameExtractor FileNameExtractor { get; }
            IFileSystem FileSystem { get; }
            public IScheduleRuntimeEvents ScheduleRuntimeEvents { get; }

            public DocumentValidationFixture WithBiblio(string docName)
            {
                BiblioStorage.Read(Arg.Any<ApplicationDownload>()).Returns(new BiblioFile()
                {
                    ImageFileWrappers = new EditableList<ImageFileWrapper>()
                    {
                        new ImageFileWrapper() {FileName = docName, MailDate = Fixture.Today().ToString("yyyy-MM-dd")}
                    }
                });
                FileNameExtractor.AbsoluteUriName(Arg.Any<string>()).Returns(docName);

                return this;
            }

            public DocumentValidationFixture WithFile(bool exists = true)
            {
                FileSystem.Exists(Arg.Any<string>()).Returns(exists);
                return this;
            }
        }
    }
}