using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;

namespace Inprotech.Integration.Notifications
{
    public interface ICaseNotificationsForExecution
    {
        Task<(IEnumerable<CaseNotificationResponse> Results, bool HasMore, Dictionary<DataSourceType, int> ResultsCount)> Fetch(ExecutionNotificationsOptions filterOptions);
    }

    public class CaseNotificationsForExecution : ICaseNotificationsForExecution
    {
        readonly ICaseDetailsWithSecurity _caseDetailsWithSecurity;
        readonly ICaseIndexesSearch _caseIndexesSearch;
        readonly ICaseNotifications _caseNotifications;
        readonly IRepository _repository;
        
        public CaseNotificationsForExecution(
            ICaseNotifications caseNotifications,
            ICaseIndexesSearch caseIndexesSearch,
            IRepository repository,
            ICaseDetailsWithSecurity caseDetailsWithSecurity)
        {
            _caseNotifications = caseNotifications;
            _caseIndexesSearch = caseIndexesSearch;
            _repository = repository;
            _caseDetailsWithSecurity = caseDetailsWithSecurity;
        }

        public async Task<(IEnumerable<CaseNotificationResponse> Results, bool HasMore, Dictionary<DataSourceType, int> ResultsCount)> Fetch(ExecutionNotificationsOptions filterOptions)
        {
            if (filterOptions == null) throw new ArgumentNullException(nameof(filterOptions));
            if (!filterOptions.ScheduleExecutionId.HasValue) throw new ArgumentNullException(nameof(filterOptions.ScheduleExecutionId));

            var hasMore = false;

            var notifications = SearchBy(filterOptions);
            var artifacts = _repository.Set<ScheduleExecutionArtifact>();

            var query = from n in notifications
                        join sea in artifacts on n.CaseId equals sea.CaseId
                        where sea.ScheduleExecutionId == filterOptions.ScheduleExecutionId
                        orderby n.UpdatedOn descending
                        select n;

            var caseNotifications = query
                                    .Include(n => n.Case)
                                    .IncludesErrors(filterOptions.IncludeErrors)
                                    .IncludesReviewed(filterOptions.IncludeReviewed)
                                    .IncludesRejected(filterOptions.IncludeRejected)
                                    .FiltersBy(filterOptions.DataSourceTypesOrDefault());

            var responses = (await _caseDetailsWithSecurity.LoadCaseDetailsWithSecurityCheck(caseNotifications)).ToArray();
            var resultsCount = responses.GroupBy(_ => _.DataSourceType).ToDictionary(_ => _.Key, _ => _.Count());

            IEnumerable<CaseNotificationResponse> results;
            if (filterOptions.Since.HasValue)
            {
                results = responses
                          .SkipWhile(_ => _.NotificationId != filterOptions.Since)
                          .Skip(1).ToList(); /* skip filterOptions.Since */
            }
            else
            {
                results = responses.ToList();
            }

            if (results.Count() > filterOptions.PageSize)
            {
                hasMore = true;
            }

            return (results.Take(filterOptions.PageSize), hasMore, resultsCount);
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

    public class ExecutionNotificationsOptions : SearchParameters
    {
        public int PageSize { get; set; }
        public string DataSource { get; set; }
        public int? ScheduleExecutionId { get; set; }
        public int? Since { get; set; }
    }
}