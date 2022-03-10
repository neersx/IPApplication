using System.Threading.Tasks;
using Autofac.Features.Indexed;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Security.TwoFactorAuth
{
    public class TwoFactorAuthVerify : ITwoFactorAuthVerify
    {
        public const string Email = "email";
        public const string App = "app";
        readonly IIndex<string, ITwoFactorAuth> _twoFactorVerifyIndex;
        public TwoFactorAuthVerify(IIndex<string, ITwoFactorAuth> twoFactorVerifyIndex)
        {
            _twoFactorVerifyIndex = twoFactorVerifyIndex;
        }
        
        public async Task<bool?> Verify(string authenticationMode, string authenticationCode, User user)
        {
            if (!string.IsNullOrWhiteSpace(authenticationMode) && !string.IsNullOrWhiteSpace(authenticationCode) && 
                _twoFactorVerifyIndex.TryGetValue(authenticationMode, out ITwoFactorAuth handler))
            {
                return await handler.VerifyForUser(user, authenticationCode.Trim());
            }

            return null;
        }

        public async Task UserCredentialsValidated(User user, string authenticationMode)
        {
            if (_twoFactorVerifyIndex.TryGetValue(authenticationMode, out ITwoFactorAuth handler))
                await handler.UserCredentialsValidated(user);
        }
    }
}