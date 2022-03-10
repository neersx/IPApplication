using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Configuration.Attachments;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.System.Settings;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Attachments
{
    public class AttachmentSettingsFacts
    {
        [Fact]
        public async Task Resolve()
        {
            var f = new AttachmentSettingsFixture();
            f.ExternalSettings.Resolve<AttachmentSetting>(KnownExternalSettings.Attachment).Returns(new AttachmentSetting()
            {
                StorageLocations = new List<AttachmentSetting.StorageLocation>()
                {
                    new AttachmentSetting.StorageLocation {Name = Fixture.String(), Path = Fixture.String()},
                    new AttachmentSetting.StorageLocation {Name = Fixture.String(), Path = Fixture.String()},
                    new AttachmentSetting.StorageLocation {Name = Fixture.String(), Path = Fixture.String()}
                }.ToArray()
            });
            var r = await f.Subject.Resolve();
            Assert.Equal(3, r.StorageLocations.Length);
            for (int i = 0; i < r.StorageLocations.Length; i++)
            {
                Assert.NotNull(r.StorageLocations.Single(_ => _.StorageLocationId == i));
            }
        }

        [Fact]
        public async Task SaveAddsDefaultAllowedFileExtension()
        {
            var attachment = new AttachmentSetting()
            {
                StorageLocations = new List<AttachmentSetting.StorageLocation>()
                {
                    new AttachmentSetting.StorageLocation {Name = Fixture.String(), Path = Fixture.String(), CanUpload = true},
                    new AttachmentSetting.StorageLocation {Name = Fixture.String(), Path = Fixture.String(),AllowedFileExtensions = Fixture.String(), CanUpload = true},
                    new AttachmentSetting.StorageLocation {Name = Fixture.String(), Path = Fixture.String(), CanUpload = true}
                }.ToArray(),
                NetworkDrives = new List<AttachmentSetting.NetworkDrive>()
                {
                    new AttachmentSetting.NetworkDrive(){DriveLetter = "Z",UncPath = Fixture.String()}
                }.ToArray(),
                EnableDms = null
            };

            var input = JsonConvert.DeserializeObject<AttachmentSetting>(JsonConvert.SerializeObject(attachment));

            var f = new AttachmentSettingsFixture();
            await f.Subject.Save(input);

            foreach (var attachmentStorageLocation in attachment.StorageLocations)
            {
                if (string.IsNullOrEmpty(attachmentStorageLocation.AllowedFileExtensions))
                    attachmentStorageLocation.AllowedFileExtensions = "doc,docx,pdf,csv,xml,ppt,pptx,odt,ods,xls,xlsx,html";
            }

            f.ExternalSettings.Received(1).AddUpdate(KnownExternalSettings.Attachment, JsonConvert.SerializeObject(attachment, new JsonSerializerSettings
            {
                NullValueHandling = NullValueHandling.Ignore
            }))
             .IgnoreAwaitForNSubstituteAssertion();
        }

        class AttachmentSettingsFixture : IFixture<AttachmentSettings>
        {
            public AttachmentSettingsFixture()
            {
                ExternalSettings = Substitute.For<IExternalSettings>();
                Subject = new AttachmentSettings(ExternalSettings);
            }

            public AttachmentSettings Subject { get; }
            public IExternalSettings ExternalSettings { get; }
        }
    }
}