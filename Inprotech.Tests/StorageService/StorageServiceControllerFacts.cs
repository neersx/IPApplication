using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using Inprotech.Infrastructure;
using Inprotech.StorageService.Api;
using Inprotech.StorageService.Storage;
using Inprotech.Web.Configuration.Attachments;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.StorageService
{
    public class StorageServiceControllerFacts
    {
        public class ValidationMethod : FactBase
        {
            [Fact]
            public async Task ShouldValidatePath()
            {
                var f = new StorageServiceControllerFixture();
                f.StorageService.ValidatePath("c:testPath").Returns(true);

                var result = await f.Subject.ValidatePath(string.Empty);
                Assert.Equal(false, result);

                result = await f.Subject.ValidatePath("c:testPath");
                Assert.Equal(true, result);
            }
        }

        public class ValideDirectoryMethod : FactBase
        {
            [Fact]
            public async Task ShouldValidateDirectory()
            {
                var f = new StorageServiceControllerFixture();
                f.StorageService.ValidateDirectory("c:testPath").Returns(new DirectoryValidationResult() { DirectoryExists = true });

                var result = await f.Subject.ValidateDirectory(string.Empty);
                Assert.Equal(false, result.DirectoryExists);

                result = await f.Subject.ValidateDirectory("c:testPath");
                Assert.Equal(true, result.DirectoryExists);
            }
        }

        public class GetDirectoryFilesMethod
        {
            [Fact]
            public async Task ShouldGetFiles()
            {
                var f = new StorageServiceControllerFixture();
                var list = new List<StorageFile>
                {
                    new StorageFile
                    {
                        PathShortName = "fileName", FullPath = "fileFullPath"
                    }
                };
                f.StorageService.GetDirectoryFiles("c:path").Returns(list);

                var result = await f.Subject.GetDirectoryFiles(string.Empty);
                Assert.Equal(new List<StorageFile>(), result);

                var result2 = await f.StorageService.GetDirectoryFiles("c:path");
                Assert.Equal(list, result2);
            }
        }

        public class GetDirectoryFoldersMethod
        {
            [Fact]
            public async Task ShouldGetFolder()
            {
                var f = new StorageServiceControllerFixture();

                await f.Subject.GetDirectoryFolders();

                await f.StorageService.Received(1).GetDirectoryFolders();
            }
        }

        public class RefreshMethod
        {
            [Fact]
            public async Task ShouldRebuildCache()
            {
                var f = new StorageServiceControllerFixture();

                await f.Subject.Refresh(new AttachmentSetting());

                await f.StorageService.Received(1).RebuildDirectoryCaching(Arg.Any<AttachmentSetting>());
            }
        }

        public class GetFileMethod
        {
            [Fact]
            public async Task ShouldReturnNotFoundIfCantFindPath()
            {
                var path = Fixture.String();
                var f = new StorageServiceControllerFixture();
                f.StorageService.GetTranslatedFilePath(path).Returns(Task.FromResult((string)null));
                f.Subject.Request = new HttpRequestMessage();

                var response = await f.Subject.GetFile(path);

                Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
                f.FileHelpers.DidNotReceive().Exists(Arg.Any<string>());
            }

            [Fact]
            public async Task ShouldReturnNotFoundIfFileNotInFileSystem()
            {
                var path = Fixture.String();
                var mappedPath = Fixture.String();
                var f = new StorageServiceControllerFixture();
                f.StorageService.GetTranslatedFilePath(path).Returns(Task.FromResult(mappedPath));
                f.FileHelpers.Exists(mappedPath).Returns(false);
                f.Subject.Request = new HttpRequestMessage();

                var response = await f.Subject.GetFile(path);

                Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
                f.FileHelpers.Received(1).Exists(mappedPath);
            }

            [Fact]
            public async Task UploadFilesHappyPath()
            {
                var f = new StorageServiceControllerFixture();

                var controllerContext = new HttpControllerContext();
                var request = new HttpRequestMessage(HttpMethod.Post, "uploadFile");
                var content = new MultipartFormDataContent();

                var fileContent = new ByteArrayContent(new byte[100]);
                fileContent.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
                {
                    FileName = "test.txt"
                };
                var stringContent = new StringContent("c:\\path");
                content.Add(fileContent);
                content.Add(stringContent);
                request.Content = content;

                controllerContext.Request = request;
                f.Subject.ControllerContext = controllerContext;

                f.StorageService.SaveFile(Arg.Any<FileToUpload>()).ReturnsForAnyArgs(new HttpResponseMessage(HttpStatusCode.Accepted));
                var result = await f.Subject.UploadFiles();

                Assert.True(result.IsSuccessStatusCode);
            }

            [Fact]
            public async Task UploadFilesInvalidContent()
            {
                var f = new StorageServiceControllerFixture();

                var controllerContext = new HttpControllerContext();
                var request = new HttpRequestMessage(HttpMethod.Post, "uploadFile");
                var content = new MultipartFormDataContent();

                var fileContent = new ByteArrayContent(new byte[100]);
                fileContent.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
                {
                    FileName = "test.txt"
                };
                content.Add(fileContent);
                request.Content = content;

                controllerContext.Request = request;
                f.Subject.ControllerContext = controllerContext;

                f.StorageService.SaveFile(Arg.Any<FileToUpload>()).ReturnsForAnyArgs(new HttpResponseMessage(HttpStatusCode.Accepted));

                var exception = await Assert.ThrowsAsync<ArgumentException>(
                                                                            async () => await f.Subject.UploadFiles());

                Assert.IsType<ArgumentException>(exception);
            }

            [Fact]
            public async Task UploadFilesInvalidMessage()
            {
                var f = new StorageServiceControllerFixture();

                var controllerContext = new HttpControllerContext();
                var request = new HttpRequestMessage(HttpMethod.Post, "uploadFile");

                request.Content = new StringContent("string content");

                controllerContext.Request = request;
                f.Subject.ControllerContext = controllerContext;

                f.StorageService.SaveFile(Arg.Any<FileToUpload>()).ReturnsForAnyArgs(new HttpResponseMessage(HttpStatusCode.Accepted));

                var result = await f.Subject.UploadFiles();

                Assert.False(result.IsSuccessStatusCode);
                Assert.Equal(HttpStatusCode.UnsupportedMediaType, result.StatusCode);
            }
        }

        public class StorageServiceControllerFixture : IFixture<StorageServiceController>
        {
            public StorageServiceControllerFixture()
            {
                StorageService = Substitute.For<IStorageService>();
                FileHelpers = Substitute.For<IFileHelpers>();
                Subject = new StorageServiceController(StorageService, FileHelpers);
            }

            public IStorageService StorageService { get; }
            public IFileHelpers FileHelpers { get; }
            public StorageServiceController Subject { get; }
        }
    }
}