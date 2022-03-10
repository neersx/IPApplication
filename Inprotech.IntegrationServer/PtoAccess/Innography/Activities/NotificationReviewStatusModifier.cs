using System;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Notifications;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Patents;
using Inprotech.IntegrationServer.PtoAccess.Innography.Model.Trademarks;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Activities
{
    public class NotificationReviewStatusModifier : ISourceNotificationModifier
    {
        readonly ISecurityContext _securityContext;

        public NotificationReviewStatusModifier(ISecurityContext securityContext)
        {
            _securityContext = securityContext;
        }

        public CaseNotification Modify(CaseNotification notification, object data)
        {
            var dataDownload = data as DataDownload;
            if (dataDownload == null) throw new ArgumentNullException(nameof(data));
            if (notification == null) throw new ArgumentNullException(nameof(notification));

            if (dataDownload.IsPatentsDataValidation())
            {
                var result = dataDownload.GetExtendedDetails<ValidationResult>();
                if (result.ApplicationDate.IsVerified() && result.ApplicationNumber.IsVerified()
                                                        && result.PublicationDate.IsVerified() && result.PublicationNumber.IsVerified()
                                                        && result.GrantDate.IsVerified() && result.GrantNumber.IsVerified())
                {
                    notification.IsReviewed = true;
                    notification.ReviewedBy = _securityContext.User.Id;
                }
            }
            else
            {
                var result = dataDownload.GetExtendedDetails<TrademarkDataValidationResult>();
                if (result.ApplicationDate.IsVerified(KnownPropertyTypes.TradeMark) && result.ApplicationNumber.IsVerified(KnownPropertyTypes.TradeMark)
                                                        && result.PublicationDate.IsVerified(KnownPropertyTypes.TradeMark) && result.PublicationNumber.IsVerified(KnownPropertyTypes.TradeMark)
                                                        && result.RegistrationDate.IsVerified(KnownPropertyTypes.TradeMark) && result.RegistrationNumber.IsVerified(KnownPropertyTypes.TradeMark))
                {
                    notification.IsReviewed = true;
                    notification.ReviewedBy = _securityContext.User.Id;
                }
            }

            return notification;
        }
    }
}