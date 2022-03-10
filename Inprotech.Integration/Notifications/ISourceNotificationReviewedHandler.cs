using System.Threading.Tasks;

namespace Inprotech.Integration.Notifications
{
    public interface ISourceNotificationReviewedHandler
    {
        Task Handle(CaseNotification notification);
    }
}