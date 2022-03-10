using OtpNet;

namespace Inprotech.Web.Security.TwoFactorAuth
{
    public class TwoFactorTotp : ITwoFactorTotp
    {
        public Totp OneTimePassword(int step, string key)
        {
            return new Totp(Base32Encoding.ToBytes(key), step);
        }
    }
}