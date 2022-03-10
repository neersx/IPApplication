using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules.Extensions;
using Newtonsoft.Json;

namespace Inprotech.Integration.Schedules
{
    [Authorize]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleUsptoTsdrDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleEpoDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleIpOneDataDownload)]
    [RequiresAccessTo(ApplicationTask.ScheduleFileDataDownload)]
    [ViewInitialiser]
    public class ScheduleViewController : ApiController
    {
        readonly IDataSourceSchedule _dataSourceSchedule;
        readonly IRecoverableItems _recoverableItems;
        readonly IRecoveryScheduleStatusReader _recoveryScheduleStatusReader;
        readonly IRepository _repository;
        readonly IScheduleExecutions _scheduleExecutions;
        readonly IIndex<DataSourceType, IScheduleMessages> _scheduleMessages;
        readonly ISiteControlReader _siteControlReader;

        public ScheduleViewController(IRepository repository, IDataSourceSchedule dataSourceSchedule,
                                      IScheduleExecutions scheduleExecutions, IRecoverableItems recoverableItems,
                                      IRecoveryScheduleStatusReader recoveryScheduleStatusReader, IIndex<DataSourceType, IScheduleMessages> scheduleMessages,
                                      ISiteControlReader siteControlReader)
        {
            _repository = repository;
            _dataSourceSchedule = dataSourceSchedule;
            _scheduleExecutions = scheduleExecutions;
            _recoverableItems = recoverableItems;
            _recoveryScheduleStatusReader = recoveryScheduleStatusReader;
            _scheduleMessages = scheduleMessages;
            _siteControlReader = siteControlReader;
        }

        [Route("api/ptoaccess/scheduleview")]
        public async Task<dynamic> Get(int id)
        {
            var schedule = await _repository.Set<Schedule>()
                                      .SingleAsync(s => s.Id == id);
            
            ScheduleMessage messageData = null;
            if (_scheduleMessages.TryGetValue(schedule.DataSourceType, out var messageResolver))
            {
                messageData = messageResolver.Resolve(schedule.Id);
            }

            if (schedule.State == ScheduleState.Disabled)
            {
                return new
                {
                    Schedule = _dataSourceSchedule.View(schedule),
                    RecoverableCasesCount = 0,
                    RecoverableCases = new RecoverableCase[0],
                    RecoverableDocuments = new RecoverableDocument[0],
                    RecoverableDocumentsCount = 0,
                    RecoveryScheduleStatus = string.Empty,
                    ScheduleMessage = messageData
                };
            }

            var recoverableItems = schedule.Type == ScheduleType.Continuous ? _recoverableItems.FindByDataType(schedule.DataSourceType).ToArray() : _recoverableItems.FindBySchedule(id).ToArray();

            var caseIds = recoverableItems
                          .SelectMany(_ => _.CaseIds)
                          .Distinct()
                          .ToArray();

            var documentIds = recoverableItems
                              .SelectMany(_ => _.DocumentIds)
                              .Distinct()
                              .ToArray();

            var orphanedDocumentIds = recoverableItems
                                      .SelectMany(_ => _.OrphanedDocumentIds)
                                      .Distinct()
                                      .ToArray();

            var recoverableCases = new RecoverableCase[0];

            if (caseIds.Any())
            {
                recoverableCases = await _repository.Set<Case>()
                                              .Where(_ => caseIds.Contains(_.Id))
                                              .Select(_ => new RecoverableCase
                                              {
                                                  ApplicationNumber = _.ApplicationNumber,
                                                  PublicationNumber = _.PublicationNumber,
                                                  RegistrationNumber = _.RegistrationNumber,
                                                  CaseId = _.Id
                                              })
                                              .ToArrayAsync();
            }

            var recoverableDocuments = new RecoverableDocument[0];
            var recoverableCaseWithoutId = recoverableItems
                                           .SelectMany(_ => _.CaseWithoutArtifactId)
                                           .DistinctBy(_ => new { _.ArtifactId, _.ArtifactType, _.ScheduleId, _.CorrelationId })
                                           .Select(_ => new RecoverableCase
                                           {
                                               ApplicationNumber = _.ApplicationNumber,
                                               PublicationNumber = _.PublicationNumber,
                                               RegistrationNumber = _.RegistrationNumber
                                           }).ToArray();

            recoverableCases = recoverableCases.Concat(recoverableCaseWithoutId).ToArray();

            if (documentIds.Any())
            {
                recoverableDocuments = await _repository.Set<Document>()
                                                  .Where(_ => documentIds.Contains(_.Id))
                                                  .Select(_ => new RecoverableDocument
                                                  {
                                                      ApplicationNumber = _.ApplicationNumber,
                                                      DocumentId = _.Id,
                                                      MailRoomDate = _.MailRoomDate,
                                                      UpdatedOn = _.UpdatedOn,
                                                      DocumentCode = _.FileWrapperDocumentCode,
                                                      DocumentDescription = _.DocumentDescription,
                                                      RegistrationNumber = _.RegistrationNumber,
                                                      PublicationNumber = _.PublicationNumber
                                                  })
                                                  .ToArrayAsync();
            }

            if (orphanedDocumentIds.Any())
            {
                var orphanedDocuments = await _repository.Set<Document>()
                                                   .Where(_ => orphanedDocumentIds.Contains(_.Id))
                                                   .Select(_ => new RecoverableCase
                                                   {
                                                       ApplicationNumber = _.ApplicationNumber,
                                                       PublicationNumber = _.PublicationNumber,
                                                       RegistrationNumber = _.RegistrationNumber,
                                                       DocumentId = _.Id
                                                   })
                                                   .ToArrayAsync();

                recoverableCases = recoverableCases.Concat(orphanedDocuments).ToArray();
            }

            recoverableCases = recoverableCases.Distinct(new RecoverableCaseComparer()).ToArray();

            foreach (var @case in recoverableCases)
            {
                @case.CorrelationIds =
                    recoverableItems.CorrelationshipOf(@case.CaseId, @case.DocumentId).AsString();
            }
            
            var missingBackgroundProcessLoginId = string.IsNullOrWhiteSpace(_siteControlReader.Read<string>(SiteControls.BackgroundProcessLoginId));

            return new
            {
                Schedule = _dataSourceSchedule.View(schedule),
                RecoverableCasesCount = recoverableCases.Length,
                RecoverableCases = recoverableCases,
                RecoverableDocuments = recoverableDocuments,
                RecoverableDocumentsCount = recoverableDocuments.Length,
                RecoveryScheduleStatus = _recoveryScheduleStatusReader.Read(id).ToString(),
                ScheduleMessage = messageData,
                missingBackgroundProcessLoginId
            };
        }

        public class RecoverableCase
        {
            [JsonIgnore]
            public int? CaseId { get; set; }

            [JsonIgnore]
            public int? DocumentId { get; set; }

            public string ApplicationNumber { get; set; }

            public string PublicationNumber { get; set; }

            public string RegistrationNumber { get; set; }

            public string CorrelationIds { get; set; }
        }

        public class RecoverableDocument
        {
            [JsonIgnoreAttribute]
            public int? CaseId { get; set; }

            [JsonIgnore]
            public int? DocumentId { get; set; }

            public string ApplicationNumber { get; set; }

            public string RegistrationNumber { get; set; }

            public string PublicationNumber { get; set; }

            public string DocumentDescription { get; set; }

            public string DocumentCode { get; set; }

            public DateTime? MailRoomDate { get; set; }
            public DateTime UpdatedOn { get; set; }
        }

        public class RecoverableCaseComparer : IEqualityComparer<RecoverableCase>
        {
            public bool Equals(RecoverableCase x, RecoverableCase y)
            {
                if (ReferenceEquals(x, y)) return true;

                if (x == null || y == null) return false;

                return x.ApplicationNumber == y.ApplicationNumber
                       && x.PublicationNumber == y.PublicationNumber
                       && x.RegistrationNumber == y.RegistrationNumber;
            }

            public int GetHashCode(RecoverableCase obj)
            {
                return new
                {
                    obj.ApplicationNumber,
                    obj.PublicationNumber,
                    obj.RegistrationNumber
                }.GetHashCode();
            }
        }
    }
}