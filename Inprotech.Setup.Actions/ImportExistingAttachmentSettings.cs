using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Serialization;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using Inprotech.Setup.Core.Utilities;
using Newtonsoft.Json;

namespace Inprotech.Setup.Actions
{
    public class ImportExistingAttachmentSettings : ISetupActionAsync
    {
        const string ProviderNameAttachment = "Attachment";

        readonly ICryptoService _cryptoService;
        readonly IIwsSettingHelper _iwsSettingHelper;

        public ImportExistingAttachmentSettings(ICryptoService cryptoService, IIwsSettingHelper iwsSettingHelper)
        {
            _cryptoService = cryptoService;
            _iwsSettingHelper = iwsSettingHelper;
        }

        public string Description => "Import Existing Attachment Settings";
        public bool ContinueOnException => true;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            RunAsync(context, eventStream).Wait();
        }

        public async Task RunAsync(IDictionary<string, object> context, IEventStream eventStream)
        {
            var connectionString = (string)context["InprotechAdministrationConnectionString"];
            var ctx = (SetupContext)context;
            var privateKey = ctx.PrivateKey;
            var configuredInWebConfig = _iwsSettingHelper.IsValidLocalAddress((string)context["IwsMachineName"]) || _iwsSettingHelper.IsValidLocalAddress((string)context["IwsAttachmentMachineName"]);

            await TryImport(connectionString, privateKey, eventStream, configuredInWebConfig);
        }

        async Task TryImport(string connectionString, string privateKey, IEventStream eventStream, bool configuredInWebConfig)
        {
            var hasExistingSetting = _iwsSettingHelper.HasExistingSetting(connectionString, ProviderNameAttachment);
            if (hasExistingSetting)
            {
                eventStream.PublishInformation("Configuration settings need not be imported as it already exists.");
                return;
            }

            if (!configuredInWebConfig)
            {
                eventStream.PublishInformation("Could not import as configuration settings of Attachment have not been configured.");
                return;
            }

            var encryptionKey = _iwsSettingHelper.GeneratePrivateKey();
            var result = await CommandLineUtility.RunAsync(Constants.MigrateIWSConfigSettings.MigrateUtilityPath,
                                                           "\"" + encryptionKey + "\" Attachment \"" + _iwsSettingHelper.ResolveInstallationLocation() + "\\\"");

            if (result.ExitCode == -1)
            {
                eventStream.PublishWarning("Configuration settings could not be imported, the service information could not be located.");
                return;
            }

            if (result.ExitCode == -9)
            {
                eventStream.PublishWarning("Configuration settings could not be imported due to unknown errors.");
                return;
            }

            var output = _cryptoService.Decrypt(encryptionKey, result.Output);

            if (string.IsNullOrWhiteSpace(output))
            {
                eventStream.PublishWarning("Configuration settings could not be imported either because there was no configuration.");
                return;
            }

            if (!IwsSettingParser.IsAttachmentSettingValid(output))
            {
                eventStream.PublishWarning("Configuration settings could not be imported either because there was no configuration, or the configuration was invalid.");
                return;
            }

            var attachmentSetting = IwsSettingParser.ParseAttachmentSetting(output);

            if (attachmentSetting.StorageLocations.Any() || attachmentSetting.NetworkDrives.Any())
            {
                var settingString = _cryptoService.Encrypt(privateKey, JsonConvert.SerializeObject(attachmentSetting));
                _iwsSettingHelper.SaveExternalSetting(connectionString, settingString, true, ProviderNameAttachment);
                eventStream.PublishInformation("The configuration settings for Attachment in windows services have been imported.");
            }
            else
            {
                eventStream.PublishInformation(Constants.MigrateIWSConfigSettings.MigrateUtilityPath + "\"" + encryptionKey + "\" Attachment \"" + _iwsSettingHelper.ResolveInstallationLocation() + "\\\"    " + "Could not import as configuration settings of Attachment have not been configured.");
            }
        }

        public class IwsSettingParser
        {
            public static bool IsAttachmentSettingValid(string output)
            {
                if (!string.IsNullOrWhiteSpace(output))
                {
                    using (var sr = new StringReader(output))
                    {
                        var serializer = new XmlSerializer(typeof(AttachmentSettingImported));
                        var config = serializer.Deserialize(sr) as AttachmentSettingImported;
                        if (config == null)
                        {
                            return false;
                        }

                        var networkDrivesValid = config.Networkdrives.Add?.All(_ => !string.IsNullOrEmpty(_.Driveletter) && !string.IsNullOrEmpty(_.Uncpath)) ?? true;
                        var storageLocationsValid = config.StorageLocations.Add?.All(_ => !string.IsNullOrEmpty(_.Name) && !string.IsNullOrEmpty(_.Path)) ?? true;
                        return networkDrivesValid && storageLocationsValid;
                    }
                }
                return false;
            }

            public static AttachmentSetting ParseAttachmentSetting(string output)
            {
                if (!string.IsNullOrWhiteSpace(output))
                {
                    using (var sr = new StringReader(output))
                    {
                        var serializer = new XmlSerializer(typeof(AttachmentSettingImported));
                        var config = serializer.Deserialize(sr) as AttachmentSettingImported;
                        if (config == null)
                        {
                            return new AttachmentSetting();
                        }

                        return new AttachmentSetting
                        {
                            NetworkDrives = ToNetworkDrives(config.Networkdrives),
                            StorageLocations = ToStorageLocations(config.StorageLocations, config.AllowedFileExtensions)
                        };
                    }
                }

                return new AttachmentSetting();
            }

            public static AttachmentSetting.NetworkDrive[] ToNetworkDrives(AttachmentSettingImported.NetworkDrives data)
            {
                if (data.Add?.Any() ?? false)
                {
                    return data.Add.Select(_ => new AttachmentSetting.NetworkDrive
                    {
                        DriveLetter = _.Driveletter,
                        UncPath = _.Uncpath
                    }).ToArray();
                }

                return new AttachmentSetting.NetworkDrive[0];
            }

            public static AttachmentSetting.StorageLocation[] ToStorageLocations(AttachmentSettingImported.StorageLocation data, string extensions)
            {
                if (data.Add?.Any() ?? false)
                {
                    return data.Add.Select(_ => new AttachmentSetting.StorageLocation
                    {
                        Name = _.Name,
                        Path = _.Path,
                        AllowedFileExtensions = extensions
                    }).ToArray();
                }

                return new AttachmentSetting.StorageLocation[0];
            }
        }

        public class AttachmentSetting
        {
            public AttachmentSetting()
            {
                IsRestricted = true;
                StorageLocations = new StorageLocation[0];
                NetworkDrives = new NetworkDrive[0];
            }

            public StorageLocation[] StorageLocations { get; set; }
            public NetworkDrive[] NetworkDrives { get; set; }
            public bool IsRestricted { get; set; }

            public class NetworkDrive
            {
                public string DriveLetter { get; set; }
                public string UncPath { get; set; }
            }

            public class StorageLocation
            {
                public string Name { get; set; }
                public string Path { get; set; }
                public string AllowedFileExtensions { get; set; }
            }
        }

        [XmlRoot("attachment")]
        public class AttachmentSettingImported
        {
            public AttachmentSettingImported()
            {
                IsRestricted = true;
                StorageLocations = new StorageLocation();
                Networkdrives = new NetworkDrives();
            }

            [XmlElement(ElementName = "storage-locations")]
            public StorageLocation StorageLocations { get; set; }

            [XmlElement(ElementName = "network-drives")]
            public NetworkDrives Networkdrives { get; set; }

            [XmlAttribute(AttributeName = "is-restricted")]
            public bool IsRestricted { get; set; }

            [XmlAttribute(AttributeName = "allowed-file-extensions")]
            public string AllowedFileExtensions { get; set; }

            public class NetworkDrives
            {
                [XmlElement(ElementName = "clear")]
                public string Clear { get; set; }

                [XmlElement(ElementName = "add")]
                public ElementAdd[] Add { get; set; }
            }

            public class ElementAdd
            {
                [XmlAttribute(AttributeName = "name")]
                public string Name { get; set; }

                [XmlAttribute(AttributeName = "path")]
                public string Path { get; set; }

                [XmlAttribute(AttributeName = "drive-letter")]
                public string Driveletter { get; set; }

                [XmlAttribute(AttributeName = "unc-path")]
                public string Uncpath { get; set; }
            }

            public class StorageLocation
            {
                [XmlElement(ElementName = "clear")]
                public string Clear { get; set; }

                [XmlElement(ElementName = "add")]
                public ElementAdd[] Add { get; set; }
            }
        }
    }
}