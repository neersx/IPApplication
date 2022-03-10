using Inprotech.Contracts;
using Inprotech.Integration.Settings;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Settings
{
    public class EpoIntegrationSettingsFacts
    {
        [Fact]
        public void GetsKeysAfterDecryption()
        {
            var keys = new EpoKeys("somekey", "some secret");

            var fixture = new EpoIntegrationSettingsFixture();
            fixture.GroupedSettings["ConsumerKeys"].Returns("encryped value");
            fixture.CryptoService.Decrypt(Arg.Any<string>()).Returns(JsonConvert.SerializeObject(keys));

            var result = fixture.Subject.Keys;

            Assert.NotNull(fixture.GroupedSettings.Received(1)["ConsumerKeys"]);
            fixture.CryptoService.Received(1).Decrypt("encryped value");

            Assert.Equal(keys.ConsumerKey, result.ConsumerKey);
            Assert.Equal(keys.PrivateKey, result.PrivateKey);
        }

        [Fact]
        public void RefreshesKeys()
        {
            var keys = new EpoKeys("somekey", "some secret");

            var fixture = new EpoIntegrationSettingsFixture();
            fixture.GroupedSettings["ConsumerKeys"].Returns("encryped value");
            fixture.CryptoService.Decrypt(Arg.Any<string>()).Returns(JsonConvert.SerializeObject(keys));

            fixture.Subject.RefreshKeys();

            Assert.NotNull(fixture.GroupedSettings.Received(1)["ConsumerKeys"]);
            fixture.CryptoService.Received(1).Decrypt("encryped value");

            Assert.Equal(keys.ConsumerKey, fixture.Subject.Keys.ConsumerKey);
            Assert.Equal(keys.PrivateKey, fixture.Subject.Keys.PrivateKey);
        }

        [Fact]
        public void SetsKeysAfterEncryption()
        {
            var keys = new EpoKeys("somekey", "some secret");

            var fixture = new EpoIntegrationSettingsFixture();

            fixture.Subject.Keys = keys;

            fixture.CryptoService.Received(1).Encrypt(JsonConvert.SerializeObject(keys));
        }
    }

    internal class EpoIntegrationSettingsFixture : IFixture<EpoIntegrationSettings>
    {
        public ICryptoService CryptoService = Substitute.For<ICryptoService>();
        public GroupedConfigSettings GroupedSettings = Substitute.For<GroupedConfigSettings>();

        public EpoIntegrationSettings Subject => new EpoIntegrationSettings(GroupedSettingsResolver, CryptoService);

        GroupedConfigSettings GroupedSettingsResolver(string s)
        {
            return GroupedSettings;
        }
    }
}