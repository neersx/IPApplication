using OtpNet;

namespace Inprotech.Web.Security.TwoFactorAuth
{
    public interface ITwoFactorTotp
    {
        Totp OneTimePassword(int step, string key);
    }
}