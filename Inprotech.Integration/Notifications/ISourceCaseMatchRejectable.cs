using System.Threading.Tasks;

namespace Inprotech.Integration.Notifications
{
    public interface ISourceCaseMatchRejectable
    {
        Task Reject(CaseNotification caseNotification);

        Task ReverseReject(CaseNotification caseNotification);
    }
}
