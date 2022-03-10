using System.Collections.Generic;
using System.Linq;
using System.Transactions;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.System.Messages;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface IGlobalNameChangeMonitor : IMonitorClockRunnable
    {
    }

    class GlobalNameChangeMonitor : IGlobalNameChangeMonitor
    {
        readonly IDbContext _dbContext;
        readonly IBus _bus;
        readonly IGlobalNameChangeCaseIdProvider _caseIdProvider;

        public GlobalNameChangeMonitor(IDbContext dbContext, IBus bus, IGlobalNameChangeCaseIdProvider caseIdProvider)
        {
            _dbContext = dbContext;
            _bus = bus;
            _caseIdProvider = caseIdProvider;
        }

        public void Run()
        {
            var caseIds = _caseIdProvider.CaseIds.ToArray();
            if (!caseIds.Any())
                return;

            IEnumerable<int> workingCaseIds;

            using (_dbContext.BeginTransaction(IsolationLevel.ReadUncommitted))
            {
                workingCaseIds = _dbContext.Set<GlobalNameChangeRequest>()
                                           .Where(_ => caseIds.Contains(_.CaseId))
                                           .Select(_ => _.CaseId)
                                           .Distinct()
                                           .ToArray();
            }

            foreach (var caseId in workingCaseIds)
            {
                var message = new BroadcastMessageToClient
                              {
                                  Topic = "globalName.change." + caseId, Data = GlobalNameChangeReader.Running
                              };

                _bus.Publish(message);
            }

            foreach (var caseId in caseIds.Except(workingCaseIds))
            {
                var message = new BroadcastMessageToClient
                              {
                                  Topic = "globalName.change." + caseId,
                                  Data = GlobalNameChangeReader.Complete
                              };

                _bus.Publish(message);
            }
        }
    }
}