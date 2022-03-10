using System;
using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Security
{
    public interface IUserIdentityAccessManager
    {
        Task<(UserIdentityAccessData data, DateTime? lastExtension)> GetSigninData(long logId, int identityId, string authProvider);

        Task ExtendProviderSession(long logId, int identityId, string authProvider, UserIdentityAccessData data);

        long StartSession(int identityId, string authProvider, UserIdentityAccessData data, string application, string source);

        Task EndSession(long logId);

        Task EndSessionIfOpen(long logId);

        Task EndExpiredSessions();

        Task<bool> TryExtendProviderSession(long logId, int identityId, string authProvider, UserIdentityAccessData data, int defaultExtensionToleranceMinutes);
    }
}