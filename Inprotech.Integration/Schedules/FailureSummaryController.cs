using System;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.DataSources;
using Inprotech.Integration.Diagnostics.PtoAccess;

namespace Inprotech.Integration.Schedules
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoTsdrDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleEpoDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleIpOneDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleFileDataDownload)]
    [ViewInitialiser]
    public class FailureSummaryController : ApiController
    {
        readonly IDiagnosticLogsProvider _diagnosticLogsProvider;
        readonly IFailureSummaryProvider _failureSummaryProvider;
        readonly IAvailableDataSources _availableDataSources;
        readonly IRecoverableSchedule _recoverableSchedule;

        public FailureSummaryController(IDiagnosticLogsProvider diagnosticLogsProvider,
                                        IFailureSummaryProvider failureSummaryProvider,
                                        IAvailableDataSources availableDataSources,
                                        IRecoverableSchedule recoverableSchedule)
        {
            _diagnosticLogsProvider = diagnosticLogsProvider;
            _availableDataSources = availableDataSources;
            _recoverableSchedule = recoverableSchedule;
            _failureSummaryProvider = failureSummaryProvider;
        }

        [Route("api/ptoaccess/failuresummaryview")]
        public dynamic Get()
        {
            return new
                   {
                       AllowDiagnostics = _diagnosticLogsProvider.DataAvailable,
                       FailureSummary = _failureSummaryProvider.RecoverableItemsByDataSource(_availableDataSources.List().ToArray(), ArtifactInclusion.Exclude).ToArray()
                   };
        }

        [HttpPost]
        [Route("api/ptoaccess/failuresummary/retryall/{dataSourceType}")]
        public void RetryAll(string dataSourceType)
        {
            DataSourceType dataSource;
            if (!Enum.TryParse(dataSourceType, true, out dataSource))
                return;

            var allFailedItems = _failureSummaryProvider.AllFailedItems(new[] {dataSource}, ArtifactInclusion.Exclude).ToArray();
            var allFailedSchedules = allFailedItems.Select(_ => _.ScheduleId).Distinct();

            foreach (var scheduleId in allFailedSchedules)
            {
                _recoverableSchedule.Recover(scheduleId);
            }
        }
    }
}