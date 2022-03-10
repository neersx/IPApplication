using Inprotech.Integration.Notifications;

namespace Inprotech.IntegrationServer.PtoAccess
{
    public interface ISourceNotificationModifier
    {
        CaseNotification Modify(CaseNotification notification, object data);
    }
}