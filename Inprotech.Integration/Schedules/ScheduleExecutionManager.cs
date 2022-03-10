using Inprotech.Integration.Persistence;
using System;
using System.Linq;

namespace Inprotech.Integration.Schedules
{
    public interface IScheduleExecutionManager
    {
        ScheduleExecution FindBySession(Guid guid);

        void AddArtefactOnCaseProcessed(ScheduleExecution se, int forCaseId, byte[] caseArtefacts);

        void AddExecutionArtifact(ScheduleExecution se, byte[] executionArtefacts);

        void UpdateCasesProcessed(ScheduleExecution se, params int[] caseIds);
    }

    internal class ScheduleExecutionManager : IScheduleExecutionManager
    {
        readonly Func<DateTime> _now;
        readonly IRepository _repository;

        public ScheduleExecutionManager(IRepository repository, Func<DateTime> now)
        {
            _repository = repository;
            _now = now;
        }

        public ScheduleExecution FindBySession(Guid guid)
        {
            return _repository.Set<ScheduleExecution>().SingleOrDefault(_ => _.SessionGuid == guid);
        }

        public void AddArtefactOnCaseProcessed(ScheduleExecution se, int forCaseId, byte[] caseArtefacts)
        {
            if (se == null) throw new ArgumentNullException(nameof(se));
            var artifacts = _repository.Set<ScheduleExecutionArtifact>();

            var sea = artifacts.SingleOrDefault(_ => _.ScheduleExecutionId == se.Id && _.CaseId == forCaseId)
                      ?? artifacts
                          .Add(new ScheduleExecutionArtifact
                          {
                              ScheduleExecutionId = se.Id,
                              CaseId = forCaseId
                          });

            sea.Blob = caseArtefacts ?? sea.Blob;

            _repository.SaveChanges();

            /* schedule execution artifacts could store non-case artefacts */
            se.CasesProcessed = artifacts.Count(_ => _.ScheduleExecutionId == se.Id && _.CaseId != null);

            se.UpdatedOn = _now();

            _repository.SaveChanges();

            UpdateRecoverableForRetrySchedule(se, new[] { forCaseId });
        }

        public void UpdateCasesProcessed(ScheduleExecution se, params int[] caseIds)
        {
            if (se == null) throw new ArgumentNullException(nameof(se));

            var artifacts = _repository.Set<ScheduleExecutionArtifact>();

            var existing = artifacts.Where(_ => _.ScheduleExecutionId == se.Id && _.CaseId != null && caseIds.Contains(_.CaseId.Value))
                                    .Select(_ => _.CaseId.Value)
                                    .ToArray();

            foreach (var id in caseIds.Except(existing))
            {
                artifacts.Add(new ScheduleExecutionArtifact
                {
                    CaseId = id,
                    ScheduleExecutionId = se.Id
                });
            }

            _repository.SaveChanges();

            /* schedule execution artifacts could store non-case artefacts */
            se.CasesProcessed = artifacts.Count(_ => _.ScheduleExecutionId == se.Id && _.CaseId != null);

            se.UpdatedOn = _now();

            _repository.SaveChanges();

            UpdateRecoverableForRetrySchedule(se, caseIds);
        }

        public void AddExecutionArtifact(ScheduleExecution se, byte[] executionArtifacts)
        {
            if (se == null) throw new ArgumentNullException(nameof(se));

            var artifacts = _repository.Set<ScheduleExecutionArtifact>();

            var sea = artifacts.SingleOrDefault(_ => _.ScheduleExecutionId == se.Id && _.CaseId == null)
                      ?? artifacts
                          .Add(new ScheduleExecutionArtifact
                          {
                              ScheduleExecutionId = se.Id
                          });

            sea.Blob = executionArtifacts;

            se.UpdatedOn = _now();

            _repository.SaveChanges();

        }
        void UpdateRecoverableForRetrySchedule(ScheduleExecution se, int[] caseIds)
        {
            if (se.Schedule.Type != ScheduleType.Retry) return;
            _repository.Delete(_repository.Set<ScheduleRecoverable>()
                                          .Where(sr => sr.ScheduleExecutionId == se.Id && sr.CaseId.HasValue && caseIds.Contains(sr.CaseId.Value)));

            _repository.SaveChanges();
        }
    }
}