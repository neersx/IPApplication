using System.Threading.Tasks;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Security.TwoFactorAuth
{
    public interface ITwoFactorAuth
    {
        Task UserCredentialsValidated(User user);
        Task<bool> VerifyForUser(User user, string authenticationCode);
    }
}