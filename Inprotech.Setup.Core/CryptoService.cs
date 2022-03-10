using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace Inprotech.Setup.Core
{
    public interface ICryptoService
    {
        string Encrypt(string privateKey, string text);
        string Decrypt(string privateKey, string text);
        string TryDecrypt(string privateKey, string text);
        void Encrypt(string privateKey, AdfsSettings adfsSettings);
        void Decrypt(string privateKey, AdfsSettings adfsSettings);
        void Encrypt(string privateKey, IpPlatformSettings ipPlatformSettings);
        void Decrypt(string privateKey, IpPlatformSettings ipPlatformSettings);
    }
    public class CryptoService : ICryptoService
    {
        byte[] _privateKey;

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage",
            "CA2202:Do not dispose objects multiple times")]
        string Encrypt(string plainText)
        {
            if (plainText == null) return null;
            using (var cryptoProvider = new AesCryptoServiceProvider())
            using (var memoryStream = new MemoryStream())
            using (
                var cryptoStream = new CryptoStream(
                                                    memoryStream,
                                                    cryptoProvider.CreateEncryptor(_privateKey, _privateKey),
                                                    CryptoStreamMode.Write))
            using (var writer = new StreamWriter(cryptoStream))
            {
                writer.Write(plainText);
                writer.Flush();
                cryptoStream.FlushFinalBlock();
                writer.Flush();
                return Convert.ToBase64String(memoryStream.GetBuffer(), 0, (int)memoryStream.Length);
            }
        }

        public string Decrypt(string privateKey, string cipherText)
        {
            var pKey = Encoding.ASCII.GetBytes(privateKey);
            if (cipherText == null) return null;
            using (var cryptoProvider = new AesCryptoServiceProvider())
            using (var memoryStream = new MemoryStream(Convert.FromBase64String(cipherText)))
            using (
                var decStream = new CryptoStream(
                                                 memoryStream,
                                                 cryptoProvider.CreateDecryptor(pKey, pKey),
                                                 CryptoStreamMode.Read))
            using (var reader = new StreamReader(decStream))
            {
                return reader.ReadToEnd();
            }
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage",
            "CA2202:Do not dispose objects multiple times")]
        string Decrypt(string cipherText)
        {
            if (cipherText == null) return null;
            using (var cryptoProvider = new AesCryptoServiceProvider())
            using (var memoryStream = new MemoryStream(Convert.FromBase64String(cipherText)))
            using (
                var decStream = new CryptoStream(
                                                 memoryStream,
                                                 cryptoProvider.CreateDecryptor(_privateKey, _privateKey),
                                                 CryptoStreamMode.Read))
            using (var reader = new StreamReader(decStream))
            {
                return reader.ReadToEnd();
            }
        }

        public string Encrypt(string privateKey, string text)
        {
            if (string.IsNullOrEmpty(privateKey) || string.IsNullOrWhiteSpace(text))
                return text;
            SetPrivateKey(privateKey);

            return Encrypt(text);
        }

        public string TryDecrypt(string privateKey, string text)
        {
            if (string.IsNullOrEmpty(privateKey) || string.IsNullOrWhiteSpace(text))
            {
                return text;
            }

            SetPrivateKey(privateKey);

            try
            {
                return Decrypt(text);
            }
            catch (FormatException)
            {
                // The text supplied was not encrypted, return the same text back
                return text;
            }
        }

        public void Encrypt(string privateKey, AdfsSettings adfsSettings)
        {
            if (string.IsNullOrEmpty(privateKey) || adfsSettings == null)
                return;
            SetPrivateKey(privateKey);
            adfsSettings.ClientId = Encrypt(adfsSettings.ClientId);
            adfsSettings.RelyingPartyTrustId = Encrypt(adfsSettings.RelyingPartyTrustId);
            adfsSettings.Certificate = Encrypt(adfsSettings.Certificate);
        }

        public void Decrypt(string privateKey, AdfsSettings adfsSettings)
        {
            if (string.IsNullOrEmpty(privateKey) || adfsSettings == null)
                return;
            SetPrivateKey(privateKey);
            adfsSettings.ClientId = Decrypt(adfsSettings.ClientId);
            adfsSettings.RelyingPartyTrustId = Decrypt(adfsSettings.RelyingPartyTrustId);
            adfsSettings.Certificate = Decrypt(adfsSettings.Certificate);
        }

        public void Encrypt(string privateKey, IpPlatformSettings ipPlatformSettings)
        {
            if (string.IsNullOrEmpty(privateKey) || ipPlatformSettings == null)
                return;
            SetPrivateKey(privateKey);
            ipPlatformSettings.ClientId = Encrypt(ipPlatformSettings.ClientId);
            ipPlatformSettings.ClientSecret = Encrypt(ipPlatformSettings.ClientSecret);
        }

        public void Decrypt(string privateKey, IpPlatformSettings ipPlatformSettings)
        {
            if (string.IsNullOrEmpty(privateKey) || ipPlatformSettings == null)
                return;
            SetPrivateKey(privateKey);
            ipPlatformSettings.ClientId = Decrypt(ipPlatformSettings.ClientId);
            ipPlatformSettings.ClientSecret = Decrypt(ipPlatformSettings.ClientSecret);
        }

        void SetPrivateKey(string privateKey)
        {
            _privateKey = Encoding.ASCII.GetBytes(privateKey);
        }
    }
}