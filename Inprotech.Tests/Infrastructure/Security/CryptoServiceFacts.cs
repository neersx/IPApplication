using Inprotech.Contracts;
using Inprotech.Infrastructure.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Security
{
    [Trait("Category", "Crypto")]
    public class CryptoServiceFacts
    {
        [Fact]
        public void CipherTextDoesNotMatchPlainText()
        {
            var f = new CryptoServiceFixture().WithPrivateKey();

            Assert.NotEqual(f.PlainText, f.Subject.Encrypt(f.PlainText));
        }

        [Fact]
        public void ShouldDecryptEncryptedText()
        {
            var f = new CryptoServiceFixture().WithPrivateKey();

            Assert.Equal(f.PlainText, f.Subject.Decrypt(f.Subject.Encrypt(f.PlainText)));
        }

        [Fact]
        public void ShouldEncryptBasedOnKey()
        {
            var f = new CryptoServiceFixture();

            var key1 = "supersecretkeyv1";
            var key2 = "v2supersecretkey";

            f.AppSettingsProvider["PrivateKey"].Returns(key1, key2);

            var result1 = f.Subject.Encrypt(f.PlainText);
            var result2 = f.Subject.Encrypt(f.PlainText);

            Assert.NotEqual(result1, result2);
        }
    }

    internal sealed class CryptoServiceFixture : IFixture<CryptoService>
    {
        public readonly IAppSettingsProvider AppSettingsProvider = Substitute.For<IAppSettingsProvider>();
        public readonly string PlainText = "encryptme";

        public CryptoService Subject => new CryptoService(AppSettingsProvider);

        public CryptoServiceFixture WithPrivateKey(string key = "XsupersecretkeyX")
        {
            AppSettingsProvider["PrivateKey"].Returns(key);
            return this;
        }
    }
}