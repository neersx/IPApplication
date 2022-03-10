using System.Collections.Generic;
using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Security
{
    public interface ICaseAuthorization
    {
        Task<AuthorizationResult> Authorize(int caseId, AccessPermissionLevel requiredLevel);

        Task<IDictionary<int, AccessPermissionLevel>> GetInternalUserAccessPermissions(IEnumerable<int> caseIds, int? userIdentityId = null);

        Task<IEnumerable<int>> AccessibleCases(params int[] caseIds);

        Task<IEnumerable<int>> UpdatableCases(params int[] caseIds);
    }
}