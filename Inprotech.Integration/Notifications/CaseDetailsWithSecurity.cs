using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Inprotech.Integration.Notifications
{
    public interface ICaseDetailsWithSecurity
    {
        Task<IEnumerable<CaseNotificationResponse>> LoadCaseDetailsWithSecurityCheck(IQueryable<CaseNotification> items);
    }

    public class CaseDetailsWithSecurity : ICaseDetailsWithSecurity
    {
        readonly ICaseDetailsLoader _caseDetailsLoader;
        readonly INotificationResponse _notificationResponse;
        public CaseDetailsWithSecurity(ICaseDetailsLoader caseDetailsLoader, INotificationResponse notificationResponse)
        {
            _caseDetailsLoader = caseDetailsLoader;
            _notificationResponse = notificationResponse;
        }

        public async Task<IEnumerable<CaseNotificationResponse>> LoadCaseDetailsWithSecurityCheck(IQueryable<CaseNotification> items)
        {
            var n = _notificationResponse.For(items).ToArray();

            if (!n.Any())
            {
                return new CaseNotificationResponse[0];
            }

            var map = await _caseDetailsLoader.LoadCasesForNotifications(n);

            var result = new List<CaseNotificationResponse>();

            foreach (var itm in n)
            {
                if (!map.ContainsKey(itm.NotificationId))
                {
                    result.Add(itm);
                    continue;
                }

                var c = map[itm.NotificationId];
                if (!c.HasPermission)
                {
                    itm.CaseId = null;
                    continue;
                }

                itm.CaseRef = c.CaseRef;
                itm.CaseId = c.CaseId;

                result.Add(itm);
            }

            return result;
        }
    }
}
