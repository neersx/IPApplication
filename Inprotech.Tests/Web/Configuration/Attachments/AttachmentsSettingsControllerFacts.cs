using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Configuration.Attachments;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Attachments
{
    public class AttachmentsSettingsControllerFacts
    {
        public class ValidatePath
        {
            [Fact]
            public void CheckPathAndNetworkDrive()
            {
                var drive = "Z:\\";
                var path = $"{drive}ABC";
                var networkPath = "\\Server123\\Folder1";
                var combinedPath = networkPath + "\\ABC";

                var f = new AttachmentsSettingsControllerFixture()
                    .WithFiles(path, exists: false);
                f.FileHelpers.GetPathRoot(path).Returns(drive);
                f.FileHelpers.DirectoryExists(drive).Returns(false);
                f.FileHelpers.FilePathValid(combinedPath).Returns(true);

                var r = f.Subject.ValidatePath(new AttachmentsSettingsController.ValidatePathModel
                {
                    Path = path,
                    NetworkDrives = new[] {new AttachmentSetting.NetworkDrive {DriveLetter = drive, UncPath = networkPath}}
                });

                Assert.False(r);
                f.FileHelpers.Received(1).GetPathRoot(path);
                f.FileHelpers.Received(1).DirectoryExists(drive);
                f.FileHelpers.Received(1).FilePathValid(combinedPath);
                f.FileHelpers.Received(1).DirectoryExists(combinedPath);
            }

            [Fact]
            public void CheckPathIfNetworkDriveDoesNotMatch()
            {
                var drive = "Z:\\";
                var path = $"{drive}ABC";
                var networkPath = "\\Server123\\Folder1";
                var f = new AttachmentsSettingsControllerFixture()
                    .WithFiles(path, exists: false);
                f.FileHelpers.GetPathRoot(path).Returns(drive);
                f.FileHelpers.DirectoryExists(drive).Returns(false);
                var r = f.Subject.ValidatePath(new AttachmentsSettingsController.ValidatePathModel
                {
                    Path = path,
                    NetworkDrives = new[] {new AttachmentSetting.NetworkDrive {DriveLetter = "U:", UncPath = networkPath}}
                });
                Assert.False(r);
                f.FileHelpers.Received(1).GetPathRoot(path);
                f.FileHelpers.Received(1).DirectoryExists(drive);
                f.FileHelpers.Received(1).FilePathValid(path);
                f.FileHelpers.Received(1).DirectoryExists(path);
            }

            [Fact]
            public void ValidateLocalRootPathForValidDrive()
            {
                var path = "U:\\ABC";
                var f = new AttachmentsSettingsControllerFixture()
                    .WithFiles();
                f.FileHelpers.GetPathRoot(path).Returns("U:\\");
                var r = f.Subject.ValidatePath(new AttachmentsSettingsController.ValidatePathModel
                {
                    Path = path
                });
                Assert.Equal(r, true);
                f.FileHelpers.Received(1).GetPathRoot(Arg.Any<string>());
                f.FileHelpers.Received(2).DirectoryExists(Arg.Any<string>());
                f.FileHelpers.Received(1).FilePathValid(Arg.Any<string>());
            }

            [Fact]
            public void ValidateRelativePAthIfItExists()
            {
                var path = "Abc";
                var f = new AttachmentsSettingsControllerFixture()
                    .WithFiles();
                var r = f.Subject.ValidatePath(new AttachmentsSettingsController.ValidatePathModel
                {
                    Path = path
                });
                Assert.Equal(r, true);
                f.FileHelpers.Received(1).FilePathValid(Arg.Any<string>());
                f.FileHelpers.Received(1).DirectoryExists(Arg.Any<string>());
            }
        }

        class AttachmentsSettingsControllerFixture : IFixture<AttachmentsSettingsController>
        {
            public AttachmentsSettingsControllerFixture()
            {
                Settings = Substitute.For<IAttachmentSettings>();
                FileHelpers = Substitute.For<IFileHelpers>();
                StorageServiceClient = Substitute.For<IStorageServiceClient>();
                Subject = new AttachmentsSettingsController(Settings, FileHelpers, StorageServiceClient);
            }

            public IAttachmentSettings Settings { get; }
            public IFileHelpers FileHelpers { get; }

            public IStorageServiceClient StorageServiceClient { get; }

            public AttachmentsSettingsController Subject { get; }

            public AttachmentsSettingsControllerFixture WithFiles(string path = null, bool valid = true, bool exists = true)
            {
                FileHelpers.FilePathValid(path ?? Arg.Any<string>()).Returns(valid);
                FileHelpers.DirectoryExists(path ?? Arg.Any<string>()).Returns(exists);
                return this;
            }
        }

        [Fact]
        public async Task ShouldCallSaveMethodOnSettingsIfNoStorageLocations()
        {
            var setting = new AttachmentSetting
            {
                StorageLocations = new AttachmentSetting.StorageLocation[0]
            };
            var f = new AttachmentsSettingsControllerFixture();
            await f.Subject.Update(setting);

            f.Settings.Received(1).Save(Arg.Is<AttachmentSetting>(x => x.IsRestricted)).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldNotSaveIfStorageLocationHasFailure()
        {
            var failingPath = Fixture.String();
            var setting = new AttachmentSetting
            {
                StorageLocations = new[]
                {
                    new AttachmentSetting.StorageLocation
                    {
                        Path = failingPath
                    },
                    new AttachmentSetting.StorageLocation()
                }
            };

            var f = new AttachmentsSettingsControllerFixture();
            f.FileHelpers.FilePathValid(failingPath).Returns(false);

            var result = await f.Subject.Update(setting);

            f.Settings.DidNotReceive().Save(Arg.Is<AttachmentSetting>(x => x.IsRestricted)).IgnoreAwaitForNSubstituteAssertion();
            f.FileHelpers.Received(1).FilePathValid(Arg.Any<string>());
            Assert.True(result.InvalidPath);
        }

        [Fact]
        public async Task ShouldSaveIfAllFilePathsAreValid()
        {
            var setting = new AttachmentSetting
            {
                StorageLocations = new[]
                {
                    new AttachmentSetting.StorageLocation {Path = "path1"},
                    new AttachmentSetting.StorageLocation {Path = "path2"}
                }
            };

            var f = new AttachmentsSettingsControllerFixture();
            f.FileHelpers.FilePathValid(Arg.Any<string>()).Returns(true);
            f.FileHelpers.DirectoryExists(Arg.Any<string>()).Returns(true);

            var result = await f.Subject.Update(setting);

            f.Settings.Received(1).Save(Arg.Is<AttachmentSetting>(x => x.IsRestricted)).IgnoreAwaitForNSubstituteAssertion();
            Assert.False(result.InvalidPath);
        }
    }
}