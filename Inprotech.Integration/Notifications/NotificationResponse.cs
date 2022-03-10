using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Integration.Notifications
{
    public interface INotificationResponse
    {
        IEnumerable<CaseNotificationResponse> For(IEnumerable<CaseNotification> notifications);
        Task<CaseNotificationResponse> For(CaseNotification notification);
    }

    public class NotificationResponse : INotificationResponse
    {
        readonly IDbContext _dbContext;

        public NotificationResponse(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<CaseNotificationResponse> For(CaseNotification notification)
        {
            if (notification == null) throw new ArgumentNullException(nameof(notification));

            var r = new CaseNotificationResponse(notification, NotificationTitle(notification), NotificationBody(notification));

            if (r.CaseId.HasValue)
            {
                r.CaseRef = (await _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                                             .Select(_ => new
                                                          {
                                                              _.Id,
                                                              _.Irn
                                                          })
                                             .SingleAsync(_ => _.Id == r.CaseId)).Irn;
            }

            return r;
        }
        
        public IEnumerable<CaseNotificationResponse> For(IEnumerable<CaseNotification> notifications)
        {
            if (notifications == null) throw new ArgumentNullException(nameof(notifications));

            return notifications.Select(n => new CaseNotificationResponse(n, NotificationTitle(n), NotificationBody(n)));
        }

        static string NotificationTitle(CaseNotification caseNotification)
        {
            if (caseNotification.Type == CaseNotificateType.CaseUpdated)
                return caseNotification.Body;
            
            if (caseNotification.Type == CaseNotificateType.Rejected)
                return caseNotification.Body;

            if (caseNotification.Type == CaseNotificateType.Error)
                return "Error";

            throw new NotSupportedException($"Could not generate the title for notification type {caseNotification.Type}");
        }

        static object NotificationBody(CaseNotification caseNotification)
        {
            if (caseNotification.Type == CaseNotificateType.CaseUpdated)
                return new object();
            
            if (caseNotification.Type == CaseNotificateType.Rejected)
                return new object();

            if (caseNotification.Type == CaseNotificateType.Error)
                return JsonConvert.DeserializeObject(caseNotification.Body);

            throw new NotSupportedException($"Could not generate the body for notification type {caseNotification.Type}");
        }
    }
}