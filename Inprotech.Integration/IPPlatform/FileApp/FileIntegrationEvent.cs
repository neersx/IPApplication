using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    public interface IFileIntegrationEvent
    {
        Task AddOrUpdate(int caseId, FileSettings fileSetting);

        Task Clear(int caseId, FileSettings fileSettings);
    }

    public class FileIntegrationEvent : IFileIntegrationEvent
    {
        readonly IBatchPolicingRequest _batchPolicingRequest;
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;
        readonly IPolicingEngine _policingEngine;
        readonly ISiteConfiguration _siteConfiguration;
        readonly ITransactionRecordal _transactionRecordal;

        public FileIntegrationEvent(IDbContext dbContext,
                                    IPolicingEngine policingEngine,
                                    IBatchPolicingRequest batchPolicingRequest,
                                    ITransactionRecordal transactionRecordal,
                                    ISiteConfiguration siteConfiguration,
                                    Func<DateTime> now)
        {
            _dbContext = dbContext;
            _policingEngine = policingEngine;
            _batchPolicingRequest = batchPolicingRequest;
            _transactionRecordal = transactionRecordal;
            _siteConfiguration = siteConfiguration;
            _now = now;
        }

        public async Task AddOrUpdate(int caseId, FileSettings fileSettings)
        {
            if (fileSettings == null) throw new ArgumentNullException(nameof(fileSettings));
            if (!fileSettings.FileIntegrationEvent.HasValue) throw new InvalidOperationException("Integration Event is null");

            var @case = await _dbContext.Set<InprotechKaizen.Model.Cases.Case>().SingleAsync(_ => _.Id == caseId);

            var reason = _siteConfiguration.ReasonInternalChange;
            var integrationEventId = fileSettings.FileIntegrationEvent.Value;

            _transactionRecordal.RecordTransactionFor(@case, CaseTransactionMessageIdentifier.AmendedCase, reason);

            var integrationEvent = @case.CaseEvents.SingleOrDefault(e => e.EventNo == integrationEventId && e.Cycle == 1);
            if (integrationEvent == null)
            {
                @case.CaseEvents.Add(integrationEvent = new CaseEvent(@case.Id, integrationEventId, 1));
            }

            integrationEvent.EventDate = _now().Date;
            integrationEvent.IsOccurredFlag = 1;

            var policingRequests = new List<PoliceCaseEvent> {new PoliceCaseEvent(integrationEvent)};

            var policingBatchNo = _batchPolicingRequest.Enqueue(policingRequests);

            _dbContext.SaveChanges();

            if (policingBatchNo.HasValue)
            {
                _policingEngine.PoliceAsync(policingBatchNo.Value);
            }
        }

        public async Task Clear(int caseId, FileSettings fileSettings)
        {
            if (fileSettings == null) throw new ArgumentNullException(nameof(fileSettings));
            if (!fileSettings.FileIntegrationEvent.HasValue) throw new InvalidOperationException("Integration Event is null");

            var @case = await (from c in _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                               where c.Id == caseId
                               select c)
                .SingleAsync();

            var integrationEventId = fileSettings.FileIntegrationEvent.Value;
            var integrationEvent = @case.CaseEvents.SingleOrDefault(e => e.EventNo == integrationEventId && e.Cycle == 1);

            if (integrationEvent == null)
            {
                return;
            }

            var reason = _siteConfiguration.ReasonInternalChange;
            _transactionRecordal.RecordTransactionFor(@case, CaseTransactionMessageIdentifier.AmendedCase, reason);

            integrationEvent.EventDate = null;
            integrationEvent.EventDueDate = null;
            integrationEvent.IsOccurredFlag = 0;
            integrationEvent.IsDateDueSaved = 0;

            var policingRequests = new List<PoliceCaseEvent> {new PoliceCaseEvent(integrationEvent)};

            var policingBatchNo = _batchPolicingRequest.Enqueue(policingRequests);

            _dbContext.SaveChanges();

            if (policingBatchNo.HasValue)
            {
                _policingEngine.PoliceAsync(policingBatchNo.Value);
            }
        }
    }
}
