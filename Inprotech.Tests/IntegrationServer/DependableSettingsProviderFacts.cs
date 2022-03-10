using System;
using Inprotech.Contracts;
using Inprotech.Integration.Settings;
using Inprotech.IntegrationServer;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer
{
    public class DependableSettingsProviderFacts
    {
        readonly IAppSettingsProvider _appSettingsProvider = Substitute.For<IAppSettingsProvider>();
        readonly GroupedConfigSettings _dependableSettings = Substitute.For<GroupedConfigSettings>();

        IDependableSettings CreateSubject()
        {
            return new DependableSettingsProvider(Settings, _appSettingsProvider);
        }

        GroupedConfigSettings Settings(string group)
        {
            return _dependableSettings;
        }

        [Fact]
        public void DatabaseValuesHasPriority()
        {
            var appSettingsRetryDelay = Fixture.Integer();
            var appSettingsRetryTimer = Fixture.Integer();
            var appSettingsRetryCount = Fixture.Integer();

            var persistedRetryDelay = Fixture.Integer();
            var persistedRetryTimer = Fixture.Integer();
            var persistedRetryCount = Fixture.Integer();

            _appSettingsProvider["RetryTimerInterval"].Returns($"{appSettingsRetryTimer}");

            _appSettingsProvider["RetryCount"].Returns($"{appSettingsRetryCount}");

            _appSettingsProvider["RetryDelay"].Returns($"{appSettingsRetryDelay}");

            _dependableSettings.GetValueOrDefault<double?>("RetryTimerInterval").Returns(persistedRetryTimer);

            _dependableSettings.GetValueOrDefault<int?>("RetryCount").Returns(persistedRetryCount);

            _dependableSettings.GetValueOrDefault<double?>("RetryDelay").Returns(persistedRetryDelay);

            var r = CreateSubject().GetSettings();

            Assert.Equal(TimeSpan.FromMinutes(persistedRetryDelay), r.DmsRetryDelay);
            Assert.Equal(TimeSpan.FromMinutes(persistedRetryDelay), r.RetryDelay);
            Assert.Equal(TimeSpan.FromMinutes(persistedRetryTimer), r.RetryTimerInterval);
            Assert.Equal(persistedRetryCount, r.RetryCount);
        }

        [Fact]
        public void ReturnValuesFromAppSettings()
        {
            var retryDelay = Fixture.Integer();
            var retryTimerInterval = Fixture.Integer();
            var retryCount = Fixture.Integer();

            _appSettingsProvider["RetryTimerInterval"].Returns($"{retryTimerInterval}");

            _appSettingsProvider["RetryCount"].Returns($"{retryCount}");

            _appSettingsProvider["RetryDelay"].Returns($"{retryDelay}");

            var r = CreateSubject().GetSettings();

            Assert.Equal(TimeSpan.FromMinutes(retryDelay), r.DmsRetryDelay);
            Assert.Equal(TimeSpan.FromMinutes(retryDelay), r.RetryDelay);
            Assert.Equal(TimeSpan.FromMinutes(retryTimerInterval), r.RetryTimerInterval);
            Assert.Equal(retryCount, r.RetryCount);
        }

        [Fact]
        public void ReturnValuesFromDatabase()
        {
            var retryDelay = Fixture.Integer();
            var retryTimerInterval = Fixture.Integer();
            var retryCount = Fixture.Integer();

            _dependableSettings.GetValueOrDefault<double?>("RetryTimerInterval").Returns(retryTimerInterval);

            _dependableSettings.GetValueOrDefault<int?>("RetryCount").Returns(retryCount);

            _dependableSettings.GetValueOrDefault<double?>("RetryDelay").Returns(retryDelay);

            var r = CreateSubject().GetSettings();

            Assert.Equal(TimeSpan.FromMinutes(retryDelay), r.DmsRetryDelay);
            Assert.Equal(TimeSpan.FromMinutes(retryDelay), r.RetryDelay);
            Assert.Equal(TimeSpan.FromMinutes(retryTimerInterval), r.RetryTimerInterval);
            Assert.Equal(retryCount, r.RetryCount);
        }
    }
}