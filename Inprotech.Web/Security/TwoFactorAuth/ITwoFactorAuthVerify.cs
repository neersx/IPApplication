using System.Threading.Tasks;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Security.TwoFactorAuth
{
    public interface ITwoFactorAuthVerify
    {
        Task<bool?> Verify(string authenticationMode, string authenticationCode, User user);
        Task UserCredentialsValidated(User user, string authenticationMode);
    }
}