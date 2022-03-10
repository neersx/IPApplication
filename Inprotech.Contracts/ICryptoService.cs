namespace Inprotech.Contracts
{
    public interface ICryptoService
    {
        string Encrypt(string plainText);
        string Decrypt(string cipherText, bool legacyMode = false);
    }
}