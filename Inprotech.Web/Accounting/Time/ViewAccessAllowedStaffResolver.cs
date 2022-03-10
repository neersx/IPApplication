using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Accounting.Time
{
    public interface IViewAccessAllowedStaffResolver
    {
        Task<IEnumerable<int>> Resolve();
    }

    public class ViewAccessAllowedStaffResolver : IViewAccessAllowedStaffResolver
    {
        readonly IFunctionSecurityProvider _functionSecurityProvider;
        readonly ISecurityContext _securityContext;

        public ViewAccessAllowedStaffResolver(ISecurityContext securityContext,
                                                       IFunctionSecurityProvider functionSecurityProvider)
        {
            _securityContext = securityContext;
            _functionSecurityProvider = functionSecurityProvider;
        }

        public async Task<IEnumerable<int>> Resolve()
        {
            var staff = _securityContext.User;

            var allowedStaffIds = (await _functionSecurityProvider.ForOthers(BusinessFunction.TimeRecording, staff))
                                  .Where(_ => _.CanRead).Select(_ => _.OwnerId).Distinct().ToArray();

            if (!allowedStaffIds.Any())
            {
                return new[] {staff.NameId};
            }

            if (allowedStaffIds.Any(_ => _ == null))
            {
                return Enumerable.Empty<int>();
            }

            return allowedStaffIds.Where(_ => _.HasValue)
                                  .Select(_ => _.Value)
                                  .Union(new[] {staff.NameId})
                                  .AsEnumerable();
        }
    }
}