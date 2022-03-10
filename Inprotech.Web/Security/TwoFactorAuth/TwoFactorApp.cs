using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Security;
using OtpNet;

namespace Inprotech.Web.Security.TwoFactorAuth
{
    public class TwoFactorApp : ITwoFactorAuth, ITwoFactorApp
    {
        const int Step = 30;
        readonly IUserTwoFactorAuthPreference _authPreference;
        readonly ITwoFactorTotp _twoFactorTotp;

        public TwoFactorApp(ITwoFactorTotp twoFactorTotp, IUserTwoFactorAuthPreference authPreference)
        {
            _twoFactorTotp = twoFactorTotp;
            _authPreference = authPreference;
        }

        public bool VerifyCode(string secretKey, string authenticationCode)
        {
            return _twoFactorTotp.OneTimePassword(Step, secretKey).VerifyTotp(authenticationCode, out _, new VerificationWindow(3, 1));
        }

#pragma warning disable 1998
        public async Task UserCredentialsValidated(User user)
#pragma warning restore 1998
        {
        }

        public async Task<bool> VerifyForUser(User user, string authenticationCode)
        {
            return VerifyCode(await _authPreference.ResolveAppSecretKey(user.Id), authenticationCode);
        }
    }

    public interface ITwoFactorApp
    {
        bool VerifyCode(string secretKey, string authenticationCode);
    }
}