using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Activities
{
    public class DetailsUnavailable
    {
        readonly IRepository _repository;
        readonly IScheduleRuntimeEvents _runtimeEvents;

        public DetailsUnavailable(IRepository repository, IScheduleRuntimeEvents runtimeEvents)
        {
            _repository = repository;
            _runtimeEvents = runtimeEvents;
        }

        public async Task RemoveStaleNotification(DataDownload dataDownload)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            var caseNotification = await _repository.Set<CaseNotification>()
                                                    .SingleOrDefaultAsync(_ => _.Case.Source == dataDownload.DataSourceType &&
                                                                               _.Case.CorrelationId == dataDownload.Case.CaseKey);

            if (caseNotification == null)
            {
                return;
            }

            _repository.Set<CaseNotification>().Remove(caseNotification);
            _repository.SaveChanges();
        }

        public async Task DiscardNofitications(Guid sessionGuid, int[] inprotechCaseIds)
        {
            var exists = _repository.Set<Case>()
                                    .Where(_ => inprotechCaseIds.Any(c => _.CorrelationId == c) && _.Source == DataSourceType.IpOneData)
                                    .Select(_ => _.Id)
                                    .ToArray();

            if (exists.Any())
            {
                await _repository.DeleteAsync(
                                              _repository.Set<CaseNotification>().Where(_ => exists.Contains(_.CaseId)));
            }

            _runtimeEvents.UpdateCasesProcessed(sessionGuid, exists);
        }
    }
}