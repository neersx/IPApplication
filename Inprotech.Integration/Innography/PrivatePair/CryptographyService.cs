using System.IO;
using System.Linq;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Encodings;
using Org.BouncyCastle.Crypto.Engines;
using Org.BouncyCastle.Crypto.Generators;
using Org.BouncyCastle.Crypto.Modes;
using Org.BouncyCastle.Crypto.Paddings;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.Crypto.Prng;
using Org.BouncyCastle.OpenSsl;
using Org.BouncyCastle.Security;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public interface ICryptographyService
    {
        KeySet GenerateRsaKeys(int rsaKeySize);
        KeySet GenerateRsaKeys(string privateKeyAsPEM);
        byte[] RSAEncrypt(byte[] clear, string publicKeyAsPem);
        byte[] RSADecrypt(byte[] encrypted, string privateKeyAsPEM);
        byte[] AESEncrypt(byte[] input, byte[] key, byte[] iv);
        byte[] AESDecrypt(byte[] input, byte[] key, byte[] iv);
    }

    /// <summary>
    ///     TODO: The intention is to review the location of this interface and class after the Extraction library is removed.
    /// </summary>
    public class CryptographyService : ICryptographyService
    {
        public KeySet GenerateRsaKeys(int rsaKeySize)
        {
            var generator = new RsaKeyPairGenerator();
            generator.Init(new KeyGenerationParameters(new SecureRandom(new CryptoApiRandomGenerator()), rsaKeySize));
            var keyPair = generator.GenerateKeyPair();
            return GenerateRsaKeys(keyPair);
        }

        public KeySet GenerateRsaKeys(string privateKeyAsPEM)
        {
            using (var sr = new StringReader(privateKeyAsPEM))
            {
                var keyPair = (AsymmetricCipherKeyPair) new PemReader(sr).ReadObject();
                return GenerateRsaKeys(keyPair);
            }
        }

        public byte[] RSAEncrypt(byte[] clear, string publicKeyAsPem)
        {
            var engine = new OaepEncoding(new RsaEngine());
            using (var sr = new StringReader(publicKeyAsPem))
            {
                var keyParameter = (AsymmetricKeyParameter) new PemReader(sr).ReadObject();
                engine.Init(true, keyParameter);
            }

            return engine.ProcessBlock(clear, 0, clear.Length);
        }

        public byte[] RSADecrypt(byte[] encrypted, string privateKeyAsPEM)
        {
            var engine = new OaepEncoding(new RsaEngine());
            using (var sr = new StringReader(privateKeyAsPEM))
            {
                var keyPair = (AsymmetricCipherKeyPair) new PemReader(sr).ReadObject();
                engine.Init(false, keyPair.Private);
            }

            return engine.ProcessBlock(encrypted, 0, encrypted.Length);
        }

        public byte[] AESEncrypt(byte[] input, byte[] key, byte[] iv)
        {
            var aes = new PaddedBufferedBlockCipher(new CbcBlockCipher(new AesEngine()));
            var ivAndKey = new ParametersWithIV(new KeyParameter(key), iv);
            aes.Init(true, ivAndKey);

            var outputBytes = new byte[aes.GetOutputSize(input.Length)];
            var length = aes.ProcessBytes(input, outputBytes, 0);
            aes.DoFinal(outputBytes, length);
            return outputBytes;
        }

        public byte[] AESDecrypt(byte[] input, byte[] key, byte[] iv)
        {
            var aes = new PaddedBufferedBlockCipher(new CbcBlockCipher(new AesEngine()));
            var ivAndKey = new ParametersWithIV(new KeyParameter(key), iv);
            aes.Init(false, ivAndKey);

            var outputBytes = new byte[aes.GetOutputSize(input.Length)];
            var length = aes.ProcessBytes(input, outputBytes, 0);
            length += aes.DoFinal(outputBytes, length);
            return outputBytes.Take(length).ToArray();
        }

        static KeySet GenerateRsaKeys(AsymmetricCipherKeyPair keyPair)
        {
            var keySet = new KeySet();
            using (var sw = new StringWriter())
            {
                var pemWriter = new PemWriter(sw);
                pemWriter.WriteObject(keyPair.Private);
                keySet.Private = sw.ToString();
            }

            using (var sw = new StringWriter())
            {
                var pemWriter = new PemWriter(sw);
                pemWriter.WriteObject(keyPair.Public);
                keySet.Public = sw.ToString();
            }

            return keySet;
        }
    }

    public class KeySet
    {
        public string Private { get; set; }

        public string Public { get; set; }
    }
}