using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.DmsIntegration.Component;
using Inprotech.Web.Configuration.Attachments;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Attachments
{
    public class AttachmentsSettingsViewControllerFacts
    {
        [Fact]
        public async Task Get()
        {
            var f = new AttachmentsSettingsViewControllerFixture();
            var res = await f.Subject.Get();
            var r = res.ViewData.Settings as AttachmentSetting;
            Assert.Equal(f.attachmentSetting.IsRestricted, r.IsRestricted);
            Assert.Equal(f.attachmentSetting.NetworkDrives.Single().DriveLetter, r.NetworkDrives.Single().DriveLetter);
            Assert.Equal(f.attachmentSetting.StorageLocations.Single().Name, r.StorageLocations.Single().Name);
        }

        class AttachmentsSettingsViewControllerFixture : IFixture<AttachmentsSettingsViewController>
        {
            public AttachmentSetting attachmentSetting => new AttachmentSetting()
            {
                IsRestricted = true,
                NetworkDrives = new List<AttachmentSetting.NetworkDrive> { new AttachmentSetting.NetworkDrive { DriveLetter = "Z", UncPath = "C:\\Abc" } }.ToArray(),
                StorageLocations = new List<AttachmentSetting.StorageLocation> { new AttachmentSetting.StorageLocation { Name = "Storage", Path = "C:\\Abc" } }.ToArray()
            };

            public AttachmentsSettingsViewControllerFixture()
            {
                Settings = Substitute.For<IAttachmentSettings>();
                Settings.Resolve().Returns(attachmentSetting);
                DmsSettings = Substitute.For<IDmsSettingsProvider>();
                DmsSettings.HasSettings().Returns(true);
                Subject = new AttachmentsSettingsViewController(Settings, DmsSettings);
            }

            public AttachmentsSettingsViewController Subject { get; }

            IAttachmentSettings Settings { get; }
            IDmsSettingsProvider DmsSettings { get; }
        }
    }
}