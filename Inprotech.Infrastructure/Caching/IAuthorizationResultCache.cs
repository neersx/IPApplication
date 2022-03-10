using Inprotech.Infrastructure.Security;

namespace Inprotech.Infrastructure.Caching
{
    public interface IAuthorizationResultCache : IDisableApplicationCache
    {
        bool IsEmpty { get; }

        void Clear();

        bool TryGetCaseAuthorizationResult(int userIdentityId, int caseId, AccessPermissionLevel minimumLevelRequested, out AuthorizationResult authorizationResult);

        bool TryGetNameAuthorizationResult(int userIdentityId, int nameId, AccessPermissionLevel minimumLevelRequested, out AuthorizationResult authorizationResult);

        bool TryAddCaseAuthorizationResult(int userIdentityId, int caseId, AccessPermissionLevel minimumLevelRequested, AuthorizationResult authorizationResult);

        bool TryAddNameAuthorizationResult(int userIdentityId, int nameId, AccessPermissionLevel minimumLevelRequested, AuthorizationResult authorizationResult);
    }
}
