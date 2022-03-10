using System.Collections.Generic;
using System.Threading.Tasks;

namespace Inprotech.Infrastructure.Security
{
    public interface INameAuthorization
    {
        Task<AuthorizationResult> Authorize(int nameId, AccessPermissionLevel requiredLevel);
        Task<IEnumerable<int>> AccessibleNames(params int[] nameIds);
        Task<IEnumerable<int>> UpdatableNames(params int[] nameIds);
    }
}