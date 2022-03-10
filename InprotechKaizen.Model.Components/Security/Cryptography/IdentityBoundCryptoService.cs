using System;
using System.Text;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Security;

namespace InprotechKaizen.Model.Components.Security.Cryptography
{
    public class IdentityBoundCryptoService : IIdentityBoundCryptoService
    {
        readonly ISecurityContext _securityContext;
        readonly Func<string, ICryptoService> _cryptoServiceFunc;

        public IdentityBoundCryptoService(
            ISecurityContext securityContext)
        {
            _cryptoServiceFunc = x => new CryptoService((string) x);
            _securityContext = securityContext;
        }

        public string Encrypt(string plainText)
        {
            var service = GetService();
            return service.Encrypt(plainText);
        }

        public string Decrypt(string cypherText)
        {
            var service = GetService();
            return service.Decrypt(cypherText);
        }

        ICryptoService GetService()
        {
            return _cryptoServiceFunc(BuildKey());
        }

        string BuildKey()
        {
            var seed = $"^{_securityContext.User.UserName.Replace("\\", string.Empty)}^{_securityContext.User.Id}^".PadRight(8, '%');
            return Convert.ToBase64String(Encoding.ASCII.GetBytes(seed + seed)).Substring(0, 16);
        }
    }
}