using System;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.StorageService;
using Inprotech.StorageService.Storage;
using Inprotech.Web.Configuration.Attachments;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.StorageService
{
    public class StorageServiceFacts : FactBase
    {
        public class ValidatePathMethod : FactBase
        {
            [Fact]
            public async Task ShouldThrowExceptionIfNoAttachmentSettings()
            {
                var fixture = new StorageServiceFixture();
                var path = Fixture.String();
                fixture.Settings.Resolve().Returns((AttachmentSetting) null);

                await Assert.ThrowsAsync<ApplicationException>(async () => await fixture.Subject.ValidatePath(path));
            }

            [Fact]
            public async Task ShouldValidatePathDrive()
            {
                var f = new StorageServiceFixture().WithSettings();
                var filePath = @"C:\test.pdf";
                var filePath2 = @"W:\test.pdf";

                f.FileHelpers.Exists(filePath).Returns(true);
                f.FileHelpers.GetFileExtension(filePath).Returns("pdf");
                f.FileHelpers.Exists(@"\\server1\path1\test.pdf").Returns(true);
                f.FileHelpers.GetFileExtension(@"\\server1\path1\test.pdf").Returns("pdf");

                var result = await f.Subject.ValidatePath(filePath);
                Assert.False(result);
                var result2 = await f.Subject.ValidatePath(filePath2);
                Assert.True(result2);
            }

            [Fact]
            public async Task ValidatePathExtensionNotExisted()
            {
                var f = new StorageServiceFixture().WithSettings();
                var filePath = @"W:\test.log";
                var filePath2 = @"W:\test.pdf";

                f.FileHelpers.Exists(@"\\server1\path1\test.log").Returns(true);
                f.FileHelpers.GetFileExtension(@"\\server1\path1\test.log").Returns("log");
                f.FileHelpers.Exists(@"\\server1\path1\test.pdf").Returns(true);
                f.FileHelpers.GetFileExtension(@"\\server1\path1\test.pdf").Returns("pdf");

                var result = await f.Subject.ValidatePath(filePath);
                Assert.False(result);
                var result2 = await f.Subject.ValidatePath(filePath2);
                Assert.True(result2);
            }

            [Fact]
            public async Task ValidatePathMappedPathNotIncluded()
            {
                var f = new StorageServiceFixture().WithSettings();
                var filePath = @"W:\test.txt";
                var filePath2 = @"\\server2\path2\folder\test.txt";
                var filePath3 = @"\\server2\pathInvalid\test.txt";

                f.FileHelpers.Exists(@"\\server1\path1\test.txt").Returns(true);
                f.FileHelpers.GetFileExtension(@"\\server1\path1\test.txt").Returns("txt");
                f.FileHelpers.Exists(filePath2).Returns(true);
                f.FileHelpers.GetFileExtension(filePath2).Returns("txt");
                f.FileHelpers.Exists(filePath3).Returns(true);
                f.FileHelpers.GetFileExtension(filePath2).Returns("txt");
                var result = await f.Subject.ValidatePath(filePath);
                Assert.True(result);
                var result2 = await f.Subject.ValidatePath(filePath2);
                Assert.True(result2);
                var result3 = await f.Subject.ValidatePath(filePath3);
                Assert.False(result3);
            }
        }

        public class ValidateDirectoryMethod : FactBase
        {
            [Fact]
            public async Task ShouldThrowExceptionIfNoAttachmentSettings()
            {
                var fixture = new StorageServiceFixture();
                var path = Fixture.String();
                fixture.Settings.Resolve().Returns((AttachmentSetting) null);

                await Assert.ThrowsAsync<ApplicationException>(async () => await fixture.Subject.ValidateDirectory(path));
            }

            [Fact]
            public async Task ShouldValidatePathDrive()
            {
                var f = new StorageServiceFixture().WithSettings();
                var filePath = @"C:\test\";
                var filePath2 = @"W:\test\";

                f.FileHelpers.DirectoryExists(filePath).Returns(true);
                f.FileHelpers.DirectoryExists(@"\\server1\path1\test\").Returns(true);

                var result = await f.Subject.ValidateDirectory(filePath);
                Assert.False(result.DirectoryExists);
                var result2 = await f.Subject.ValidateDirectory(filePath2);
                Assert.True(result2.DirectoryExists);
            }

            [Fact]
            public async Task ValidatePathMappedPathNotIncluded()
            {
                var f = new StorageServiceFixture().WithSettings();
                var filePath = @"W:\";
                var filePath2 = @"\\server2\path2\folder\";
                var filePath3 = @"\\server2\pathInvalid\";

                f.FileHelpers.DirectoryExists(@"\\server1\path1\").Returns(true);
                f.FileHelpers.DirectoryExists(filePath2).Returns(true);
                f.FileHelpers.DirectoryExists(filePath3).Returns(true);
                var result = await f.Subject.ValidateDirectory(filePath);
                Assert.True(result.IsLinkedToStorageLocation);
                Assert.True(result.DirectoryExists);
                var result2 = await f.Subject.ValidateDirectory(filePath2);
                Assert.True(result2.DirectoryExists);
                Assert.True(result2.IsLinkedToStorageLocation);
                var result3 = await f.Subject.ValidateDirectory(filePath3);
                Assert.False(result3.DirectoryExists);
                Assert.False(result3.IsLinkedToStorageLocation);
            }
        }

        public class GetDirectoryFoldersMethod
        {
            [Fact]
            public async Task ShouldCallToCacheToGetTopFolders()
            {
                var f = new StorageServiceFixture();

                await f.Subject.GetDirectoryFolders();

                await f.StorageCache.Received(1).FetchFolders();
            }
        }

        public class RebuildDirectoryCachingMethod
        {
            [Fact]
            public void ShouldCallToRepopulateCache()
            {
                var f = new StorageServiceFixture();

                f.Subject.RebuildDirectoryCaching();

                f.StorageCache.Received(1).RebuildEntireCache();
            }
        }

        public class GetDirectoryFilesMethod
        {
            [Fact]
            public async Task ShouldCallToGetDirectoryFiles()
            {
                var f = new StorageServiceFixture();
                var path = Fixture.String();
                var files = new[]
                {
                    new StorageFile {DateModified = Fixture.Date()}
                };
                f.StorageCache.FetchFilePaths(path).Returns(Task.FromResult(files.AsEnumerable()));

                var result = await f.Subject.GetDirectoryFiles(path);

                Assert.Equal(files, result);
                await f.StorageCache.Received(1).FetchFilePaths(path);
            }
        }

        public class SaveFileMethod
        {
            [Fact]
            public async Task ShouldDoValidation()
            {
                var f = new StorageServiceFixture().WithSettings();

                var file = new FileToUpload
                {
                    FileName = "file.pdf",
                    FileBytes = new byte[4194303],
                    FolderPath = "c:\\temp"
                };

                file.FolderPath = string.Empty;
                var ex = await Assert.ThrowsAsync<ArgumentNullException>(
                                                                         async () => await f.Subject.SaveFile(file));
                Assert.Equal("FolderPath", ex.ParamName);

                file.FolderPath = "c:\\temp";
                file.FileBytes = null;
                ex = await Assert.ThrowsAsync<ArgumentNullException>(
                                                                     async () => await f.Subject.SaveFile(file));
                Assert.Equal("FileBytes", ex.ParamName);

                file.FileBytes = new byte[4194305];
                var resp = await Assert.ThrowsAsync<HttpResponseException>(
                                                                           async () => await f.Subject.SaveFile(file));
                Assert.Equal(HttpStatusCode.BadRequest, resp.Response.StatusCode);
                Assert.True(resp.Response.ReasonPhrase.Contains("File size exceeded"));
                file.FileBytes = new byte[4194303];
                resp = await Assert.ThrowsAsync<HttpResponseException>(
                                                                       async () => await f.Subject.SaveFile(file));
                Assert.Equal(HttpStatusCode.BadRequest, resp.Response.StatusCode);
                Assert.True(resp.Response.ReasonPhrase.Contains("Invalid folder path"));
            }
        }

        public class StorageServiceFixture : IFixture<Inprotech.StorageService.Storage.StorageService>
        {
            public StorageServiceFixture()
            {
                Settings = Substitute.For<IAttachmentSettings>();
                FileHelpers = Substitute.For<IFileHelpers>();
                StorageCache = Substitute.For<IStorageCache>();
                FileTypeChecker = Substitute.For<IFileTypeChecker>();
                Subject = new Inprotech.StorageService.Storage.StorageService(FileHelpers, StorageCache, Substitute.For<IValidateHttpOrHttpsString>(), FileTypeChecker);
            }

            public IAttachmentSettings Settings { get; }
            public IFileHelpers FileHelpers { get; }
            public IStorageCache StorageCache { get; }

            public IFileTypeChecker FileTypeChecker { get; }

            public Inprotech.StorageService.Storage.StorageService Subject { get; }

            public StorageServiceFixture WithSettings()
            {
                var data = new AttachmentSetting
                {
                    IsRestricted = true,
                    NetworkDrives = new[]
                    {
                        new AttachmentSetting.NetworkDrive {DriveLetter = "W", NetworkDriveMappingId = 0, UncPath = @"\\server1\path1"},
                        new AttachmentSetting.NetworkDrive {DriveLetter = "V", NetworkDriveMappingId = 1, UncPath = @"\\server2\path2\"}
                    },
                    StorageLocations = new[]
                    {
                        new AttachmentSetting.StorageLocation {AllowedFileExtensions = "txt,pdf", Name = "name1", Path = @"W:\"},
                        new AttachmentSetting.StorageLocation {AllowedFileExtensions = "txt,pdf", Name = "name2", Path = @"V:\folder\"}
                    }
                };
                StorageCache.GetExistingAttachmentSetting().Returns(Task.FromResult(data));
                return this;
            }
        }
    }
}