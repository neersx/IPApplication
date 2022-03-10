using System;

namespace Inprotech.Integration.Settings
{
    public interface IDmsIntegrationSettings
    {
        string PrivatePairLocation { get; set; }
        string TsdrLocation { get; set; }
        bool PrivatePairIntegrationEnabled { get; set; }
        bool TsdrIntegrationEnabled { get; set; }
        string PrivatePairFilename { get; set; }
        string TsdrFilename { get; set; }

        bool IsEnabledFor(DataSourceType dataSourceType);
        string GetLocationFor(DataSourceType dataSourceType);
        string GetFilenameFor(DataSourceType dataSourceType);
        void SetEnabledFor(DataSourceType dataSourceType, bool enabled);
        void SetLocationFor(DataSourceType dataSourceType, string location);
    }

    public class DmsIntegrationSettings : IDmsIntegrationSettings
    {
        const string SettingsGroup = "DmsIntegration";
        const string PrivatePairLocationKey = "PrivatePairLocation";
        const string PrivatePairIntegrationEnabledKey = "PrivatePairIntegrationEnabled";
        const string TsdrLocationKey = "TsdrLocation";
        const string TsdrIntegrationEnabledKey = "TsdrIntegrationEnabled";
        const string PrivatePairFilenameKey = "PrivatePairFilenameFormat";
        const string TsdrFilenameKey = "TsdrFilenameFormat";

        readonly GroupedConfigSettings _settings;

        public string PrivatePairLocation
        {
            get => _settings[PrivatePairLocationKey];
            set => _settings[PrivatePairLocationKey] = value;
        }

        public string TsdrLocation
        {
            get => _settings[TsdrLocationKey];
            set => _settings[TsdrLocationKey] = value;
        }

        public bool PrivatePairIntegrationEnabled
        {
            get => _settings.GetValueOrDefault(PrivatePairIntegrationEnabledKey, false);
            set => _settings.SetValue(PrivatePairIntegrationEnabledKey, value);
        }

        public bool TsdrIntegrationEnabled
        {
            get => _settings.GetValueOrDefault(TsdrIntegrationEnabledKey, false);
            set => _settings.SetValue(TsdrIntegrationEnabledKey, value);
        }

        public bool IsEnabledFor(DataSourceType dataSourceType)
        {
            switch (dataSourceType)
            {
                case DataSourceType.UsptoPrivatePair:
                    return PrivatePairIntegrationEnabled;
                case DataSourceType.UsptoTsdr:
                    return TsdrIntegrationEnabled;
                case DataSourceType.Epo:
                    return false;
                case DataSourceType.IpOneData:
                    return false;
                case DataSourceType.File:
                    return false;
                default:
                    throw new InvalidOperationException("Unknown data source type");
            }
        }

        public string GetLocationFor(DataSourceType dataSourceType)
        {
            switch (dataSourceType)
            {
                case DataSourceType.UsptoPrivatePair:
                    return PrivatePairLocation;
                case DataSourceType.UsptoTsdr:
                    return TsdrLocation;
                default:
                    throw new InvalidOperationException("Unknown data source type");
            }
        }

        public string GetFilenameFor(DataSourceType dataSourceType)
        {
            switch (dataSourceType)
            {
                case DataSourceType.UsptoPrivatePair:
                    return PrivatePairFilename;
                case DataSourceType.UsptoTsdr:
                    return TsdrFilename;
                default:
                    throw new InvalidOperationException("Unknown data source type");
            }
        }

        public void SetEnabledFor(DataSourceType dataSourceType, bool enabled)
        {
            switch (dataSourceType)
            {
                case DataSourceType.UsptoPrivatePair:
                    PrivatePairIntegrationEnabled = enabled;
                    break;
                case DataSourceType.UsptoTsdr:
                    TsdrIntegrationEnabled = enabled;
                    break;
                default:
                    throw new InvalidOperationException("Unknown data source type");
            }
        }

        public void SetLocationFor(DataSourceType dataSourceType, string location)
        {
            switch (dataSourceType)
            {
                case DataSourceType.UsptoPrivatePair:
                    PrivatePairLocation = location;
                    break;
                case DataSourceType.UsptoTsdr:
                    TsdrLocation = location;
                    break;
                default:
                    throw new InvalidOperationException("Unknown data source type");
            }
        }

        public string PrivatePairFilename
        {
            get => _settings[PrivatePairFilenameKey];
            set => _settings[PrivatePairFilenameKey] = value;
        }

        public string TsdrFilename
        {
            get => _settings[TsdrFilenameKey];
            set => _settings[TsdrFilenameKey] = value;
        }

        public DmsIntegrationSettings(GroupedConfigSettings.Factory groupedSettingsResolver)
        {
            if (groupedSettingsResolver == null) throw new ArgumentNullException(nameof(groupedSettingsResolver));
            _settings = groupedSettingsResolver(SettingsGroup);
        }
    }
}