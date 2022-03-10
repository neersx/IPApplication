using System.Configuration;
using Inprotech.Contracts;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Profiles;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration
{
    public class ExchangeIntegrationSettingsFacts
    {
        public class ResolveMethod : FactBase
        {
            readonly ICryptoService _crypto = Substitute.For<ICryptoService>();

            void SetupExternalSettings(string server, string userName, string password, bool isEnabled, string domain = "dev")
            {
                var settings = "{\"Server\": \"" + server + "\",\"Domain\": \"" + domain + "\",\"UserName\": \"" + userName + "\",\"Password\": \"" + password + "\",\"IsReminderEnabled\": \"" + isEnabled + "\"}";
                new ExternalSettings (KnownExternalSettings.ExchangeSetting) { Id = Fixture.Integer(), Settings = settings}.In(Db);
            }

            [Fact]
            public void DecryptsPassword()
            {
                SetupExternalSettings(Fixture.String(), Fixture.String(), Fixture.String(), true);
                new ExchangeIntegrationSettings(Db, _crypto).Resolve();
                _crypto.Received(1).Decrypt(Arg.Any<string>());
            }

            [Fact]
            public void ReturnsDefaultSettings()
            {
                SetupExternalSettings(null, null, null, false);
                var r = new ExchangeIntegrationSettings(Db, _crypto).Resolve();
                Assert.False(r.IsReminderEnabled);
                Assert.Null(r.UserName);
                Assert.Null(r.Password);
                Assert.Null(r.Domain);
                Assert.Null(r.Server);
            }

            [Fact]
            public void ReturnsSettingsFromDatabase()
            {
                var server = Fixture.String("https://");
                var userName = Fixture.String("user");
                var password = Fixture.String();

                SetupExternalSettings(server, userName, password, true);
                _crypto.Decrypt(Arg.Any<string>()).Returns(password);
                var r = new ExchangeIntegrationSettings(Db, _crypto).Resolve();

                Assert.True(r.IsReminderEnabled);
                Assert.Equal(userName, r.UserName);
                Assert.Equal(password, r.Password);
                Assert.Equal("dev", r.Domain);
                Assert.Equal(server, r.Server);
            }

            [Fact]
            public void ThrowsExceptionWhenPasswordIsNotSet()
            {
                var server = Fixture.String("https://");
                var userName = Fixture.String("user");
                var password = string.Empty;

                SetupExternalSettings(server, userName, password, true);
                _crypto.Decrypt(Arg.Any<string>()).Returns(password);
                Assert.Throws<ConfigurationErrorsException>(
                                                            () => { new ExchangeIntegrationSettings(Db, _crypto).Resolve(); }
                                                           );
            }

            [Fact]
            public void ThrowsExceptionWhenServerIsNotSet()
            {
                var server = string.Empty;
                var userName = Fixture.String("user");
                var password = Fixture.String();

                SetupExternalSettings(server, userName, password, true);
                _crypto.Decrypt(Arg.Any<string>()).Returns(password);
                Assert.Throws<ConfigurationErrorsException>(
                                                            () => { new ExchangeIntegrationSettings(Db, _crypto).Resolve(); }
                                                           );
            }

            [Fact]
            public void ThrowsExceptionWhenUserNameIsNotSet()
            {
                var server = Fixture.String("https://");
                var userName = string.Empty;
                var password = Fixture.String();

                SetupExternalSettings(server, userName, password, true);
                _crypto.Decrypt(Arg.Any<string>()).Returns(password);
                Assert.Throws<ConfigurationErrorsException>(
                                                            () => { new ExchangeIntegrationSettings(Db, _crypto).Resolve(); }
                                                           );
            }
        }
    }
}