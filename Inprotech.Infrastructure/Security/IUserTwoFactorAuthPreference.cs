using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Security
{
    public interface IUserTwoFactorAuthPreference
    {
        Task<string> ResolvePreferredMethod(int userId);
        Task SetPreference(int userId, string preference);
        Task<string> ResolveEmailSecretKey(int userId);
        Task<string> ResolveAppSecretKey(int userId);
        Task SaveAppSecretKeyFromTemp(int userId);
        Task RemoveAppSecretKey(int userId);
        Task<string> ResolveAppTempSecretKey(int userId);
        Task<string> GenerateAppTempSecretKey(int userId);
    }
}
