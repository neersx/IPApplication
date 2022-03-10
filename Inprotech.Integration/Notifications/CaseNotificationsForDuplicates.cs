using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;

namespace Inprotech.Integration.Notifications
{
    public interface ICaseNotificationsForDuplicates
    {
        Task<CaseNotificationResponse[]> FetchDuplicatesFor(DataSourceType dataSourceType, int forId);
    }

    public class CaseNotificationsForDuplicates : ICaseNotificationsForDuplicates
    {
        readonly IIndex<DataSourceType, IDuplicateCasesFinder> _duplicateCasesFinders;
        readonly INotificationResponse _notificationResponse;
        readonly IRequestedCases _requestedCases;

        public CaseNotificationsForDuplicates(IIndex<DataSourceType, IDuplicateCasesFinder> duplicateCasesFinders, IRequestedCases requestedCases, INotificationResponse notificationResponse)
        {
            _duplicateCasesFinders = duplicateCasesFinders;
            _requestedCases = requestedCases;
            _notificationResponse = notificationResponse;
        }

        public async Task<CaseNotificationResponse[]> FetchDuplicatesFor(DataSourceType dataSourceType, int forId)
        {
            IDuplicateCasesFinder finder;
            if (!_duplicateCasesFinders.TryGetValue(dataSourceType, out finder))
            {
                throw new NotImplementedException();
            }
            var caseIds = (await finder.FindFor(forId)).Select(_ => _.ToString()).ToArray();

            var notifications = await _requestedCases.LoadNotifications(caseIds, new[]{dataSourceType});

            var result = new List<CaseNotificationResponse>();
            foreach (var n in _notificationResponse.For(notifications.Keys))
            {
                var c = notifications.Single(_ => _.Key.Id == n.NotificationId);
                n.CaseRef = c.Value.Irn;
                n.CaseId = c.Value.Id;
                result.Add(n);
            }
            return result.ToArray();
        }
    }
}