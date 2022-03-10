using Inprotech.Contracts;
using Inprotech.Integration.Settings;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Settings
{
    public class TsdrIntegrationSettingsFacts
    {
        readonly ICryptoService _cryptoService = Substitute.For<ICryptoService>();
        readonly GroupedConfigSettings _groupedSettings = Substitute.For<GroupedConfigSettings>();

        TsdrIntegrationSettings CreateSubject()
        {
            return new TsdrIntegrationSettings(GroupedSettingsResolver, _cryptoService);
        }

        GroupedConfigSettings GroupedSettingsResolver(string s)
        {
            return _groupedSettings;
        }

        [Fact]
        public void GetsKeyAfterDecryption()
        {
            const string key = "some secret";

            _groupedSettings["ApiKey"].Returns("encryped value");
            _cryptoService.Decrypt(Arg.Any<string>()).Returns(key);

            var result = CreateSubject().Key;

            Assert.NotNull(_groupedSettings.Received(1)["ApiKey"]);
            _cryptoService.Received(1).Decrypt("encryped value");

            Assert.Equal(key, result);
        }

        [Fact]
        public void RefreshesKeys()
        {
            const string key = "some secret";

            _groupedSettings["ApiKey"].Returns("encryped value");
            _cryptoService.Decrypt(Arg.Any<string>()).Returns(key);

            var subject = CreateSubject();

            subject.RefreshKeys();

            Assert.NotNull(_groupedSettings.Received(1)["ApiKey"]);
            _cryptoService.Received(1).Decrypt("encryped value");

            Assert.Equal(key, subject.Key);
        }

        [Fact]
        public void SetsKeysAfterEncryption()
        {
            const string key = "some secret";

            var subject = CreateSubject();
            subject.Key = key;

            _cryptoService.Received(1).Encrypt(key);
        }
    }
}