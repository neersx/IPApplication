using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;
using FileCaseEntity = InprotechKaizen.Model.Integration.FileCase;

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class DetailsUnavailableOrInvalid
    {
        readonly IBufferedStringReader _bufferedStringReader;
        readonly IFileInstructAllowedCases _fileInstructAllowedCases;
        readonly IFileIntegrationEvent _fileIntegrationEvent;
        readonly IFileSettingsResolver _fileSettingsResolver;
        readonly IRepository _repository;
        readonly IDbContext _dbContext;
        readonly IScheduleRuntimeEvents _runtimeEvents;

        public DetailsUnavailableOrInvalid(IRepository repository,
                                           IDbContext dbContext,
                                           IScheduleRuntimeEvents runtimeEvents,
                                           IFileSettingsResolver fileSettingsResolver,
                                           IFileInstructAllowedCases fileInstructAllowedCases,
                                           IFileIntegrationEvent fileIntegrationEvent,
                                           IBufferedStringReader bufferedStringReader)
        {
            _repository = repository;
            _dbContext = dbContext;
            _runtimeEvents = runtimeEvents;
            _fileSettingsResolver = fileSettingsResolver;
            _fileInstructAllowedCases = fileInstructAllowedCases;
            _fileIntegrationEvent = fileIntegrationEvent;
            _bufferedStringReader = bufferedStringReader;
        }

        public async Task Handle(Guid sessionGuid, int[] inprotechCaseIds, string listPath)
        {
            var fileSetting = _fileSettingsResolver.Resolve();

            var fileCases = JsonConvert.DeserializeObject<FileCase[]>(await _bufferedStringReader.Read(listPath));

            var current = (from iac in _fileInstructAllowedCases.Retrieve(fileSetting)
                           where inprotechCaseIds.Contains(iac.CaseId)
                           group iac by iac.ParentCaseId
                           into g1
                           select new
                           {
                               ParentCaseId = g1.Key,
                               Cases = g1
                           }).ToArray();

            var casesWithRogueIntegrationEvents = new List<(int caseId, string ipType)>();

            foreach (var c in current)
            {
                var parentCaseId = c.ParentCaseId.ToString();
                var fileCase = fileCases.FirstOrDefault(_ => _.Id == parentCaseId);

                if (fileCase == null)
                {
                    casesWithRogueIntegrationEvents
                        .AddRange(c.Cases
                                   .Where(_ => _.ParentCaseId == c.ParentCaseId)
                                   .Select(_ => (_.CaseId, _.IpType)));

                    continue;
                }

                foreach (var child in c.Cases)
                {
                    if (fileCase.Countries.All(_ => _.Code != child.CountryCode))
                    {
                        casesWithRogueIntegrationEvents.Add((child.CaseId, child.IpType));
                    }
                }
            }

            if (fileSetting.FileIntegrationEvent.HasValue)
            {
                foreach (var caseId in casesWithRogueIntegrationEvents.Select(_ => _.caseId))
                    await _fileIntegrationEvent.Clear(caseId, fileSetting);
            }

            var exists = _repository.Set<Case>()
                                    .Where(_ => inprotechCaseIds.Any(c => _.CorrelationId == c) && _.Source == DataSourceType.File)
                                    .Select(_ => _.Id)
                                    .ToArray();

            if (exists.Any())
            {
                await _repository.DeleteAsync(
                                              _repository.Set<CaseNotification>().Where(_ => exists.Contains(_.CaseId)));
            }

            var fileCaseEntities = _dbContext.Set<FileCaseEntity>();
            foreach (var byIpType in casesWithRogueIntegrationEvents.GroupBy(_ => _.ipType))
            {
                var caseIds = byIpType.Select(_ => _.caseId).ToArray();
                await _dbContext.DeleteAsync(
                                             fileCaseEntities.Where(_ => _.IpType == byIpType.Key && caseIds.Contains(_.CaseId)));
            }

            _runtimeEvents.UpdateCasesProcessed(sessionGuid, exists);
        }
    }
}