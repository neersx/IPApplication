using System;
using System.Linq;
using System.Text;
using Inprotech.Integration.Innography.PrivatePair;
using Org.BouncyCastle.Crypto;
using Xunit;

namespace Inprotech.Tests.Integration.Innography.PrivatePair
{
    public class CryptographyServiceFacts
    {
        public class GenerateRsaKeyMethod
        {
            [Fact]
            public void ShouldGenerateFromPrivateKey()
            {
                var service = new CryptographyService();

                var keys1 = service.GenerateRsaKeys(512);
                var keys2 = service.GenerateRsaKeys(keys1.Private);

                Assert.Equal(keys2.Public, keys1.Public);
            }

            [Fact]
            public void ShouldGeneratePrivateKey()
            {
                var service = new CryptographyService();
                var keys = service.GenerateRsaKeys(512);

                Assert.NotNull(keys.Private);
            }

            [Fact]
            public void ShouldGeneratePublicKey()
            {
                var service = new CryptographyService();
                var keys = service.GenerateRsaKeys(512);

                Assert.NotNull(keys.Public);
            }
        }

        public static class RandomString
        {
            const string Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            static readonly Random Rng = new Random();

            public static string Next(int size)
            {
                var buffer = new char[size];

                for (var i = 0; i < size; i++)
                    buffer[i] = Chars[Rng.Next(Chars.Length)];

                return new string(buffer);
            }
        }

        public class MyScenario
        {
            [Fact]
            public void TestDecryption()
            {
                var content = string.Join(Environment.NewLine,
                                         Enumerable.Range(0, new Random().Next(2, 200))
                                        .Select(_ => RandomString.Next(new Random().Next(1, 200))));

                var keySet = new CryptographyService().GenerateRsaKeys(4096);

                var encrypted = EncryptUsingPublicKey(keySet.Public, content);

                var decryptedBytes = DecryptFileData(encrypted.EncryptedData, keySet.Private, encrypted.Decrypter, encrypted.IV);

                var decryptedContent = Encoding.Default.GetString(decryptedBytes);

                Assert.Equal(content, decryptedContent);
            }

            [Fact]
            public void ChangeInBiblioContentFailsTheDecryption()
            {
                var biblio = string.Join(Environment.NewLine,
                                          Enumerable.Range(0, new Random().Next(2, 200))
                                                    .Select(_ => RandomString.Next(new Random().Next(1, 200))));

                var keySet = new CryptographyService().GenerateRsaKeys(4096);
                var olderBiblioLink = EncryptUsingPublicKey(keySet.Public, biblio);

                biblio += Fixture.String();
                var newerBiblioLink = EncryptUsingPublicKey(keySet.Public, biblio);

                AssertNewerBiblioIsDecrypted();
                AssertOlderBiblioLinkThrowsException();

                void AssertNewerBiblioIsDecrypted()
                {
                    var decryptedBytes = DecryptFileData(newerBiblioLink.EncryptedData, keySet.Private, newerBiblioLink.Decrypter, newerBiblioLink.IV);
                    var decryptedContent = Encoding.Default.GetString(decryptedBytes);
                    Assert.Equal(biblio, decryptedContent);
                }

                void AssertOlderBiblioLinkThrowsException()
                {
                    Assert.Throws<InvalidCipherTextException>(() => DecryptFileData(newerBiblioLink.EncryptedData, keySet.Private, olderBiblioLink.Decrypter, olderBiblioLink.IV));
                }
            }

            (string IV, string Decrypter, byte[] EncryptedData) EncryptUsingPublicKey(string publicKey, string originalContent)
            {
                var crypto = new CryptographyService();

                var ivBytes = Encoding.ASCII.GetBytes(RandomString.Next(16));
                var decrypterBytes = Encoding.ASCII.GetBytes(RandomString.Next(32));

                var ivEncryptedBase64String = Convert.ToBase64String(crypto.RSAEncrypt(ivBytes, publicKey));
                var decrypterEncryptedBase64String = Convert.ToBase64String(crypto.RSAEncrypt(decrypterBytes, publicKey));

                var encrypted = crypto.AESEncrypt(Encoding.Default.GetBytes(originalContent), decrypterBytes, ivBytes);

                return (ivEncryptedBase64String, decrypterEncryptedBase64String, encrypted);
            }

            byte[] DecryptFileData(byte[] fileData, string privateKey, string key, string iv)
            {
                var crytoService = new CryptographyService();

                var keyBytes = Convert.FromBase64String(key);
                var ivBytes = Convert.FromBase64String(iv);
                var keyx = crytoService.RSADecrypt(keyBytes, privateKey);
                var ivx = crytoService.RSADecrypt(ivBytes, privateKey);

                return crytoService.AESDecrypt(fileData, keyx, ivx);
            }
        }
    }
}