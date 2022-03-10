using System;
using System.IO;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.IntegrationServer.PtoAccess.CleanUp;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.CleanUp
{
    public class ScheduleExecutionSessionFolderCleanerFacts : FactBase
    {
        [Fact]
        public async Task ShouldDeleteEmptyPartOfTreeWithNonEmptyLeafFolder()
        {
            var fixture = new ScheduleExecutionSessionFolderCleanerFixture();
            var sessionRootPath = @"tempstorage\" + fixture.SessionGuid;
            var absolutePath = Path.Combine(@"c:\inprotech\", sessionRootPath);

            fixture.FileSystem.AbsolutePath(sessionRootPath).Returns(absolutePath);

            var emptyFolder1 = Path.Combine(absolutePath, "Empty Folder 1");
            var emptyFolder2 = Path.Combine(absolutePath, "Empty Folder 2");
            var nonEmptySubFolder1A = Path.Combine(emptyFolder1, "Non Empty Sub Folder 1a");

            fixture.FileHelpers.DirectoryExists(absolutePath).Returns(true);

            fixture.FileHelpers.EnumerateDirectories(absolutePath).Returns(new[] {emptyFolder1, emptyFolder2});
            fixture.FileHelpers.EnumerateDirectories(emptyFolder1).Returns(new[] {nonEmptySubFolder1A});
            fixture.FileHelpers.EnumerateDirectories(nonEmptySubFolder1A).Returns(new string[0]);
            fixture.FileHelpers.EnumerateDirectories(emptyFolder2).Returns(new string[0]);

            fixture.FileHelpers.EnumerateFileSystemEntries(absolutePath).Returns(new[] {emptyFolder1});
            fixture.FileHelpers.EnumerateFileSystemEntries(emptyFolder1).Returns(new[] {nonEmptySubFolder1A});
            fixture.FileHelpers.EnumerateFileSystemEntries(nonEmptySubFolder1A).Returns(new[] {Path.Combine(nonEmptySubFolder1A, "someFile.txt")});
            fixture.FileHelpers.EnumerateFileSystemEntries(emptyFolder2).Returns(new string[0]);

            await fixture.Subject.Clean(fixture.SessionGuid, sessionRootPath);

            fixture.FileSystem.Received(1).DeleteFolder(emptyFolder2);
        }

        [Fact]
        public async Task ShouldDeleteEmptySessionFolderTree()
        {
            var fixture = new ScheduleExecutionSessionFolderCleanerFixture();
            var sessionRootPath = @"tempstorage\" + fixture.SessionGuid;
            var absolutePath = Path.Combine(@"c:\inprotech\", sessionRootPath);

            fixture.FileSystem.AbsolutePath(sessionRootPath).Returns(absolutePath);

            var emptyFolder1 = Path.Combine(absolutePath, "Empty Folder 1");
            var emptyFolder2 = Path.Combine(absolutePath, "Empty Folder 2");
            var emptySubFolder1A = Path.Combine(emptyFolder1, "Empty Sub Folder 1a");

            fixture.FileHelpers.DirectoryExists(absolutePath).Returns(true);

            fixture.FileHelpers.EnumerateDirectories(absolutePath).Returns(new[] {emptyFolder1, emptyFolder2});
            fixture.FileHelpers.EnumerateDirectories(emptyFolder1).Returns(new[] {emptySubFolder1A});
            fixture.FileHelpers.EnumerateDirectories(emptySubFolder1A).Returns(new string[0]);
            fixture.FileHelpers.EnumerateDirectories(emptyFolder2).Returns(new string[0]);

            fixture.FileHelpers.EnumerateFileSystemEntries(absolutePath).Returns(new string[0]);
            fixture.FileHelpers.EnumerateFileSystemEntries(emptyFolder1).Returns(new string[0]);
            fixture.FileHelpers.EnumerateFileSystemEntries(emptySubFolder1A).Returns(new string[0]);
            fixture.FileHelpers.EnumerateFileSystemEntries(emptyFolder2).Returns(new string[0]);

            await fixture.Subject.Clean(fixture.SessionGuid, sessionRootPath);

            fixture.FileSystem.Received(1).DeleteFolder(absolutePath);
            fixture.FileSystem.Received(1).DeleteFolder(emptyFolder1);
            fixture.FileSystem.Received(1).DeleteFolder(emptyFolder2);
            fixture.FileSystem.Received(1).DeleteFolder(emptySubFolder1A);
        }

        [Fact]
        public async Task ShouldDeleteEmptySessionRootFolder()
        {
            var fixture = new ScheduleExecutionSessionFolderCleanerFixture();
            var sessionRootPath = @"tempstorage\" + fixture.SessionGuid;
            var absolutePath = Path.Combine(@"c:\inprotech\", sessionRootPath);

            fixture.FileSystem.AbsolutePath(sessionRootPath).Returns(absolutePath);

            fixture.FileHelpers.EnumerateDirectories(absolutePath).Returns(new string[0]);
            fixture.FileHelpers.EnumerateFileSystemEntries(absolutePath).Returns(new string[0]);
            fixture.FileHelpers.DirectoryExists(absolutePath).Returns(true);

            await fixture.Subject.Clean(fixture.SessionGuid, sessionRootPath);
            fixture.FileSystem.Received(1).DeleteFolder(absolutePath);
        }

        [Fact]
        public async Task ShouldNotDeleteNonEmptySessionRootFolder()
        {
            var fixture = new ScheduleExecutionSessionFolderCleanerFixture();
            var sessionRootPath = @"tempstorage\" + fixture.SessionGuid;
            var absolutePath = Path.Combine(@"c:\inprotech\", sessionRootPath);

            fixture.FileSystem.AbsolutePath(sessionRootPath).Returns(absolutePath);

            fixture.FileHelpers.EnumerateDirectories(absolutePath).Returns(new string[0]);
            fixture.FileHelpers.EnumerateFileSystemEntries(absolutePath).Returns(new[] {Path.Combine(sessionRootPath, "someFile.txt")});
            fixture.FileHelpers.DirectoryExists(absolutePath).Returns(true);

            await fixture.Subject.Clean(fixture.SessionGuid, sessionRootPath);
            fixture.FileSystem.DidNotReceive().DeleteFolder(absolutePath);
        }

        [Fact]
        public async Task ShouldNotDeleteTreeWithNonEmptyLeafFolder()
        {
            var fixture = new ScheduleExecutionSessionFolderCleanerFixture();
            var sessionRootPath = @"tempstorage\" + fixture.SessionGuid;
            var absolutePath = Path.Combine(@"c:\inprotech\", sessionRootPath);

            fixture.FileSystem.AbsolutePath(sessionRootPath).Returns(absolutePath);

            var emptyFolder1 = Path.Combine(absolutePath, "Empty Folder 1");
            var emptyFolder2 = Path.Combine(absolutePath, "Empty Folder 2");
            var nonEmptySubFolder1A = Path.Combine(emptyFolder1, "Non Empty Sub Folder 1a");

            fixture.FileHelpers.DirectoryExists(absolutePath).Returns(true);

            fixture.FileHelpers.EnumerateDirectories(absolutePath).Returns(new[] {emptyFolder1, emptyFolder2});
            fixture.FileHelpers.EnumerateDirectories(emptyFolder1).Returns(new[] {nonEmptySubFolder1A});
            fixture.FileHelpers.EnumerateDirectories(nonEmptySubFolder1A).Returns(new string[0]);
            fixture.FileHelpers.EnumerateDirectories(emptyFolder2).Returns(new string[0]);

            fixture.FileHelpers.EnumerateFileSystemEntries(absolutePath).Returns(new[] {emptyFolder1});
            fixture.FileHelpers.EnumerateFileSystemEntries(emptyFolder1).Returns(new[] {nonEmptySubFolder1A});
            fixture.FileHelpers.EnumerateFileSystemEntries(nonEmptySubFolder1A).Returns(new[] {Path.Combine(nonEmptySubFolder1A, "someFile.txt")});
            fixture.FileHelpers.EnumerateFileSystemEntries(emptyFolder2).Returns(new string[0]);

            await fixture.Subject.Clean(fixture.SessionGuid, sessionRootPath);

            fixture.FileSystem.DidNotReceive().DeleteFolder(absolutePath);
            fixture.FileSystem.DidNotReceive().DeleteFolder(emptyFolder1);
            fixture.FileSystem.DidNotReceive().DeleteFolder(nonEmptySubFolder1A);
        }

        [Fact]
        public async Task ShouldNotFailWhenDirectoryNotFound()
        {
            var fixture = new ScheduleExecutionSessionFolderCleanerFixture();
            var sessionRootPath = @"tempstorage\" + fixture.SessionGuid;
            var absolutePath = Path.Combine(@"c:\inprotech\", sessionRootPath);

            fixture.FileSystem.AbsolutePath(sessionRootPath).Returns(absolutePath);

            fixture.FileHelpers.DirectoryExists(absolutePath).Returns(true);

            fixture.FileHelpers.EnumerateDirectories(absolutePath).Returns(new string[0]);
            fixture.FileHelpers.EnumerateFileSystemEntries(absolutePath).Returns(new string[0]);

            var ex = await Record.ExceptionAsync(async () => await fixture.Subject.Clean(fixture.SessionGuid, sessionRootPath));
            Assert.Null(ex);
        }

        [Fact]
        public async Task ShouldNotFailWhenFolderAccessUnauthorized()
        {
            var fixture = new ScheduleExecutionSessionFolderCleanerFixture();
            var sessionRootPath = @"tempstorage\" + fixture.SessionGuid;
            var absolutePath = Path.Combine(@"c:\inprotech\", sessionRootPath);

            fixture.FileSystem.AbsolutePath(sessionRootPath).Returns(absolutePath);

            fixture.FileHelpers.DirectoryExists(absolutePath).Returns(true);

            fixture.FileHelpers.EnumerateDirectories(absolutePath).Returns(new string[0]);
            fixture.FileHelpers.EnumerateFileSystemEntries(absolutePath).Returns(new string[0]);

            var ex = await Record.ExceptionAsync(async () => await fixture.Subject.Clean(fixture.SessionGuid, sessionRootPath));
            Assert.Null(ex);
        }

        [Fact]
        public async Task ShouldNotFailWhenRootFolderDoesNotExist()
        {
            var fixture = new ScheduleExecutionSessionFolderCleanerFixture();
            var sessionRootPath = @"tempstorage\" + fixture.SessionGuid;
            var absolutePath = Path.Combine(@"c:\inprotech\", sessionRootPath);

            fixture.FileSystem.AbsolutePath(sessionRootPath).Returns(absolutePath);

            fixture.FileHelpers.DirectoryExists(absolutePath).Returns(false);

            fixture.FileHelpers.EnumerateDirectories(absolutePath).Returns(c => throw new DirectoryNotFoundException());
            fixture.FileHelpers.EnumerateFileSystemEntries(absolutePath).Returns(new string[0]);

            var ex = await Record.ExceptionAsync(async () => await fixture.Subject.Clean(fixture.SessionGuid, sessionRootPath));
            Assert.Null(ex);
        }

        [Fact]
        public async Task ShouldPublishMessageWhenFolderCleanUpFails()
        {
            var fixture = new ScheduleExecutionSessionFolderCleanerFixture();
            var sessionRootPath = @"tempstorage\" + fixture.SessionGuid;
            var absolutePath = Path.Combine(@"c:\inprotech\", sessionRootPath);

            fixture.FileSystem.AbsolutePath(sessionRootPath).Returns(absolutePath);

            fixture.FileHelpers.DirectoryExists(absolutePath).Returns(true);

            fixture.FileHelpers.EnumerateDirectories(absolutePath).Returns(new string[0]);
            fixture.FileHelpers.EnumerateFileSystemEntries(absolutePath).Returns(info => throw new Exception("failed"));

            await Assert.ThrowsAsync<Exception>(async () => await fixture.Subject.Clean(fixture.SessionGuid, sessionRootPath));

            fixture.Publisher.Received(1).Publish(Arg.Is(fixture.SessionGuid), Arg.Is("Folder is empty"),
                                                  Arg.Is(absolutePath), Arg.Is<Exception>(e => e.Message == "failed"));
        }

        [Fact]
        public async Task ShouldPublishMessageWhenFolderDeleted()
        {
            var fixture = new ScheduleExecutionSessionFolderCleanerFixture();
            var sessionRootPath = @"tempstorage\" + fixture.SessionGuid;
            var absolutePath = Path.Combine(@"c:\inprotech\", sessionRootPath);

            fixture.FileSystem.AbsolutePath(sessionRootPath).Returns(absolutePath);

            fixture.FileHelpers.DirectoryExists(absolutePath).Returns(true);

            fixture.FileHelpers.EnumerateDirectories(absolutePath).Returns(new string[0]);
            fixture.FileHelpers.EnumerateFileSystemEntries(absolutePath).Returns(new string[0]);

            await fixture.Subject.Clean(fixture.SessionGuid, sessionRootPath);

            fixture.Publisher.Received(1).Publish(Arg.Is(fixture.SessionGuid), Arg.Is("Folder is empty"), Arg.Is(absolutePath));
        }
    }

    internal class ScheduleExecutionSessionFolderCleanerFixture : IFixture<ScheduleExecutionSessionFolderCleaner>
    {
        public IFileHelpers FileHelpers = Substitute.For<IFileHelpers>();

        public IFileSystem FileSystem = Substitute.For<IFileSystem>();

        public IPublishFolderCleanUpEvents Publisher = Substitute.For<IPublishFolderCleanUpEvents>();

        public Guid SessionGuid = Guid.NewGuid();

        public ScheduleExecutionSessionFolderCleaner Subject => new ScheduleExecutionSessionFolderCleaner(FileHelpers, FileSystem, Publisher);
    }
}