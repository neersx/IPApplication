using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;

namespace Inprotech.Integration.Schedules
{
    public enum ArtifactInclusion
    {
        Include,
        Exclude
    }

    public interface IScheduleRecoverableReader
    {
        IQueryable<FailedItem> GetAll(ArtifactInclusion artifact = ArtifactInclusion.Include);

        IEnumerable<FailedItem> GetAllFor(DataSourceType[] dataSourceTypes, ArtifactInclusion withArtifact = ArtifactInclusion.Include);

        IEnumerable<FailedItem> OrphanDocuments(IEnumerable<FailedItem> allFailedItems, OrphanDocumentsReaderMode mode, out IEnumerable<FailedItem> relatedCases);

        IEnumerable<FailedSchedule> GetFailedScheduleDetails(IEnumerable<FailedItem> allFailedItems);

        IEnumerable<DownloadListArtefact> DownloadListArtefacts(IEnumerable<FailedItem> allFailedItems, ArtifactInclusion artefactInclusionOption);
        IEnumerable<FailedItem> GetRecoverable(DataSourceType dataSourceType, IEnumerable<long> recoverableIds);

        Task<IEnumerable<object>> GetAllUnrecoverableArtifacts(ArtifactInclusion artifactInclusionOption);
    }

    public enum OrphanDocumentsReaderMode
    {
        CountTowardsCase,
        ForRecovery
    }

    public class ScheduleRecoverableReader : IScheduleRecoverableReader
    {
        readonly IRecoveryScheduleStatusReader _recoveryScheduleStatusReader;
        readonly IRepository _repository;

        public ScheduleRecoverableReader(IRepository repository, IRecoveryScheduleStatusReader recoveryScheduleStatusReader)
        {
            _repository = repository;
            _recoveryScheduleStatusReader = recoveryScheduleStatusReader;
        }

        public IQueryable<FailedItem> GetAll(ArtifactInclusion artifact = ArtifactInclusion.Include)
        {
            var allRecoverable = _repository.Set<ScheduleRecoverable>();

            var caseNotifications = _repository.Set<CaseNotification>()
                                               .Where(_ => _.Type == CaseNotificateType.CaseUpdated)
                                               .Select(_ => _.CaseId);

            var cases = _repository.Set<Case>()
                                   .Where(_ => !caseNotifications.Contains(_.Id));

            var documents = _repository.Set<Document>()
                                       .Where(_ => _.Status == DocumentDownloadStatus.Failed)
                                       .AsQueryable();

            var exclude = artifact == ArtifactInclusion.Exclude;

            return from r in allRecoverable
                   join c in cases on r.CaseId equals c.Id into tempCases
                   from tempc in tempCases.DefaultIfEmpty()
                   join d in documents on r.DocumentId equals d.Id into tempDocuments
                   from tempd in tempDocuments.DefaultIfEmpty()
                   where (tempc != null || tempd != null) && !r.ScheduleExecution.Schedule.IsDeleted
                   let isCase = tempc != null
                   select new FailedItem
                   {
                       ArtifactType = isCase ? ArtifactType.Case : ArtifactType.Document,
                       ArtifactId = isCase ? tempc.Id : tempd.Id,
                       ApplicationNumber = isCase ? tempc.ApplicationNumber : tempd.ApplicationNumber,
                       RegistrationNumber = isCase ? tempc.RegistrationNumber : tempd.RegistrationNumber,
                       PublicationNumber = isCase ? tempc.PublicationNumber : tempd.PublicationNumber,
                       CorrelationId = r.ScheduleExecution.CorrelationId ?? "*",
                       DocumentDescription = isCase ? null : tempd.DocumentDescription,
                       FileWrapperDocumentCode = isCase ? null : tempd.FileWrapperDocumentCode,
                       MailRoomDate = isCase ? null : (DateTime?) tempd.MailRoomDate,
                       UpdatedOn = isCase ? null : (DateTime?) tempd.UpdatedOn,
                       ScheduleId = r.ScheduleExecution.Schedule.ParentId ?? r.ScheduleExecution.Schedule.Id,
                       Id = r.Id,
                       DataSourceType = r.ScheduleExecution.Schedule.DataSourceType,
                       Artifact = exclude ? null : r.Blob
                   };
        }

        public IEnumerable<FailedItem> GetAllFor(DataSourceType[] dataSourceTypes, ArtifactInclusion withArtifact = ArtifactInclusion.Include)
        {
            var allFailedItems = GetAll(withArtifact)
                                 .Where(_ => dataSourceTypes.Contains(_.DataSourceType))
                                 .ToArray();

            var mode = OrphanDocumentsReaderMode.CountTowardsCase;
            if (withArtifact == ArtifactInclusion.Include)
            {
                mode = OrphanDocumentsReaderMode.ForRecovery;
            }

            IEnumerable<FailedItem> relatedCases;
            var orphanedDocs = OrphanDocuments(allFailedItems, mode, out relatedCases)
                .ToArray();

            return allFailedItems.Where(_ => _.ArtifactType == ArtifactType.Case)
                                 .Union(relatedCases)
                                 .Union(orphanedDocs);
        }

        public IEnumerable<FailedItem> GetRecoverable(DataSourceType dataSourceType, IEnumerable<long> recoverableIds)
        {
            var ids = recoverableIds.ToArray();
            if (ids.Any())
            {
                return GetAll()
                       .Where(_ => _.DataSourceType == dataSourceType && _.Id.HasValue && ids.Contains(_.Id.Value))
                       .ToArray();
            }

            return new FailedItem[0];
        }

        public IEnumerable<FailedItem> OrphanDocuments(IEnumerable<FailedItem> allFailedItems, OrphanDocumentsReaderMode mode, out IEnumerable<FailedItem> relatedCases)
        {
            var cases = _repository.Set<Case>();
            var failedDocuments = allFailedItems.Where(_ => _.ArtifactType == ArtifactType.Document);

            var docs = (from doc in failedDocuments
                        join c in cases on new {doc.ApplicationNumber, doc.RegistrationNumber, doc.PublicationNumber} equals new {c.ApplicationNumber, c.RegistrationNumber, c.PublicationNumber} into tempCases
                        from tempc in tempCases.DefaultIfEmpty()
                        select new FailedItem
                        {
                            Id = mode == OrphanDocumentsReaderMode.ForRecovery ? doc.Id : null,
                            ArtifactId = mode == OrphanDocumentsReaderMode.ForRecovery ? doc.ArtifactId : null,
                            ApplicationNumber = tempc != null ? tempc.ApplicationNumber : doc.ApplicationNumber,
                            PublicationNumber = tempc != null ? tempc.PublicationNumber : doc.PublicationNumber,
                            RegistrationNumber = tempc != null ? tempc.RegistrationNumber : doc.RegistrationNumber,
                            ScheduleId = doc.ScheduleId,
                            CorrelationId = doc.CorrelationId,
                            ArtifactType = tempc != null ? ArtifactType.Case : ArtifactType.Document,
                            DataSourceType = doc.DataSourceType,
                            Artifact = doc.Artifact
                        }).ToList();

            relatedCases = docs.Where(_ => _.ArtifactType == ArtifactType.Case).Distinct();

            return docs.Where(_ => _.ArtifactType == ArtifactType.Document);
        }

        public IEnumerable<FailedSchedule> GetFailedScheduleDetails(IEnumerable<FailedItem> allFailedItems)
        {
            var failedItems = allFailedItems as FailedItem[] ?? allFailedItems.ToArray();

            var failedScheduleDetails = failedItems.Select(_ => new FailedSchedule {ScheduleId = _.ScheduleId, DataSource = _.DataSourceType})
                                                   .DistinctBy(s => new {s.ScheduleId})
                                                   .ToArray();

            var scheduleIds = failedScheduleDetails.Select(f => f.ScheduleId)
                                                   .Distinct();

            var schedules = _repository.Set<Schedule>()
                                       .Where(_ => scheduleIds.Contains(_.Id))
                                       .ToArray();

            foreach (var failedSchedule in failedScheduleDetails)
            {
                var scheduleFound = schedules.Single(_ => _.Id == failedSchedule.ScheduleId);
                failedSchedule.Name = scheduleFound.Name;
                failedSchedule.AggregateFailures = scheduleFound.Type == ScheduleType.Continuous;
                var schedule = failedSchedule;
                failedSchedule.FailedCasesCount = failedItems.Where(_ => schedule.DataSource == _.DataSourceType && (_.ScheduleId == schedule.ScheduleId || failedSchedule.AggregateFailures)).DistinctBy(_ => new {_.ArtifactId, _.ArtifactType}).DistinctBy(_ => new {_.ApplicationNumber, _.PublicationNumber, _.RegistrationNumber}).Count();
                failedSchedule.CorrelationIds = string.Join(",", failedItems.Where(_ => _.ScheduleId == failedSchedule.ScheduleId)
                                                                            .Where(_ => !string.IsNullOrEmpty(_.CorrelationId) && _.CorrelationId != "*")
                                                                            .Select(_ => _.CorrelationId)
                                                                            .Distinct()
                                                                            .ToArray());
                failedSchedule.RecoveryStatus = _recoveryScheduleStatusReader.Read(failedSchedule.ScheduleId);

                yield return failedSchedule;
            }
        }

        public IEnumerable<DownloadListArtefact> DownloadListArtefacts(IEnumerable<FailedItem> allFailedItems, ArtifactInclusion artefactInclusionOption)
        {
            if (artefactInclusionOption == ArtifactInclusion.Exclude)
            {
                return Enumerable.Empty<DownloadListArtefact>();
            }

            var allRecoverableIds = allFailedItems.Select(_ => _.Id).Distinct();
            var recoverables = _repository.Set<ScheduleRecoverable>()
                                          .Where(_ => allRecoverableIds.Contains(_.Id));

            return (from sea in _repository.Set<ScheduleExecutionArtifact>()
                    where sea.Blob != null && sea.CaseId == null
                    join r in recoverables on sea.ScheduleExecutionId equals r.ScheduleExecutionId into r1
                    from r in r1.DefaultIfEmpty()
                    where r != null
                    select new DownloadListArtefact
                    {
                        Started = r.ScheduleExecution.Started,
                        ExecutionId = r.ScheduleExecutionId,
                        DataSourceType = r.ScheduleExecution.Schedule.DataSourceType,
                        ExecutionArtefact = sea.Blob
                    }).Distinct();
        }

        public async Task<IEnumerable<object>> GetAllUnrecoverableArtifacts(ArtifactInclusion artifactInclusionOption)
        {
            var unrecoverable = (from ur in _repository.Set<UnrecoverableArtefact>()
                                 select new
                                 {
                                     id = ur.Id,
                                     artifact = artifactInclusionOption == ArtifactInclusion.Include ? ur.Artefact : null,
                                     scheduleExecutionId = ur.ScheduleExecutionId,
                                     lastUpdate = ur.LastUpdated
                                 }).ToArrayAsync();

            return await unrecoverable;
        }
    }
}