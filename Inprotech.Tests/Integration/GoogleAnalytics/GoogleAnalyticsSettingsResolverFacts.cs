using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Integration.Analytics;
using Inprotech.Integration.GoogleAnalytics;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.GoogleAnalytics
{
    public class GoogleAnalyticsSettingsResolverFacts
    {
        GoogleAnalyticsSettingsResolver _f;
        IConfigSettings _settings;
        ICryptoService _cryptoService;
        ProductImprovementSettings _productImprovementSettings = new ProductImprovementSettings();

        public GoogleAnalyticsSettingsResolverFacts()
        {
            CreateSubject();
        }

        void CreateSubject()
        {
            _settings = Substitute.For<IConfigSettings>();
            _cryptoService = Substitute.For<ICryptoService>();
            var improvementSettingsResolver = Substitute.For<IProductImprovementSettingsResolver>();
            improvementSettingsResolver.Resolve().Returns(_productImprovementSettings);

            _f = new GoogleAnalyticsSettingsResolver(() => _settings, () => improvementSettingsResolver, _cryptoService);
        }

        void TrackingIdSetup(string trackingId)
        {
            var encrypted = "encrypted";
            _settings.GetValueOrDefault<string>("Inprotech.GoogleAnalytics.TrackingId").Returns(encrypted);
            _cryptoService.Decrypt(encrypted).Returns(trackingId);
        }

        [Fact]
        public void ShouldReturnNullTrackingIdIfIdNotFound()
        {
            _settings.GetValueOrDefault<string>("Inprotech.GoogleAnalytics.TrackingId").Returns(string.Empty);

            Assert.Null(_f.Resolve());
        }

        [Fact]
        public void ShouldReturnTrackingIdIfConfigured()
        {
            TrackingIdSetup("tracking-xyz");

            var t = _f.Resolve();

            Assert.NotNull(t);
            Assert.Equal("tracking-xyz", t.Value);
        }

        [Fact]
        public void ShouldReturnIsEnabledWhenTrackingIdIsAvailableAndFirmHasConsented()
        {
            _productImprovementSettings.FirmUsageStatisticsConsented = true;

            TrackingIdSetup("tracking-xyz");

            Assert.True(_f.IsEnabled());
        }

        [Fact]
        public void ShouldReturnNotEnabledIfTrackingIdIsNotAvailable()
        {
            _productImprovementSettings.FirmUsageStatisticsConsented = true;

            TrackingIdSetup(string.Empty);

            Assert.False(_f.IsEnabled());
        }

        [Fact]
        public void ShouldReturnNotEnabledIfFirmHasNotConsented()
        {
            _productImprovementSettings.FirmUsageStatisticsConsented = false;

            TrackingIdSetup("tracking-xyz");
            
            Assert.False(_f.IsEnabled());
        }
    }
}