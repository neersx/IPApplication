using Inprotech.Infrastructure;
using Xunit;

namespace Inprotech.Tests.Infrastructure
{
    public class AppSettingsProviderFacts
    {
        const string TestSettingKey = "testSetting";
        const string TestSettingValue = "testValue";
        const string PrivateKey = "PrivateKey";
        const string PrivateKeyValue = "privateKeyValue";
        const string NonExistantKey = "nonExistantKey";

        readonly AppSettingsProvider _subject = new AppSettingsProvider();

        [Fact]
        public void GetPrivateKeyShouldReturnPrivateKeyValue()
        {
            Assert.Equal(PrivateKeyValue, _subject[PrivateKey]);
        }

        [Fact]
        public void IndexerShouldReturnSettingValue()
        {
            Assert.Equal(TestSettingValue, _subject[TestSettingKey]);
        }

        [Fact]
        public void NonExistantSettingShouldReturnNull()
        {
            Assert.Null(_subject[NonExistantKey]);
        }

        [Fact]
        public void NullIndexerShouldReturnNull()
        {
            Assert.Null(_subject[null]);
        }
    }
}