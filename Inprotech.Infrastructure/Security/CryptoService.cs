using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;

namespace Inprotech.Infrastructure.Security
{
    public class CryptoService : ICryptoService
    {
        readonly byte[] _privateKey;
        readonly byte[] _legacyPassPhrase;

        public CryptoService(string privateKey)
        {
            _privateKey = Encoding.ASCII.GetBytes(privateKey);
        }

        public CryptoService(IAppSettingsProvider appSettingsProvider)
        {
            _privateKey = Encoding.ASCII.GetBytes(appSettingsProvider.GetPrivateKey());
            _legacyPassPhrase = Convert.FromBase64String(appSettingsProvider.GetPrivateKey(true));
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage",
            "CA2202:Do not dispose objects multiple times")]
        public string Encrypt(string plainText)
        {
            using(var cryptoProvider = new AesCryptoServiceProvider())
            using(var memoryStream = new MemoryStream())
            using(
                var cryptoStream = new CryptoStream(
                    memoryStream,
                    cryptoProvider.CreateEncryptor(_privateKey, _privateKey),
                    CryptoStreamMode.Write))
            using(var writer = new StreamWriter(cryptoStream))
            {
                writer.Write(plainText);
                writer.Flush();
                cryptoStream.FlushFinalBlock();
                writer.Flush();
                return Convert.ToBase64String(memoryStream.GetBuffer(), 0, (int)memoryStream.Length);
            }
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage",
            "CA2202:Do not dispose objects multiple times")]
        public string Decrypt(string cipherText, bool legacyMode = false)
        {
            return legacyMode
                ? LegacyDecryptor(cipherText)
                : CurrentDecryptor(cipherText);
        }

        string CurrentDecryptor(string cipherText)
        {
            using(var cryptoProvider = new AesCryptoServiceProvider())
            using(var memoryStream = new MemoryStream(Convert.FromBase64String(cipherText)))
            using(
                var decStream = new CryptoStream(
                                                 memoryStream,
                                                 cryptoProvider.CreateDecryptor(_privateKey, _privateKey),
                                                 CryptoStreamMode.Read))
            using(var reader = new StreamReader(decStream))
            {
                return reader.ReadToEnd();
            }
        }

        string LegacyDecryptor(string message)
        {
            if (TryDecryptWithAesAlgorithm(message, out byte[] results) || TryDecryptWithTripleDesAlgorithm(message, out results))
            {
                return Encoding.UTF8.GetString(results);
            }
            
            throw new CryptographicException("Unknown legacy cypher text");
        }

        bool TryDecryptWithAesAlgorithm(string message, out byte[] output)
        {
            using (var cryptoHashProvider = new SHA256CryptoServiceProvider())
            {
                var aesKey = cryptoHashProvider.ComputeHash(_legacyPassPhrase);
                using (var aesAlgorithm = new AesCryptoServiceProvider
                {
                    Key = aesKey,
                    Mode = CipherMode.ECB,
                    Padding = PaddingMode.PKCS7
                })
                {
                    var dataToDecrypt = Convert.FromBase64String(message);
                    try
                    {
                        var decryptor = aesAlgorithm.CreateDecryptor();
                        output = decryptor.TransformFinalBlock(dataToDecrypt, 0, dataToDecrypt.Length);
                        return true;
                    }
                    catch (Exception)
                    {
                        output = null;
                        return false;
                    }
                    finally
                    {
                        aesAlgorithm.Clear();
                        cryptoHashProvider.Clear();
                    }
                }
            }
        }

        bool TryDecryptWithTripleDesAlgorithm(string message, out byte[] output)
        {
            using (var hashProvider = new MD5CryptoServiceProvider())
            {
                var tdesKey = hashProvider.ComputeHash(_legacyPassPhrase);

                using (var tdesAlgorithm = new TripleDESCryptoServiceProvider
                {
                    Key = tdesKey,
                    Mode = CipherMode.ECB,
                    Padding = PaddingMode.PKCS7
                })
                {
                    var dataToDecrypt = Convert.FromBase64String(message);
                    try
                    {
                        var decryptor = tdesAlgorithm.CreateDecryptor();
                        output = decryptor.TransformFinalBlock(dataToDecrypt, 0, dataToDecrypt.Length);
                        return true;
                    }
                    catch (Exception)
                    {
                        output = null;
                        return false;
                    }
                    finally
                    {
                        tdesAlgorithm.Clear();
                        hashProvider.Clear();
                    }
                }
            }
        }
    }
}