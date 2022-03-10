using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Integration;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.CleanUp;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.CleanUp
{
    public class ScheduleExecutionSessionCleanerFacts : FactBase
    {
        [Fact]
        public async Task ShouldNotRemoveFileInFileStoreReferencedByCase()
        {
            var fixture = new ScheduleExecutionSessionCleanerFixture(Db).WithFile(@"customerNumber\1.pdf");

            var fs = new FileStore {Id = 1, Path = fixture.FilesInFolder[0].RelativeFilePath, OriginalFileName = "1.pdf"}.In(Db);

            new Case
            {
                Source = DataSourceType.UsptoPrivatePair,
                FileStore = fs,
                CreatedOn = Fixture.Today(),
                UpdatedOn = Fixture.Today()
            }.In(Db);

            await fixture.Subject.Clean(fixture.SessionGuid, fixture.RootSessionFolder);

            fixture.FileHelpers.DidNotReceive().DeleteFile(fixture.FilesInFolder[0].AbsoluteFilePath);
        }

        [Fact]
        public async Task ShouldNotRemoveFileInFileStoreReferencedByCaseFiles()
        {
            var fixture = new ScheduleExecutionSessionCleanerFixture(Db).WithFile(@"customerNumber\1.pdf");

            var fs = new FileStore {Id = 1, Path = fixture.FilesInFolder[0].RelativeFilePath, OriginalFileName = "1.pdf"}.In(Db);

            new Case
            {
                Id = 1,
                Source = DataSourceType.UsptoPrivatePair,
                FileStore = fs,
                CreatedOn = Fixture.Today(),
                UpdatedOn = Fixture.Today()
            }.In(Db);

            new CaseFiles
            {
                Id = 1,
                Type = 0,
                FileStore = fs,
                CaseId = 1
            }.In(Db);

            await fixture.Subject.Clean(fixture.SessionGuid, fixture.RootSessionFolder);

            fixture.FileHelpers.DidNotReceive().DeleteFile(fixture.FilesInFolder[0].AbsoluteFilePath);
        }

        [Fact]
        public async Task ShouldNotRemoveFileInFileStoreReferencedByDocument()
        {
            var fixture = new ScheduleExecutionSessionCleanerFixture(Db).WithFile(@"customerNumber\1.pdf");

            var fs = new FileStore {Id = 1, Path = fixture.FilesInFolder[0].RelativeFilePath, OriginalFileName = "1.pdf"}.In(Db);

            new Document
            {
                FileStore = fs,
                CreatedOn = Fixture.Today(),
                UpdatedOn = Fixture.Today(),
                DocumentObjectId = "documentObjectId"
            }.In(Db);

            await fixture.Subject.Clean(fixture.SessionGuid, fixture.RootSessionFolder);

            fixture.FileHelpers.DidNotReceive().DeleteFile(fixture.FilesInFolder[0].AbsoluteFilePath);
        }

        [Fact]
        public async Task ShouldRemoveFileInFileStoreNotReferencedByCaseOrDocument()
        {
            var fixture = new ScheduleExecutionSessionCleanerFixture(Db).WithFile(@"customerNumber\1.pdf");

            new FileStore {Id = 1, Path = fixture.FilesInFolder[0].RelativeFilePath, OriginalFileName = "1.pdf"}.In(Db);

            await fixture.Subject.Clean(fixture.SessionGuid, fixture.RootSessionFolder);

            fixture.FileHelpers.Received(1).DeleteFile(fixture.FilesInFolder[0].AbsoluteFilePath);
        }

        [Fact]
        public async Task ShouldRemoveFileNotInFileStore()
        {
            var fixture = new ScheduleExecutionSessionCleanerFixture(Db).WithFile(@"customernumber\1.pdf");

            await fixture.Subject.Clean(fixture.SessionGuid, fixture.RootSessionFolder);

            fixture.FileHelpers.Received(1).DeleteFile(fixture.FilesInFolder[0].AbsoluteFilePath);
        }

        [Fact]
        public async Task ShouldRemoveFileStoreRecordFileInFileStoreNotReferencedByCaseOrDocument()
        {
            var fixture = new ScheduleExecutionSessionCleanerFixture(Db).WithFile(@"customerNumber\1.pdf");

            new FileStore {Id = 1, Path = fixture.FilesInFolder[0].RelativeFilePath, OriginalFileName = "1.pdf"}.In(Db);

            await fixture.Subject.Clean(fixture.SessionGuid, fixture.RootSessionFolder);

            Assert.False(Db.Set<FileStore>().Any(f => f.Id == 1));
        }
    }

    internal class ScheduleExecutionSessionCleanerFixture : IFixture<ScheduleExecutionSessionCleaner>
    {
        readonly InMemoryDbContext _db;
        public IFileHelpers FileHelpers = Substitute.For<IFileHelpers>();

        public List<FileInFolder> FilesInFolder = new List<FileInFolder>();
        public IFileSystem FileSystem = Substitute.For<IFileSystem>();
        public IPublishFileCleanUpEvents Publisher = Substitute.For<IPublishFileCleanUpEvents>();
        public string RootSessionFolder;

        public Guid SessionGuid = new Guid("57ad3443-6b1a-4a8d-a5f5-9afcda3d99db");
        public string TempStorageFolder = @"c:\tempstorageroot";

        public ScheduleExecutionSessionCleanerFixture(InMemoryDbContext db)
        {
            _db = db;
            RootSessionFolder = @"UsptoIntegration\testschedule\" + SessionGuid;
        }

        public ScheduleExecutionSessionCleaner Subject => new ScheduleExecutionSessionCleaner(FileHelpers, FileSystem, _db, Publisher);

        public ScheduleExecutionSessionCleanerFixture WithFile(string filePath)
        {
            WithFile(SessionGuid, TempStorageFolder, RootSessionFolder, filePath);
            return this;
        }

        public ScheduleExecutionSessionCleanerFixture WithFile(Guid sessionGuid, string tempStorageFolder, string rootSessionFolder, string filePath)
        {
            SessionGuid = sessionGuid;
            TempStorageFolder = tempStorageFolder;
            RootSessionFolder = rootSessionFolder;

            var absoluteRootFolder = Path.Combine(tempStorageFolder, rootSessionFolder);
            var relativeFilePath = Path.Combine(rootSessionFolder, filePath);
            var absoluteFilePath = Path.Combine(tempStorageFolder, relativeFilePath);

            FilesInFolder.Add(new FileInFolder {AbsoluteFilePath = absoluteFilePath, RelativeFilePath = relativeFilePath});

            FileSystem.AbsolutePath(rootSessionFolder).Returns(absoluteRootFolder);
            FileHelpers.DirectoryExists(absoluteRootFolder).Returns(true);
            FileHelpers.GetFiles(absoluteRootFolder, "*.*", SearchOption.AllDirectories)
                       .Returns(FilesInFolder.Select(f => f.AbsoluteFilePath).ToArray());
            FileHelpers.Exists(absoluteFilePath).Returns(true);
            FileSystem.RelativeStorageLocationPath(absoluteFilePath).Returns(relativeFilePath);

            return this;
        }

        public class FileInFolder
        {
            public string RelativeFilePath { get; set; }
            public string AbsoluteFilePath { get; set; }
        }
    }
}