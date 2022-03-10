using Newtonsoft.Json;

namespace Inprotech.Tests.Integration.Utils
{
    public static class CryptoService
    {
        //TODO: Use Key from Runner's config
        const string Key = "j71GprPi37JZnM6v";
        public static string Encrypt<T>(T obj) => Encrypt(JsonConvert.SerializeObject(obj));
        public static string Encrypt(string plainText) => Service.Encrypt(plainText);

        public static T Decrypt<T>(string cipherText, bool legacyMode = false) => JsonConvert.DeserializeObject<T>(Decrypt(cipherText, legacyMode));
        public static string Decrypt(string cipherText, bool legacyMode = false) => Service.Decrypt(cipherText, legacyMode);

        static Infrastructure.Security.CryptoService Service => new Infrastructure.Security.CryptoService(Key);
    }
}