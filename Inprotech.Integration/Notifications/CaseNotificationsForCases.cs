using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;

namespace Inprotech.Integration.Notifications
{
    public interface ICaseNotificationsForCases
    {
        Task<(IEnumerable<CaseNotificationResponse> Result, Dictionary<DataSourceType, int> ResultCount, bool HasMore)> Fetch(SelectedCasesNotificationOptions filterOptions);
    }

    public class CaseNotificationsForCases : ICaseNotificationsForCases
    {
        readonly ICaseIdsResolver _caseIdsResolver;
        readonly IRequestedCases _requestedCases;
        readonly ICaseNotifications _caseNotifications;
        readonly INotificationResponse _notificationResponse;
        readonly ICaseIndexesSearch _caseIndexesSearch;

        public CaseNotificationsForCases(
            ICaseIdsResolver caseIdsResolver,
            IRequestedCases requestedCases,
            ICaseNotifications caseNotifications,
            INotificationResponse notificationResponse,
            ICaseIndexesSearch caseIndexesSearch)
        {
            _caseIdsResolver = caseIdsResolver;
            _requestedCases = requestedCases;
            _caseNotifications = caseNotifications;
            _notificationResponse = notificationResponse;
            _caseIndexesSearch = caseIndexesSearch;
        }

        public async Task<(IEnumerable<CaseNotificationResponse> Result, Dictionary<DataSourceType, int> ResultCount, bool HasMore)> 
            Fetch(SelectedCasesNotificationOptions filterOptions)
        {
            if (filterOptions == null) throw new ArgumentNullException(nameof(filterOptions));

            var r = await BuildCaseNotificationResponsesFor(filterOptions);

            var responses = r.Result.ToArray();

            var hasMore = responses.Length > filterOptions.PageSize;

            return (responses.Take(filterOptions.PageSize), r.ResultsCount, hasMore);
        }

        async Task<(IEnumerable<CaseNotificationResponse> Result, Dictionary<DataSourceType, int> ResultsCount)> 
            BuildCaseNotificationResponsesFor(SelectedCasesNotificationOptions filterOptions)
        {
            var caseIds = _caseIdsResolver.Resolve(filterOptions);

            var correlated = _caseNotifications
                .ThatSatisfies(filterOptions)
                .ThatConsiders(filterOptions.SearchText)
                .Where(_ => _.Case.CorrelationId.HasValue)
                .Select(_ => _.Case.CorrelationId.Value)
                .ToArray();

            if (filterOptions.HasSearchText())
            {
                var matches = _caseIndexesSearch.Search(filterOptions.SearchText, CaseIndexSource.Irn, CaseIndexSource.Title, CaseIndexSource.OfficialNumbers);

                var shortlistedCaseIds = matches.Union(correlated).Select(_ => _.ToString()).ToArray();

                caseIds = caseIds.Intersect(shortlistedCaseIds).ToArray();
            }
            else
            {
                caseIds = caseIds.Intersect(correlated.Select(_ => _.ToString())).ToArray();
            }

            var all = (await ResolveEligibleNotifications(caseIds)).ToArray();

            var resultsCount = all.GroupBy(_ => _.DataSourceType).ToDictionary(_ => _.Key, _ => _.Count());

            var notifications = all
                .WithMatchingDataSources(filterOptions.DataSourceTypes)
                .IncludesErrors(filterOptions.IncludeErrors)
                .IncludesRejected(filterOptions.IncludeRejected)
                .IncludesReviewed(filterOptions.IncludeReviewed);

            if (filterOptions.Since.HasValue && caseIds.Contains(filterOptions.Since.ToString()))
            {
                return (notifications
                    .SkipWhile(_ => _.CaseId != filterOptions.Since)
                    .Take(filterOptions.PageSize + 2)
                    .Skip(1), resultsCount); /* skip filterOptions.Since */
            }

            return (notifications.Take(filterOptions.PageSize + 1), resultsCount);
        }

        async Task<IEnumerable<CaseNotificationResponse>> ResolveEligibleNotifications(string[] caseIds)
        {
            var notifications = await _requestedCases.LoadNotifications(caseIds);

            var result = new List<CaseNotificationResponse>();
            foreach (var n in _notificationResponse.For(notifications.Keys))
            {
                var c = notifications.Single(_ => _.Key.Id == n.NotificationId);
                n.CaseRef = c.Value.Irn;
                n.CaseId = c.Value.Id;
                result.Add(n);
            }

            return result;
        }
    }

    public class SelectedCasesNotificationOptions : SearchParameters
    {
        public int PageSize { get; set; }

        public int? Since { get; set; }

        public string Caselist { get; set; }

        public long? Ts { get; set; }
    }
}
