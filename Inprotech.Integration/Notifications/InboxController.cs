using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Settings;

namespace Inprotech.Integration.Notifications
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ViewCaseDataComparison)]
    public class InboxController : ApiController
    {
        readonly ICaseNotifications _caseNotifications;
        readonly ICaseNotificationsForCases _caseNotificationsForCases;
        readonly ICaseNotificationsForExecution _caseNotificationsForExecution;
        readonly ICaseNotificationsLastChanged _caseNotificationsLastChanged;
        readonly IDmsIntegrationSettings _settings;
        readonly ISourceCaseRejection _sourceCaseRejection;

        public InboxController(
            ICaseNotifications caseNotifications,
            ICaseNotificationsForCases caseNotificationsForCases,
            ICaseNotificationsLastChanged caseNotificationsLastChanged,
            IDmsIntegrationSettings settings,
            ISourceCaseRejection sourceCaseRejection, ICaseNotificationsForExecution caseNotificationsForExecution)
        {
            _caseNotifications = caseNotifications;
            _caseNotificationsForCases = caseNotificationsForCases;
            _caseNotificationsLastChanged = caseNotificationsLastChanged;
            _settings = settings;
            _sourceCaseRejection = sourceCaseRejection;
            _caseNotificationsForExecution = caseNotificationsForExecution;
        }

        [HttpPost]
        [Route("api/casecomparison/inbox/notifications")]
        public async Task<Response> Notifications(LastChangedNotificationsOptions searchParams)
        {
            if (searchParams == null) throw new ArgumentNullException(nameof(searchParams));

            var r = await _caseNotificationsLastChanged.Fetch(searchParams);

            return new Response
            {
                DataSources = !searchParams.DataSourceTypes.Any() ? await BuildDataSource() : null,
                Notifications = r.Results,
                HasMore = r.HasMore
            };
        }

        [HttpPost]
        [Route("api/casecomparison/inbox/executions")]
        public async Task<Response> Executions(ExecutionNotificationsOptions searchParams)
        {
            if (searchParams == null) throw new ArgumentNullException(nameof(searchParams));

            var r = await _caseNotificationsForExecution.Fetch(searchParams);

            return new Response
            {
                DataSources = !searchParams.DataSourceTypes.Any() ? await BuildDataSource(r.ResultsCount) : null,
                Notifications = r.Results,
                HasMore = r.HasMore
            };
        }

        [HttpPost]
        [Route("api/casecomparison/inbox/cases")]
        public async Task<Response> Cases(SelectedCasesNotificationOptions searchParams)
        {
            if (searchParams == null) throw new ArgumentNullException(nameof(searchParams));

            var r = await _caseNotificationsForCases.Fetch(searchParams);

            return new Response
            {
                DataSources = !searchParams.DataSourceTypes.Any() ? await BuildDataSource(r.ResultCount) : null,
                Notifications = r.Result,
                HasMore = r.HasMore
            };
        }

        [HttpPost]
        [Route("api/casecomparison/inbox/review")]
        public async Task Review(int notificationId)
        {
            await _caseNotifications.MarkReviewed(notificationId);
        }

        [HttpPost]
        [Route("api/casecomparison/inbox/reject-case-match")]
        [RequiresAccessTo(ApplicationTask.SaveImportedCaseData)]
        public async Task<dynamic> RejectCaseMatch(int notificationId)
        {
            return await _sourceCaseRejection.Reject(notificationId);
        }

        [HttpPost]
        [Route("api/casecomparison/inbox/reverse-case-match-rejection")]
        [RequiresAccessTo(ApplicationTask.SaveImportedCaseData)]
        public async Task<dynamic> ReverseCaseMatchReject(int notificationId)
        {
            return await _sourceCaseRejection.ReverseRejection(notificationId);
        }

        async Task<dynamic> BuildDataSource(IDictionary<DataSourceType, int> counts = null)
        {
            var r = counts ?? await _caseNotifications.CountByDataSourceType();

            return r.Select(_ =>
                                new
                                {
                                    Id = _.Key.ToString(),
                                    Count = _.Value,
                                    DmsIntegrationEnabled = _settings.IsEnabledFor(_.Key)
                                })
                    .ToArray();
        }

        public class Response
        {
            public dynamic DataSources { get; set; }

            public IEnumerable<CaseNotificationResponse> Notifications { get; set; }

            public bool HasMore { get; set; }
        }
    }
}