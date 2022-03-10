using System;
using System.Collections.Generic;
using Inprotech.Infrastructure;
using Inprotech.Integration.IPPlatform.FileApp;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp
{
    public class FileSettingsResolverFacts : FactBase
    {
        readonly IGroupedConfig _appSettings = Substitute.For<IGroupedConfig>();
        readonly ISiteControlReader _siteControlReader = Substitute.For<ISiteControlReader>();
        readonly IConfigurationSettings _configurationSettings = Substitute.For<IConfigurationSettings>();

        FileSettingsResolver CreateSubject()
        {
            return new FileSettingsResolver(Factory, _siteControlReader, _configurationSettings);
        }

        IGroupedConfig Factory(string any)
        {
            return _appSettings;
        }

        [Fact]
        public void ShouldDefaultDesignatedCountriesRelationship()
        {
            _appSettings.GetValues("AuthenticationMode")
                        .Returns(new Dictionary<string, string>
                        {
                            {"AuthenticationMode", "Sso"}
                        });

            var r = CreateSubject().Resolve();

            Assert.True(r.IsEnabled);
            Assert.Equal("DC1", r.DesignatedCountryRelationship);
        }

        [Fact]
        public void ShouldDefaultPriorityRelationshipIfNotFoundInSiteControl()
        {
            _appSettings.GetValues("AuthenticationMode")
                        .Returns(new Dictionary<string, string>
                        {
                            {"AuthenticationMode", "Sso"}
                        });

            _siteControlReader.Read<string>(SiteControls.EarliestPriority)
                              .Returns((string) null);

            var r = CreateSubject().Resolve();

            Assert.True(r.IsEnabled);
            Assert.Equal("BAS", r.EarliestPriorityRelationship);
        }

        [Fact]
        public void ShouldNotThrowExceptionIfEnabled()
        {
            var resolver = Substitute.For<IFileSettingsResolver>();
            resolver.Resolve().Returns(new FileSettings
            {
                IsEnabled = true
            });
            resolver.EnsureRequiredKeysAvailable();
        }

        [Fact]
        public void ShouldResolvePriorityRelationshipFromSiteControl()
        {
            _appSettings.GetValues("AuthenticationMode")
                        .Returns(new Dictionary<string, string>
                        {
                            {"AuthenticationMode", "Sso"}
                        });

            var earliestPriority = Fixture.String();

            _siteControlReader.Read<string>(SiteControls.EarliestPriority)
                              .Returns(earliestPriority);

            var r = CreateSubject().Resolve();

            Assert.True(r.IsEnabled);
            Assert.Equal(earliestPriority, r.EarliestPriorityRelationship);
        }

        [Fact]
        public void ShouldReturnEnabledWhenFileIntegrationEventIsSetAndSsoConfigured()
        {
            _appSettings.GetValues("AuthenticationMode")
                        .Returns(new Dictionary<string, string>
                        {
                            {"AuthenticationMode", "Sso"}
                        });

            _configurationSettings[KnownAppSettingsKeys.CpaApiUrl].Returns("staging_env");

            var fileIntegrationEvent = Fixture.Integer();

            _siteControlReader.Read<int?>(SiteControls.FILEIntegrationEvent)
                              .Returns(fileIntegrationEvent);

            var r = CreateSubject().Resolve();

            Assert.True(r.IsEnabled);
            Assert.Equal(fileIntegrationEvent, r.FileIntegrationEvent);
            Assert.Equal("staging_env/fapi/api/v1", r.ApiBase);
        }

        [Fact]
        public void ShouldReturnNotEnabledIfSsoNotConfigured()
        {
            _appSettings.GetValues("AuthenticationMode")
                        .Returns(new Dictionary<string, string>
                        {
                            {"AuthenticationMode", "Forms,Windows"}
                        });

            var r = CreateSubject().Resolve();

            Assert.False(r.IsEnabled);
        }

        [Fact]
        public void ShouldThrowExceptionIfNotEnabled()
        {
            Assert.Throws<Exception>(() =>
            {
                var resolver = Substitute.For<IFileSettingsResolver>();
                resolver.Resolve().Returns(new FileSettings());
                resolver.EnsureRequiredKeysAvailable();
            });
        }
    }
}