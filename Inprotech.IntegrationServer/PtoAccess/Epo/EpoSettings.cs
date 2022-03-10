using System;
using Inprotech.Contracts;
using Inprotech.Integration.Settings;

namespace Inprotech.IntegrationServer.PtoAccess.Epo
{
    public interface IEpoSettings
    {
        string EpoAuthUrl { get; }
        string EpoConsumerKey { get; }
        string EpoConsumerPrivateKey { get; }
        string EpoBaseUrl { get; }
        string EpoBaseApiUrl { get; }
    }

    public class EpoSettings : IEpoSettings
    {
        readonly IAppSettingsProvider _appSettingsProvider;
        readonly IEpoIntegrationSettings _epoIntegrationSettings;

        public EpoSettings(IAppSettingsProvider appSettingsProvider, IEpoIntegrationSettings epoIntegrationSettings )
        {
            _appSettingsProvider = appSettingsProvider;
            _epoIntegrationSettings = epoIntegrationSettings;
        }

        public string EpoAuthUrl => _appSettingsProvider["EpoAuthUrl"];

        public string EpoConsumerKey => _epoIntegrationSettings.Keys.ConsumerKey;

        public string EpoConsumerPrivateKey => _epoIntegrationSettings.Keys.PrivateKey;

        public string EpoBaseUrl => _appSettingsProvider["EpoBaseUrl"];

        public string EpoBaseApiUrl => _appSettingsProvider["EpoBaseApiUrl"];
    }

    public static class EpoSettingsExt
    {
        public static void EnsureRequiredKeysAvailable(this IEpoSettings epoSettings)
        {
            if (string.IsNullOrWhiteSpace(epoSettings.EpoConsumerKey) || string.IsNullOrWhiteSpace(epoSettings.EpoConsumerPrivateKey))
                throw new Exception("EPO scheduled download requires EpoConsumerKey and EpoConsumerPrivateKey provided by the EPO.");
        }
    }
}
