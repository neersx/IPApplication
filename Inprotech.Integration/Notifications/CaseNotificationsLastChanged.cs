using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;

namespace Inprotech.Integration.Notifications
{
    public interface ICaseNotificationsLastChanged
    {
        Task<(IEnumerable<CaseNotificationResponse> Results, bool HasMore)> Fetch(LastChangedNotificationsOptions filterOptions);
    }

    public class CaseNotificationsLastChanged : ICaseNotificationsLastChanged
    {
        readonly ICaseDetailsWithSecurity _caseDetailsWithSecurity;
        readonly ICaseIndexesSearch _caseIndexesSearch;
        readonly ICaseNotifications _caseNotifications;
        readonly Func<DateTime> _now;

        public CaseNotificationsLastChanged(
            ICaseNotifications caseNotifications,
            ICaseIndexesSearch caseIndexesSearch,
            Func<DateTime> now,
            ICaseDetailsWithSecurity caseDetailsWithSecurity)
        {
            _caseNotifications = caseNotifications;
            _caseIndexesSearch = caseIndexesSearch;
            _now = now;
            _caseDetailsWithSecurity = caseDetailsWithSecurity;
        }

        public async Task<(IEnumerable<CaseNotificationResponse> Results, bool HasMore)> Fetch(LastChangedNotificationsOptions filterOptions)
        {
            if (filterOptions == null) throw new ArgumentNullException(nameof(filterOptions));

            var hasMore = false;

            var since = filterOptions.Since ?? new DateTime(_now().Ticks, DateTimeKind.Unspecified);

            var caseNotifications = SearchBy(filterOptions)
                                    .Where(_ => _.UpdatedOn < since)
                                    .OrderByDescending(_ => _.UpdatedOn)
                                    .Take(filterOptions.PageSize + 1);

            var responses = (await _caseDetailsWithSecurity.LoadCaseDetailsWithSecurityCheck(caseNotifications)).ToArray();

            if (responses.Length > filterOptions.PageSize)
            {
                hasMore = true;
            }

            return (responses.Take(filterOptions.PageSize), hasMore);
        }

        IQueryable<CaseNotification> SearchBy(SearchParameters filterOptions)
        {
            var notifications = _caseNotifications.ThatSatisfies(filterOptions);

            if (!filterOptions.HasSearchText())
            {
                return notifications;
            }

            notifications = notifications.ThatConsiders(filterOptions.SearchText);

            var matches = _caseIndexesSearch.Search(filterOptions.SearchText, CaseIndexSource.Irn, CaseIndexSource.Title, CaseIndexSource.OfficialNumbers)
                                            .ToArray();

            var correlated = _caseNotifications.ThatSatisfies(filterOptions)
                                               .Where(_ => _.Case.CorrelationId.HasValue && matches.Contains(_.Case.CorrelationId.Value));

            return notifications.Union(correlated);
        }
    }

    public class LastChangedNotificationsOptions : SearchParameters
    {
        public int PageSize { get; set; }

        public DateTime? Since { get; set; }
    }
}