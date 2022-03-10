using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Cases.Comparison.Results;
using InprotechKaizen.Model.Components.Cases.Comparison.Updaters;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Persistence;
using Case = InprotechKaizen.Model.Cases.Case;

namespace InprotechKaizen.Model.Components.Cases.Comparison
{
    public interface IComparisonUpdater
    {
        Task ApplyChanges(CaseComparisonSave saveData);
    }

    public class ComparisonUpdater : IComparisonUpdater
    {
        readonly IBatchPolicingRequest _batchPolicingRequest;
        readonly ICaseNameUpdator _caseNameUpdator;
        readonly ICaseComparisonEvent _caseComparisonEvent;
        readonly IImportCaseImages _caseImageImporter;
        readonly ICaseUpdater _caseUpdater;
        readonly IDbContext _dbContext;
        readonly IEventUpdater _eventUpdater;
        readonly IGoodsServicesUpdater _goodsServicesUpdater;
        readonly IOfficialNumberUpdater _officialNumberUpdater;
        readonly IPolicingEngine _policingEngine;
        readonly ISiteConfiguration _siteConfiguration;
        readonly IComponentResolver _componentResolver;
        readonly ITransactionRecordal _transactionRecordal;

        public ComparisonUpdater(IDbContext dbContext,
                                 ICaseUpdater caseUpdater, IOfficialNumberUpdater officialNumberUpdater,
                                 IGoodsServicesUpdater goodsServicesUpdater, IEventUpdater eventUpdater, IPolicingEngine policingEngine,
                                 ITransactionRecordal transactionRecordal, ISiteConfiguration siteConfiguration,
                                 ICaseComparisonEvent caseComparisonEvent, IImportCaseImages caseImageImporter,
                                 IBatchPolicingRequest batchPolicingRequest, ICaseNameUpdator caseNameUpdator, IComponentResolver componentResolver)
        {
            _dbContext = dbContext;
            _caseUpdater = caseUpdater;
            _officialNumberUpdater = officialNumberUpdater;
            _goodsServicesUpdater = goodsServicesUpdater;
            _eventUpdater = eventUpdater;
            _policingEngine = policingEngine;
            _transactionRecordal = transactionRecordal;
            _siteConfiguration = siteConfiguration;
            _caseComparisonEvent = caseComparisonEvent;
            _caseImageImporter = caseImageImporter;
            _batchPolicingRequest = batchPolicingRequest;
            _caseNameUpdator = caseNameUpdator;
            _componentResolver = componentResolver;
        }

        public async Task ApplyChanges(CaseComparisonSave saveData)
        {
            if (saveData == null) throw new ArgumentNullException(nameof(saveData));

            var caseId = saveData.CaseId;

            var @case = _dbContext.Set<Case>()
                                  .Include(c => c.OpenActions)
                                  .Include(c => c.OpenActions.Select(_ => _.Criteria))
                                  .Include(c => c.OfficialNumbers)
                                  .Include(c => c.CaseNames)
                                  .Include(c => c.OfficialNumbers.Select(_ => _.NumberType))
                                  .Include(c => c.CaseEvents)
                                  .Include(c => c.CaseTexts)
                                  .Include(c => c.ClassFirstUses)
                                  .Include(c => c.TypeOfMark)
                                  .Single(c => c.Id == caseId);

            using (var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var reasonNo = _siteConfiguration.TransactionReason
                    ? _siteConfiguration.ReasonIpOfficeVerification
                    : null;

                _transactionRecordal.RecordTransactionFor(@case, CaseTransactionMessageIdentifier.AmendedCase, reasonNo, componentId: _componentResolver.Resolve(KnownComponents.CaseComparison));

                var policingRequests = new List<PoliceCaseEvent>();

                _caseUpdater.UpdateTitle(@case, saveData.Case);
                _caseUpdater.UpdateTypeOfMark(@case, saveData.Case);

                if (saveData.OfficialNumbers.Any())
                {
                    policingRequests.AddRange(
                                              _officialNumberUpdater.AddOrUpdateOfficialNumbers(@case, saveData.OfficialNumbers));
                }

                if (saveData.CaseNames.Any())
                {
                    _caseNameUpdator.UpdateNameReferences(@case, saveData.CaseNames);
                }

                if (saveData.GoodsServices.Any())
                {
                    _goodsServicesUpdater.Update(@case, saveData.GoodsServices);
                }

                if (saveData.Events.Any())
                {
                    policingRequests.AddRange(_eventUpdater.AddOrUpdateEvents(@case, saveData.Events));
                }

                if (saveData.ImportImage)
                {
                    await _caseImageImporter.Import(saveData.NotificationId, caseId, @case.Title);
                }

                policingRequests.Add(_caseComparisonEvent.Apply(@case));

                var policingBatchNo = _batchPolicingRequest.Enqueue(policingRequests);

                _dbContext.SaveChanges();

                if (policingBatchNo.HasValue)
                {
                    _policingEngine.PoliceAsync(policingBatchNo.Value);
                }

                tcs.Complete();
            }
        }
    }
}