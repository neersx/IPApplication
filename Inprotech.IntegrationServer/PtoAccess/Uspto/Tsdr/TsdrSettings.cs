using System;
using System.Xml.Linq;
using Inprotech.Contracts;
using Inprotech.Integration.Settings;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr
{
    public interface ITsdrSettings
    {
        string TsdrBaseUrl { get; }

        string TsdrBaseDocsUrl { get; }

        XNamespace TrademarkNs { get; }

        XNamespace CommonNs { get; }

        XNamespace DocsListNs { get; }

        TimeSpan Delay { get; }

        string ApiKey { get; }
    }

    public class TsdrSettings : ITsdrSettings
    {
        readonly IAppSettingsProvider _appSettingsProvider;
        readonly ITsdrIntegrationSettings _tsdrIntegrationSettings;

        public TsdrSettings(IAppSettingsProvider appSettingsProvider, ITsdrIntegrationSettings tsdrIntegrationSettings)
        {
            _appSettingsProvider = appSettingsProvider;
            _tsdrIntegrationSettings = tsdrIntegrationSettings;
        }

        public string TsdrBaseUrl => _appSettingsProvider["TsdrBaseUrl"];

        public string TsdrBaseDocsUrl => _appSettingsProvider["TsdrBaseDocUrl"];

        public XNamespace TrademarkNs => "http://www.wipo.int/standards/XMLSchema/ST96/Trademark";

        public XNamespace CommonNs => "http://www.wipo.int/standards/XMLSchema/ST96/Common";

        public XNamespace DocsListNs => "urn:us:gov:doc:uspto:trademark";

        public TimeSpan Delay => TimeSpan.FromSeconds(5);

        public string ApiKey => _tsdrIntegrationSettings.Key;
    }

    public static class TsdrSettingsExt
    {
        public static void EnsureRequiredKeysAvailable(this ITsdrSettings tsdrSettings)
        {
            if (string.IsNullOrWhiteSpace(tsdrSettings.ApiKey))
                throw new Exception("USPTO TSDR scheduled download requires API Key provided by the USPTO. Register for the API key from https://account.uspto.gov/api-manager");
        }
    }

}
