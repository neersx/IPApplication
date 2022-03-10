using System;
using System.Data.Entity;
using System.Linq;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Persistence;
using Newtonsoft.Json;

namespace Inprotech.Integration.Schedules
{
    public interface IScheduleRuntimeEvents
    {
        Guid StartSchedule(Schedule schedule, Guid cancellationToken, string correlationId = null, string additionalData = null);
        void End(Guid guid);
        void Cancel(Guid scheduleId);
        void Failed(Guid guid, string details, byte[] recoverableArtifacts = null);
        void CaseFailed(Guid guid, Case @case, byte[] caseArtifacts);
        void DocumentFailed(Guid guid, Document document, byte[] documentArtifacts);
        void CaseProcessed(Guid guid, Case @case, byte[] caseArtifacts);
        void DocumentProcessed(Guid guid, Document document);
        void IncludeCases(Guid guid, int cases, byte[] executionArtifacts = null);
        void IncludeDocumentsForCase(Guid guid, int documents);
        void MarkUnrecoverable(Guid guid, params object[] artifacts);
        void UpdateCasesProcessed(Guid guid, params int[] caseIds);
    }

    public class ScheduleRuntimeEvents : IScheduleRuntimeEvents
    {
        readonly Func<DateTime> _now;
        readonly IRepository _repository;
        readonly IScheduleExecutionManager _scheduleExecutionManager;

        public ScheduleRuntimeEvents(IRepository repository, IScheduleExecutionManager scheduleExecutionManager, Func<DateTime> now)
        {
            _repository = repository;
            _scheduleExecutionManager = scheduleExecutionManager;
            _now = now;
        }

        public Guid StartSchedule(Schedule schedule, Guid cancellationToken, string correlationId = null, string additionalData = null)
        {
            if (schedule == null) throw new ArgumentNullException(nameof(schedule));

            var guid = Guid.NewGuid();
            var now = _now();

            _repository.Set<ScheduleExecution>()
                       .Add(
                            new ScheduleExecution(guid, schedule, now, correlationId)
                            {
                                AdditionalData = additionalData,
                                Status = ScheduleExecutionStatus.Started,
                                CancellationData = cancellationToken != Guid.Empty ? JsonConvert.SerializeObject(new CancellationInfo(cancellationToken)) : null
                            });

            _repository.SaveChanges();

            return guid;
        }

        public void End(Guid guid)
        {
            var se = _repository.Set<ScheduleExecution>()
                                .Include(_ => _.Schedule)
                                .Single(_ => _.SessionGuid == guid);

            se.Finished = se.UpdatedOn = _now();

            //This method might get called even if there are some failures happened
            var scheduleExecutionId = se.Id;
            var hasFailures = _repository.Set<ScheduleFailure>().Any(_ => _.ScheduleExecutionId == scheduleExecutionId);

            se.Status = hasFailures ? ScheduleExecutionStatus.Failed : ScheduleExecutionStatus.Complete;

            _repository.SaveChanges();
        }

        public void Failed(Guid guid, string details, byte[] recoverableArtifacts = null)
        {
            var se = _repository.Set<ScheduleExecution>()
                                .Include(_ => _.Schedule)
                                .Single(_ => _.SessionGuid == guid);

            se.Finished = se.UpdatedOn = _now();
            se.Status = ScheduleExecutionStatus.Failed;

            _repository.Set<ScheduleFailure>().Add(new ScheduleFailure(se.Schedule, se, se.UpdatedOn, details));

            if (recoverableArtifacts != null)
            {
                var recoverable = _repository.Set<ScheduleRecoverable>();
                var sr = recoverable
                         .Include(_ => _.ScheduleExecution)
                         .SingleOrDefault(_ => _.ScheduleExecution.Id == se.Id && _.Document == null && _.CaseId == null) ??
                         recoverable.Add(new ScheduleRecoverable(se, se.UpdatedOn));
                sr.Blob = recoverableArtifacts;
                sr.LastUpdated = se.UpdatedOn = _now();
            }
            
            _repository.SaveChanges();
        }

        public void Cancel(Guid scheduleId)
        {
            var se = _repository.Set<ScheduleExecution>()
                                .Include(_ => _.Schedule)
                                .Single(_ => _.SessionGuid == scheduleId);

            if (se.Status == ScheduleExecutionStatus.Complete || se.Status == ScheduleExecutionStatus.Failed)
            {
                return;
            }

            se.Finished = se.UpdatedOn = _now();
            se.Status = ScheduleExecutionStatus.Cancelled;
            _repository.SaveChanges();
        }

        public void CaseFailed(Guid guid, Case @case, byte[] caseArtifacts)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));

            var se = _repository.Set<ScheduleExecution>()
                                .Include(_ => _.Schedule)
                                .Single(_ => _.SessionGuid == guid);

            var recoverables = _repository.Set<ScheduleRecoverable>();
            var sr = recoverables
                         .Include(_ => _.ScheduleExecution)
                         .Include(_ => _.Case)
                         .SingleOrDefault(_ => _.ScheduleExecution.Id == se.Id && _.Case.Id == @case.Id && _.Document == null) ??
                     recoverables.Add(new ScheduleRecoverable(se, @case, se.UpdatedOn));

            sr.Blob = caseArtifacts ?? sr.Blob;
            sr.LastUpdated = se.UpdatedOn = _now();
            _repository.SaveChanges();
        }

        public void DocumentFailed(Guid guid, Document document, byte[] caseArtifacts)
        {
            if (document == null) throw new ArgumentNullException(nameof(document));

            var se = _repository.Set<ScheduleExecution>()
                                .Include(_ => _.Schedule)
                                .Single(_ => _.SessionGuid == guid);

            var recoverables = _repository.Set<ScheduleRecoverable>();
            var sr = recoverables
                         .Include(_ => _.ScheduleExecution)
                         .Include(_ => _.Document)
                         .SingleOrDefault(_ => _.ScheduleExecution.Id == se.Id && _.Document.Id == document.Id) ??
                     recoverables.Add(new ScheduleRecoverable(se, document, se.UpdatedOn));

            sr.Blob = caseArtifacts ?? sr.Blob;
            sr.LastUpdated = se.UpdatedOn = _now();
            _repository.SaveChanges();
        }

        public void CaseProcessed(Guid guid, Case @case, byte[] caseArtifacts)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));

            var se = _scheduleExecutionManager.FindBySession(guid);
            _scheduleExecutionManager.AddArtefactOnCaseProcessed(se, @case.Id, caseArtifacts);
        }

        public void UpdateCasesProcessed(Guid guid, params int[] caseIds)
        {
            var se = _scheduleExecutionManager.FindBySession(guid);
            _scheduleExecutionManager.UpdateCasesProcessed(se, caseIds);
        }

        public void DocumentProcessed(Guid guid, Document document)
        {
            if (document == null) throw new ArgumentNullException(nameof(document));

            var se = _repository.Set<ScheduleExecution>()
                                .Include(_ => _.Schedule)
                                .Single(_ => _.SessionGuid == guid);

            se.UpdatedOn = _now();
            se.DocumentsProcessed = se.DocumentsProcessed.GetValueOrDefault() + 1;

            _repository.SaveChanges();
        }

        public void IncludeCases(Guid guid, int cases, byte[] executionArtifacts = null)
        {
            var se = _repository.Set<ScheduleExecution>()
                                .Include(_ => _.Schedule)
                                .Single(_ => _.SessionGuid == guid);
            se.CasesIncluded = cases;
            se.UpdatedOn = _now();

            _repository.SaveChanges();

            if (executionArtifacts == null)
            {
                return;
            }

            _scheduleExecutionManager.AddExecutionArtifact(se, executionArtifacts);
        }

        public void IncludeDocumentsForCase(Guid guid, int documents)
        {
            var se = _repository.Set<ScheduleExecution>()
                                .Include(_ => _.Schedule)
                                .Single(_ => _.SessionGuid == guid);

            se.DocumentsIncluded = se.DocumentsIncluded.GetValueOrDefault() + documents;
            se.UpdatedOn = _now();

            _repository.SaveChanges();
        }

        public void MarkUnrecoverable(Guid guid, params object[] artifacts)
        {
            var se = _repository.Set<ScheduleExecution>()
                                .Include(_ => _.Schedule)
                                .Single(_ => _.SessionGuid == guid);

            foreach (var artifact in artifacts)
            {
                _repository.Set<UnrecoverableArtefact>()
                           .Add(
                                new UnrecoverableArtefact(se, JsonConvert.SerializeObject(artifact), _now())
                               );
            }

            _repository.SaveChanges();
        }
    }
}