using System.Data.Entity;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Notifications
{
    public interface ISourceCaseRejection
    {
        Task<object> Reject(int notificationId);

        Task<object> ReverseRejection(int notificationId);

        Task<(bool CanReject, bool CanReverseReject)> CheckRejectability(int notificationId);
    }

    public class SourceCaseRejection : ISourceCaseRejection
    {
        readonly INotificationResponse _notificationResponse;
        readonly IRepository _repository;
        readonly IIndex<DataSourceType, ISourceCaseMatchRejectable> _sourceCaseRejectables;

        public SourceCaseRejection(IRepository repository,
                                   IIndex<DataSourceType, ISourceCaseMatchRejectable> sourceCaseRejectables,
                                   INotificationResponse notificationResponse)
        {
            _repository = repository;
            _sourceCaseRejectables = sourceCaseRejectables;
            _notificationResponse = notificationResponse;
        }

        public async Task<dynamic> Reject(int notificationId)
        {
            var cn = await GetNotificationAsync(notificationId);

            if (cn == null || cn.Type == CaseNotificateType.Error || cn.Type == CaseNotificateType.Rejected)
            {
                return new HttpResponseMessage(HttpStatusCode.BadRequest);
            }

            if (!_sourceCaseRejectables.TryGetValue(cn.Case.Source, out ISourceCaseMatchRejectable sourceMatch))
            {
                return new HttpResponseMessage(HttpStatusCode.BadRequest);
            }

            await sourceMatch.Reject(cn);

            cn.Type = CaseNotificateType.Rejected;

            _repository.SaveChanges();

            return await _notificationResponse.For(cn);
        }

        public async Task<object> ReverseRejection(int notificationId)
        {
            var cn = await GetNotificationAsync(notificationId);

            if (cn == null || cn.Type == CaseNotificateType.Error || cn.Type != CaseNotificateType.Rejected)
            {
                return new HttpResponseMessage(HttpStatusCode.BadRequest);
            }

            if (!_sourceCaseRejectables.TryGetValue(cn.Case.Source, out ISourceCaseMatchRejectable sourceMatch))
            {
                return new HttpResponseMessage(HttpStatusCode.BadRequest);
            }

            await sourceMatch.ReverseReject(cn);

            cn.Type = CaseNotificateType.CaseUpdated;
            cn.IsReviewed = false;
            cn.ReviewedBy = null;

            _repository.SaveChanges();

            return await _notificationResponse.For(cn);
        }

        public async Task<(bool CanReject, bool CanReverseReject)> CheckRejectability(int notificationId)
        {
            var cn = await GetNotificationAsync(notificationId);
            if (cn == null)
            {
                return (false, false);
            }

            // ReSharper disable once UnusedVariable
            var canReject = _sourceCaseRejectables.TryGetValue(cn.Case.Source, out ISourceCaseMatchRejectable sourceMatch);

            var canReverseReject = canReject && cn.Type == CaseNotificateType.Rejected;

            return (canReject, canReverseReject);
        }

        async Task<CaseNotification> GetNotificationAsync(int notificationId)
        {
            var notifications = _repository.Set<CaseNotification>();

            return await notifications
                .Include(_ => _.Case)
                .SingleOrDefaultAsync(_ => _.Id == notificationId);
        }
    }
}