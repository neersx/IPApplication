using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.System.Settings;
using Newtonsoft.Json;

namespace Inprotech.Web.Configuration.Attachments
{
    public interface IAttachmentSettings
    {
        Task<AttachmentSetting> Resolve();
        Task Save(AttachmentSetting settings);
    }

    public class AttachmentSettings : IAttachmentSettings
    {
        const string DefaultFileExtensions = "doc,docx,pdf,csv,xml,ppt,pptx,odt,ods,xls,xlsx,html";
        readonly IExternalSettings _externalSettings;

        public AttachmentSettings(IExternalSettings externalSettings)
        {
            _externalSettings = externalSettings;
        }

        public async Task<AttachmentSetting> Resolve()
        {
            var settings = await _externalSettings.Resolve<AttachmentSetting>(KnownExternalSettings.Attachment) ?? new AttachmentSetting();
            foreach (var sl in settings.StorageLocations)
            {
                if (!sl.CanUpload.HasValue)
                {
                    sl.CanUpload = true;
                }
            }

            AddIdTemp(settings);
            return settings;
        }

        public async Task Save(AttachmentSetting settings)
        {
            AddDefaultFileTypesIfRequired(settings);
            var json = JsonConvert.SerializeObject(settings, Formatting.None, new JsonSerializerSettings {NullValueHandling = NullValueHandling.Ignore});
            await _externalSettings.AddUpdate(KnownExternalSettings.Attachment, json);
        }

        //Todo Remove this after grid is fixed
        void AddIdTemp(AttachmentSetting settings)
        {
            var index = -1;
            foreach (var settingsNameType in settings.StorageLocations) settingsNameType.StorageLocationId = ++index;

            index = -1;
            foreach (var settingsNameType in settings.NetworkDrives) settingsNameType.NetworkDriveMappingId = ++index;
        }

        void AddDefaultFileTypesIfRequired(AttachmentSetting settings)
        {
            if (settings.StorageLocations?.Any() == true)
            {
                foreach (var storageLocation in settings.StorageLocations)
                {
                    if (string.IsNullOrEmpty(storageLocation.AllowedFileExtensions))
                    {
                        storageLocation.AllowedFileExtensions = DefaultFileExtensions;
                    }
                }
            }
        }
    }

    public class AttachmentSetting
    {
        public AttachmentSetting()
        {
            IsRestricted = true;
            StorageLocations = new StorageLocation[0];
            NetworkDrives = new NetworkDrive[0];
            EnableBrowseButton = true;
        }

        public StorageLocation[] StorageLocations { get; set; }
        public NetworkDrive[] NetworkDrives { get; set; }
        public bool IsRestricted { get; set; }
        public bool? EnableDms { get; set; }
        public bool EnableBrowseButton { get; set; }

        public string GetMappedNetworkPath(string path)
        {
            if (char.IsLetter(path, 0) && path.IndexOf(@":\", StringComparison.Ordinal) >= 1 && NetworkDrives.Any())
            {
                var pathRoot = Path.GetPathRoot(path);
                var mappedRoot = NetworkDrives.SingleOrDefault(_ => _.DriveLetter.ToUpperInvariant() == pathRoot[0].ToString().ToUpperInvariant())?.UncPath;

                return string.IsNullOrWhiteSpace(mappedRoot) ? path : string.Concat(mappedRoot, mappedRoot.Substring(mappedRoot.Length - 1) == @"\" ? string.Empty : @"\", path.Length > 3 ? path.Substring(3) : string.Empty);
            }

            return path;
        }

        public StorageLocation GetStorageLocation(string path)
        {
            var storageLocation = StorageLocations.SingleOrDefault(_ => path.ToLowerInvariant().IndexOf(_.Path.ToLowerInvariant(), StringComparison.Ordinal) == 0);
            return storageLocation ?? StorageLocations.SingleOrDefault(sl => path.ToLowerInvariant().IndexOf(GetMappedNetworkPath(sl.Path).ToLowerInvariant(), StringComparison.Ordinal) == 0);
        }

        public class NetworkDrive
        {
            public int NetworkDriveMappingId { get; set; }
            public string DriveLetter { get; set; }
            public string UncPath { get; set; }
        }

        public class StorageLocation
        {
            public string Name { get; set; }
            public string Path { get; set; }
            public string AllowedFileExtensions { get; set; }
            public int StorageLocationId { get; set; }
            public bool? CanUpload { get; set; }

            public bool IsExtensionAllowed(string extension)
            {
                return AllowedFileExtensions.Split(',').Any(_ => _.ToLowerInvariant().Equals(extension.ToLowerInvariant().Replace(".", string.Empty)));
            }
        }
    }
}