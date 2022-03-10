namespace Inprotech.Infrastructure.Security
{
    public interface IIdentityBoundCryptoService
    {
        string Encrypt(string plainText);
        string Decrypt(string cypherText);
    }
}
