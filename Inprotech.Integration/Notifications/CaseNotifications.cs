using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Integration.Notifications
{
    public interface ICaseNotifications
    {
        Task<IDictionary<DataSourceType, int>> CountByDataSourceType();

        IQueryable<CaseNotification> ThatSatisfies(SearchParameters searchParameters);

        Task MarkReviewed(int notificationid);

        IQueryable<CaseNotification> Where(Func<CaseNotification, bool> whereClause);
    }

    public class CaseNotifications : ICaseNotifications
    {
        readonly IEthicalWall _ethicalWall;
        readonly ICaseAuthorization _caseAuthorization;
        readonly IRepository _repository;
        readonly IIndex<DataSourceType, ISourceNotificationReviewedHandler> _reviewHandlers;
        readonly ISecurityContext _securityContext;

        public CaseNotifications(IRepository repository, ISecurityContext securityContext,
                                 IEthicalWall ethicalWall, ICaseAuthorization caseAuthorization,
                                 IIndex<DataSourceType, ISourceNotificationReviewedHandler> reviewHandlers)
        {
            _repository = repository;
            _securityContext = securityContext;
            _ethicalWall = ethicalWall;
            _caseAuthorization = caseAuthorization;
            _reviewHandlers = reviewHandlers;
        }

        public async Task<IDictionary<DataSourceType, int>> CountByDataSourceType()
        {
            var rawSource = _repository.Set<CaseNotification>()
                                       .Select(n => new {n.Case.Source, n.Case.CorrelationId})
                                       .GroupBy(n => n.Source)
                                       .ToDictionary(_ => _.Key, _ => _);

            var result = new Dictionary<DataSourceType, int>();

            foreach (var source in rawSource)
            {
                var caseIds = source.Value.Where(_ => _.CorrelationId.HasValue).Select(_ => _.CorrelationId).Cast<int>().ToArray();

                var countCorrelatedAccessible = (await _caseAuthorization.GetInternalUserAccessPermissions(_ethicalWall.AllowedCases(caseIds)))
                                                                   .Count(_ => (_.Value & AccessPermissionLevel.Select) == AccessPermissionLevel.Select);

                var countNonCorrelated = source.Value.Count(_ => _.CorrelationId == null);

                result[source.Key] = countNonCorrelated + countCorrelatedAccessible;
            }

            return result;
        }

        public IQueryable<CaseNotification> Where(Func<CaseNotification, bool> whereClause)
        {
            if (whereClause == null) throw new ArgumentNullException(nameof(whereClause));

            return _repository.Set<CaseNotification>()
                              .Include(n => n.Case)
                              .Where(whereClause)
                              .AsQueryable();
        }

        public IQueryable<CaseNotification> ThatSatisfies(SearchParameters searchParameters)
        {
            if (searchParameters == null) throw new ArgumentNullException(nameof(searchParameters));

            return _repository.Set<CaseNotification>()
                              .Include(n => n.Case)
                              .IncludesErrors(searchParameters.IncludeErrors)
                              .IncludesReviewed(searchParameters.IncludeReviewed)
                              .IncludesRejected(searchParameters.IncludeRejected)
                              .FiltersBy(searchParameters.DataSourceTypesOrDefault());
        }

        public async Task MarkReviewed(int notificationid)
        {
            var notification = await _repository
                .Set<CaseNotification>()
                .Include(_ => _.Case)
                .SingleAsync(cn => cn.Id == notificationid);

            notification.IsReviewed = true;
            notification.ReviewedBy = _securityContext.User.Id;

            if (_reviewHandlers.TryGetValue(notification.Case.Source, out ISourceNotificationReviewedHandler handler))
            {
                await handler.Handle(notification);
            }

            _repository.SaveChanges();
        }
    }

    public static class CaseNotificationsExt
    {
        public static IQueryable<CaseNotification> FiltersBy(this IQueryable<CaseNotification> notifications, IEnumerable<DataSourceType> dataSourceTypes)
        {
            if (notifications == null) throw new ArgumentNullException(nameof(notifications));
            if (dataSourceTypes == null) throw new ArgumentNullException(nameof(dataSourceTypes));

            return notifications.Where(_ => dataSourceTypes.Contains(_.Case.Source));
        }

        public static IQueryable<CaseNotification> IncludesErrors(this IQueryable<CaseNotification> notifications, bool include)
        {
            if (notifications == null) throw new ArgumentNullException(nameof(notifications));

            return include ? notifications : notifications.Where(_ => _.Type != CaseNotificateType.Error);
        }

        public static IQueryable<CaseNotification> IncludesRejected(this IQueryable<CaseNotification> notifications, bool include)
        {
            if (notifications == null) throw new ArgumentNullException(nameof(notifications));

            return include ? notifications : notifications.Where(_ => _.Type != CaseNotificateType.Rejected);
        }

        public static IQueryable<CaseNotification> IncludesReviewed(this IQueryable<CaseNotification> notifications, bool include)
        {
            if (notifications == null) throw new ArgumentNullException(nameof(notifications));

            return include ? notifications : notifications.Where(_ => !_.IsReviewed);
        }

        public static IQueryable<CaseNotification> ThatConsiders(this IQueryable<CaseNotification> notifications, string searchText)
        {
            if (string.IsNullOrWhiteSpace(searchText))
            {
                return notifications;
            }

            return notifications
                .Where(_ => _.Type != CaseNotificateType.Error
                            && _.Body != null
                            && _.Body.Contains(searchText) || _.Case.ApplicationNumber != null && _.Case.ApplicationNumber.Contains(searchText) || _.Case.PublicationNumber != null && _.Case.PublicationNumber.Contains(searchText) || _.Case.RegistrationNumber != null && _.Case.RegistrationNumber.Contains(searchText));
        }
    }
}