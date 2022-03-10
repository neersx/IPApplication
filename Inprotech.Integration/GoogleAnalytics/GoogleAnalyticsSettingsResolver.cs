using System;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Integration.Analytics;
using Inprotech.Integration.GoogleAnalytics.Parameters;

namespace Inprotech.Integration.GoogleAnalytics
{
    public interface IGoogleAnalyticsSettingsResolver
    {
        TrackingId Resolve();
        bool IsEnabled();
    }

    public class GoogleAnalyticsSettingsResolver : IGoogleAnalyticsSettingsResolver
    {
        const string GoogleAnalyticsTrackingId = "Inprotech.GoogleAnalytics.TrackingId";
        readonly Func<IProductImprovementSettingsResolver> _productImprovementSettingsFunc;
        readonly ICryptoService _cryptoService;
        readonly Func<IConfigSettings> _settingsFunc;
        bool _isEnabled;

        bool _resolved;
        TrackingId _trackingId;

        public GoogleAnalyticsSettingsResolver(Func<IConfigSettings> settingsFunc, Func<IProductImprovementSettingsResolver> productImprovementSettingsResolverFunc,
            ICryptoService cryptoService)
        {
            _settingsFunc = settingsFunc;
            _productImprovementSettingsFunc = productImprovementSettingsResolverFunc;
            _cryptoService = cryptoService;
        }

        public TrackingId Resolve()
        {
            ResolveInternal();

            return _trackingId;
        }

        public bool IsEnabled()
        {
            ResolveInternal();

            return _isEnabled;
        }

        void ResolveInternal()
        {
            if (_resolved) return;

            var trackingIdEncrypted = _settingsFunc().GetValueOrDefault<string>(GoogleAnalyticsTrackingId);
            var trackingId = string.IsNullOrEmpty(trackingIdEncrypted) ? null : _cryptoService.Decrypt(trackingIdEncrypted);

            _trackingId = string.IsNullOrEmpty(trackingId)
                ? null
                : new TrackingId(trackingId);

            _isEnabled = _trackingId != null && _productImprovementSettingsFunc().Resolve().FirmUsageStatisticsConsented;

            _resolved = true;
        }
    }
}