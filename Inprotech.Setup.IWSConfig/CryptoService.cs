using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace Inprotech.Setup.IWSConfig
{
    public interface ICryptoService
    {
        string Encrypt(string privateKey, string text);
    }
    public class CryptoService : ICryptoService
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage",
            "CA2202:Do not dispose objects multiple times")]
        public string Encrypt(string privateKey, string plainText)
        {
            var pKey = Encoding.ASCII.GetBytes(privateKey);
            if (plainText == null) return null;
            using (var cryptoProvider = new AesCryptoServiceProvider())
            using (var memoryStream = new MemoryStream())
            using (var cryptoStream = new CryptoStream(
                                                    memoryStream,
                                                    cryptoProvider.CreateEncryptor(pKey, pKey),
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
    }
}