using System;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Web.Http.Controllers;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Attachment;
using Inprotech.Web.Configuration.Attachments;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Attachment
{
    public class AttachmentControllerFacts
    {
        public class Validation : FactBase
        {
            public class ValidatePathMethod
            {
                [Fact]
                public async Task ShouldResultOfValidatePathIfPathNotEmpty()
                {
                    var f = new AttachmentControllerFixture();
                    var path = Fixture.String();
                    f.StorageServiceClient.ValidatePath(path, Arg.Any<HttpRequestMessage>()).Returns(true);

                    var result = await f.Subject.ValidatePath(path);

                    Assert.True(result);
                }

                [Fact]
                public async Task ShouldReturnFalseIfPathIsEmpty()
                {
                    var f = new AttachmentControllerFixture();

                    var result = await f.Subject.ValidatePath(string.Empty);
                    Assert.False(result);
                }
            }

            public class ValidateDirectoryMethod
            {
                [Fact]
                public async Task ShouldResultOfValidatePathIfPathNotEmpty()
                {
                    var f = new AttachmentControllerFixture();
                    var path = Fixture.String();
                    f.StorageServiceClient.ValidateDirectory(path, Arg.Any<HttpRequestMessage>()).Returns(new DirectoryValidationResult() {DirectoryExists = true});

                    var result = await f.Subject.ValidateDirectory(path);

                    Assert.True(result.DirectoryExists);
                }

                [Fact]
                public async Task ShouldReturnFalseIfPathIsEmpty()
                {
                    var f = new AttachmentControllerFixture();

                    var result = await f.Subject.ValidateDirectory(string.Empty);
                    Assert.False(result.DirectoryExists);
                    Assert.False(result.IsLinkedToStorageLocation);
                }
            }

            [Fact]
            public async Task GetAllowedExtensions()
            {
                var f = new AttachmentControllerFixture();
                f.AttachmentSettings.Resolve().ReturnsForAnyArgs(new AttachmentSetting
                {
                    StorageLocations = new[]
                    {
                        new AttachmentSetting.StorageLocation
                        {
                            AllowedFileExtensions = ".pdf", Name = "storageLocation", Path = "c:\\test", StorageLocationId = 1
                        }
                    }
                });

                var exception = await Assert.ThrowsAsync<ArgumentNullException>(
                                                                                async () => await f.Subject.GetStorageLocation(string.Empty));

                Assert.IsType<ArgumentNullException>(exception);

                var result = await f.Subject.GetStorageLocation("c:\\test\\subfolder");
                Assert.Equal(".pdf", result.AllowedFileExtensions);
            }

            [Fact]
            public async Task GetFiles()
            {
                var f = new AttachmentControllerFixture();
                f.StorageServiceClient.GetDirectoryFiles(Arg.Any<string>(), Arg.Any<HttpRequestMessage>()).ReturnsForAnyArgs(new HttpResponseMessage(HttpStatusCode.BadRequest));

                var result = await f.Subject.GetDirectoryFiles(string.Empty);
                Assert.False(result.IsSuccessStatusCode);
            }

            [Fact]
            public async Task GetFolders()
            {
                var f = new AttachmentControllerFixture();
                f.StorageServiceClient.GetDirectoryFolders(Arg.Any<HttpRequestMessage>()).ReturnsForAnyArgs(new HttpResponseMessage(HttpStatusCode.Accepted));

                var result = await f.Subject.GetDirectoryFolders();
                Assert.True(result.IsSuccessStatusCode);
            }

            [Fact]
            public async Task ShouldCallTheComponentToSuccessfullyUploadTheFile()
            {
                var f = new AttachmentControllerFixture();

                var controllerContext = new HttpControllerContext();
                var request = new HttpRequestMessage(HttpMethod.Post, "uploadFiles");
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

                f.StorageServiceClient.UploadFile(Arg.Any<HttpRequestMessage>()).ReturnsForAnyArgs(new HttpResponseMessage(HttpStatusCode.Accepted));

                var result = await f.Subject.UploadFiles();

                Assert.True(result.IsSuccessStatusCode);
            }
        }

        public class View
        {
            [Theory]
            [InlineData(true, true, true)]
            [InlineData(true, true, false)]
            [InlineData(true, false, false)]
            [InlineData(true, false, true)]
            [InlineData(false, false, false)]
            [InlineData(false, true, false)]
            [InlineData(false, true, true)]
            public async void ChecksTaskSecurityForCaseAttachments(bool canAdd, bool canEdit, bool canDelete)
            {
                var f = new AttachmentControllerFixture();
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.Create).Returns(canAdd);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.Modify).Returns(canEdit);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseAttachments, ApplicationTaskAccessLevel.Delete).Returns(canDelete);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPriorArtAttachment, Arg.Any<ApplicationTaskAccessLevel>()).Returns(false);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.AccessDocumentsfromDms).Returns(false);
                f.SubjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments).Returns(false);
                var data = await f.Subject.View();

                Assert.Equal(canAdd, data.CanMaintainCaseAttachments.CanAdd);
                Assert.Equal(canEdit, data.CanMaintainCaseAttachments.CanEdit);
                Assert.Equal(canDelete, data.CanMaintainCaseAttachments.CanDelete);
                Assert.False(data.CanMaintainPriorArtAttachments.CanAdd);
                Assert.False(data.CanMaintainPriorArtAttachments.CanEdit);
                Assert.False(data.CanMaintainPriorArtAttachments.CanDelete);
                Assert.False(data.CanAccessDocumentsFromDms);
                Assert.False(data.CanViewCaseAttachments);
            }

            [Theory]
            [InlineData(true, true, true)]
            [InlineData(true, true, false)]
            [InlineData(true, false, false)]
            [InlineData(true, false, true)]
            [InlineData(false, false, false)]
            [InlineData(false, true, false)]
            [InlineData(false, true, true)]
            public async void ChecksTaskSecurityForPriorArtAttachments(bool canAdd, bool canEdit, bool canDelete)
            {
                var f = new AttachmentControllerFixture();
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPriorArtAttachment, ApplicationTaskAccessLevel.Create).Returns(canAdd);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPriorArtAttachment, ApplicationTaskAccessLevel.Modify).Returns(canEdit);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPriorArtAttachment, ApplicationTaskAccessLevel.Delete).Returns(canDelete);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseAttachments, Arg.Any<ApplicationTaskAccessLevel>()).Returns(false);
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.AccessDocumentsfromDms).Returns(true);
                f.SubjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments).Returns(true);
                var data = await f.Subject.View();

                Assert.Equal(canAdd, data.CanMaintainPriorArtAttachments.CanAdd);
                Assert.Equal(canEdit, data.CanMaintainPriorArtAttachments.CanEdit);
                Assert.Equal(canDelete, data.CanMaintainPriorArtAttachments.CanDelete);
                Assert.False(data.CanMaintainCaseAttachments.CanAdd);
                Assert.False(data.CanMaintainCaseAttachments.CanEdit);
                Assert.False(data.CanMaintainCaseAttachments.CanDelete);
                Assert.True(data.CanAccessDocumentsFromDms);
                Assert.True(data.CanViewCaseAttachments);
            }
        }

        public class AttachmentControllerFixture : IFixture<AttachmentController>
        {
            public AttachmentControllerFixture()
            {
                StorageServiceClient = Substitute.For<IStorageServiceClient>();
                AttachmentSettings = Substitute.For<IAttachmentSettings>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                SubjectSecurityProvider = Substitute.For<ISubjectSecurityProvider>();
                Subject = new AttachmentController(StorageServiceClient, Substitute.For<IActivityAttachmentAccessResolver>(), Substitute.For<IAttachmentContentLoader>(), AttachmentSettings, Substitute.For<IActivityAttachmentFileNameResolver>(), TaskSecurityProvider, SubjectSecurityProvider);
            }

            public IStorageServiceClient StorageServiceClient { get; }
            public IAttachmentSettings AttachmentSettings { get; }
            public ITaskSecurityProvider TaskSecurityProvider { get; }
            public ISubjectSecurityProvider SubjectSecurityProvider { get; }
            public AttachmentController Subject { get; }
        }
    }
}