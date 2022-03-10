using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Autofac;
using Inprotech.Integration;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Storage;

namespace Inprotech.IntegrationServer.PtoAccess
{
    public interface IPtoAccessCase
    {
        void Update(string path, Case @case, string hash, EligibleCase eligibleCase = null);

        CaseNotification CreateOrUpdateNotification(Case @case, string title);

        Task EnsureAvailable(EligibleCase eligibleCases);

        Task EnsureAvailableDetached(params EligibleCase[] eligibleCases);

        void AddCaseFile(EligibleCase eligibleCase, CaseFileType type, string path, string fileName, bool removeExistingFiles = false, string mediaType = null);

        bool CaseFileExists(int caseKey, DataSourceType dataSource, CaseFileType caseFileType);
    }

    public class PtoAccessCase : IPtoAccessCase
    {
        readonly Func<DateTime> _now;
        IRepository _repository;

        public PtoAccessCase(IRepository repository, Func<DateTime> now)
        {
            _repository = repository;
            _now = now;
        }

        public void Update(string path, Case @case, string hash, EligibleCase eligibleCase = null)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentNullException(nameof(path));
            if (string.IsNullOrWhiteSpace(hash)) throw new ArgumentNullException(nameof(hash));

            @case.Version = hash;
            @case.UpdatedOn = _now();
            @case.FileStore = new FileStore
            {
                OriginalFileName = PtoAccessFileNames.CpaXml,
                Path = path
            };

            if (eligibleCase == null) return;

            @case.CorrelationId = eligibleCase.CaseKey;
            @case.ApplicationNumber = eligibleCase.ApplicationNumber;
            @case.PublicationNumber = eligibleCase.PublicationNumber;
            @case.RegistrationNumber = eligibleCase.RegistrationNumber;
            @case.Jurisdiction = eligibleCase.CountryCode;
        }

        public bool CaseFileExists(int caseKey, DataSourceType dataSource, CaseFileType caseFileType)
        {
            var @case = _repository.Set<Case>()
                                   .Single(n => n.Source == dataSource &&
                                                n.CorrelationId == caseKey);

            var exists = _repository.Set<CaseFiles>().Any(c => c.CaseId == @case.Id && c.Type == (int) caseFileType);
            return exists;
        }

        public async Task EnsureAvailable(EligibleCase eligibleCases)
        {
            BuildCaseData(eligibleCases.SystemCode, new[] { eligibleCases });

            await _repository.SaveChangesAsync();
        }

        public async Task EnsureAvailableDetached(params EligibleCase[] eligibleCases)
        {
            using (var scope = Configuration.Container.BeginLifetimeScope())
            {
                _repository = scope.Resolve<IRepository>().WithUntrackedContext();
                foreach (var bySource in eligibleCases.GroupBy(_ => _.SystemCode))
                {
                    BuildCaseData(bySource.Key, bySource);

                    await _repository.SaveChangesAsync();
                }
            }
        }

        public void AddCaseFile(EligibleCase eligibleCase, CaseFileType type, string pathAndFileName, string fileName, bool removeExistingFiles = false, string mediaType = null)
        {
            var fileStore = _repository.Set<FileStore>()
                                       .Add(
                                            new FileStore
                                            {
                                                OriginalFileName = fileName,
                                                Path = pathAndFileName,
                                                MediaType = mediaType
                                            });

            var dataSource = ExternalSystems.DataSource(eligibleCase.SystemCode);
            var @case = _repository.Set<Case>()
                                   .Single(n => n.Source == dataSource &&
                                                n.CorrelationId == eligibleCase.CaseKey);

            if (removeExistingFiles)
            {
                var itemsToRemove = _repository.Set<CaseFiles>().Where(c => c.CaseId == @case.Id && c.Type == (int)type).ToArray();
                foreach (var r in itemsToRemove)
                    _repository.Set<CaseFiles>().Remove(r);
            }

            _repository.Set<CaseFiles>()
                       .Add(
                            new CaseFiles
                            {
                                Type = (int)type,
                                CaseId = @case.Id,
                                FileStore = fileStore
                            });

            _repository.SaveChanges();
        }

        public CaseNotification CreateOrUpdateNotification(Case @case, string title)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));

            var notifications = _repository.Set<CaseNotification>();

            var existing = notifications.SingleOrDefault(cn => cn.CaseId == @case.Id);
            DateTime? existingNotificationDate = null;

            if (existing != null)
            {
                existingNotificationDate = existing.CreatedOn;
                notifications.Remove(existing);
            }

            return notifications.Add(new CaseNotification
            {
                Type = CaseNotificateType.CaseUpdated,
                Case = @case,
                Body = title,
                CreatedOn = existingNotificationDate ?? _now(),
                UpdatedOn = _now(),
                IsReviewed = false,
                ReviewedBy = null
            });
        }

        void EnsureCaseAvailable(EligibleCase eligibleCase)
        {
            if (eligibleCase == null) throw new ArgumentNullException(nameof(eligibleCase));

            var dataSource = ExternalSystems.DataSource(eligibleCase.SystemCode);
            var jurisdiction = eligibleCase.CountryCode;
            if (dataSource == DataSourceType.UsptoPrivatePair)
            {
                jurisdiction = null;
            }

            _repository.Set<Case>()
                       .Add(
                            new Case
                            {
                                CorrelationId = eligibleCase.CaseKey,
                                ApplicationNumber = eligibleCase.ApplicationNumber,
                                PublicationNumber = eligibleCase.PublicationNumber,
                                RegistrationNumber = eligibleCase.RegistrationNumber,
                                Jurisdiction = jurisdiction,
                                Source = dataSource,
                                CreatedOn = _now(),
                                UpdatedOn = _now()
                            });
        }

        void BuildCaseData(string key, IEnumerable<EligibleCase> bySource)
        {
            var source = ExternalSystems.DataSource(key);
            var correlationIdMap = bySource.ToDictionary(k => k.CaseKey, v => v);
            var correlationIds = correlationIdMap.Keys.ToArray();

            var exists = _repository.Set<Case>()
                                    .Where(_ => _.CorrelationId != null && _.Source == source)
                                    .Where(_ => correlationIds.Contains(_.CorrelationId.Value))
                                    .Select(_ => _.CorrelationId.Value)
                                    .ToArray();

            foreach (var m in correlationIdMap)
            {
                if (exists.Contains(m.Key))
                    continue;

                EnsureCaseAvailable(m.Value);
            }
        }
    }
}