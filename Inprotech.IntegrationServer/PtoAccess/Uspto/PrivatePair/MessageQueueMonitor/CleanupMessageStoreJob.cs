using System;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Contracts;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Storage;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.MessageQueueMonitor
{
    public interface ICleanupMessageStoreJob
    {
        Task CleanupMessageStoreTable();
    }

    class CleanupMessageStoreJob : ICleanupMessageStoreJob
    {
        readonly IRepository _repository;
        readonly Func<DateTime> _now;
        readonly IBackgroundProcessLogger<ICleanupMessageStoreJob> _logger;

        public CleanupMessageStoreJob(IRepository repository, Func<DateTime> now, IBackgroundProcessLogger<ICleanupMessageStoreJob> logger)
        {
            _repository = repository;
            _now = now;
            _logger = logger;
        }

        public async Task CleanupMessageStoreTable()
        {
            var processIdToCleanup = _repository.Set<ProcessIdsToCleanup>()
                                                .Where(_ => !_.IsCleanedUp)
                                                .OrderBy(_ => _.AddedOn)
                                                .Take(1)
                                                .FirstOrDefault();

            if (processIdToCleanup == null)
                return;

            using var tcs = _repository.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled);
            try
            {
                var messageStoreToDelete = _repository.Set<MessageStore>()
                                                      .Where(_ => _.ProcessId == processIdToCleanup.ProcessId);
                await _repository.DeleteAsync(messageStoreToDelete);

                processIdToCleanup.MarkAsCleanedup(_now());
                
                await _repository.SaveChangesAsync();
                
                tcs.Complete();
            }
            catch (Exception ex)
            {
                tcs.Dispose();
                _logger.Exception(ex);
            }
        }
    }
}