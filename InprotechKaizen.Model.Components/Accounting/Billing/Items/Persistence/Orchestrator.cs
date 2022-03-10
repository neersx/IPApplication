using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Contracts;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public interface IOrchestrator
    {
        Task<SaveOpenItemResult> SaveNewDraftBill(int userIdentityId, string culture, OpenItemModel model, Guid requestId);
        
        Task<SaveOpenItemResult> UpdateDraftBill(int userIdentityId, string culture, OpenItemModel model, Guid requestId);
        
        Task<SaveOpenItemResult> FinaliseDraftBill(int userIdentityId, string culture, OpenItemModel model, Guid requestId, 
                                                   BillGenerationTracking trackingDetails, bool sendFinalisedBillToReviewer);

        Task PrintBills(int userIdentityId, string culture, IEnumerable<BillGenerationRequest> bills, BillGenerationTracking trackingDetails, bool sendFinalisedBillToReviewer);

        Task GenerateCreditBill(int userIdentityId, string culture, IEnumerable<BillGenerationRequest> bills, BillGenerationTracking trackingDetails);
    }

    public class Orchestrator : IOrchestrator
    {
        readonly IDbContext _dbContext;
        readonly IBillingSiteSettingsResolver _siteSettingsResolver;
        readonly IEnumerable<INewDraftBill> _newDraftBillPersistenceComponents;
        readonly IEnumerable<IUpdateDraftBill> _updateDraftBillPersistenceComponents;
        readonly IEnumerable<IFinaliseDraftBill> _finaliseDraftBillPersistenceComponents;
        readonly IBillProductionJobDispatcher _billProductionJobDispatcher;
        readonly ILogger<Orchestrator> _logger;

        public Orchestrator(
            IDbContext dbContext,
            IBillingSiteSettingsResolver siteSettingsResolver,
            IEnumerable<INewDraftBill> newDraftBillPersistenceComponents,
            IEnumerable<IUpdateDraftBill> updateDraftBillPersistenceComponents,
            IEnumerable<IFinaliseDraftBill> finaliseDraftBillPersistenceComponents,
            IBillProductionJobDispatcher billProductionJobDispatcher,
            ILogger<Orchestrator> logger)
        {
            _dbContext = dbContext;
            _siteSettingsResolver = siteSettingsResolver;
            _newDraftBillPersistenceComponents = newDraftBillPersistenceComponents;
            _updateDraftBillPersistenceComponents = updateDraftBillPersistenceComponents;
            _finaliseDraftBillPersistenceComponents = finaliseDraftBillPersistenceComponents;
            _billProductionJobDispatcher = billProductionJobDispatcher;
            _logger = logger;
        }

        public async Task<SaveOpenItemResult> SaveNewDraftBill(int userIdentityId, string culture, OpenItemModel model, Guid requestId)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (model.ItemEntityId == null) throw new ArgumentException(nameof(model.ItemEntityId));

            var result = new SaveOpenItemResult(requestId);

            _logger.SetContext(requestId);
            _logger.Trace($"{nameof(SaveNewDraftBill)}:Start", model);

            var settings = await _siteSettingsResolver.Resolve(new BillingSiteSettingsScope
            {
                Scope = SettingsResolverScope.IncludeUserSpecificSettings,
                UserIdentityId = userIdentityId
            });
            
            using var transaction = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled);

            var persistenceComponents = _newDraftBillPersistenceComponents.OrderBy(_ => _.Stage);

            foreach (var component in persistenceComponents)
            {
                component.SetLogContext(requestId);
                if (!await component.Run(userIdentityId, culture, settings, model, result) || result.HasError)
                {
                    break;
                }
            }

            if (!result.HasError) transaction.Complete();
                
            _logger.Trace($"{nameof(SaveNewDraftBill)}:{(result.HasError?"Error" : "Completed")}", result);
            
            return result;
        }

        public async Task<SaveOpenItemResult> UpdateDraftBill(int userIdentityId, string culture, OpenItemModel model, Guid requestId)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (model.ItemEntityId == null) throw new ArgumentException(nameof(model.ItemEntityId));

            var result = new SaveOpenItemResult(requestId);
            
            _logger.SetContext(requestId);
            _logger.Trace($"{nameof(UpdateDraftBill)}:Start", model);

            var settings = await _siteSettingsResolver.Resolve(new BillingSiteSettingsScope
            {
                Scope = SettingsResolverScope.IncludeUserSpecificSettings,
                UserIdentityId = userIdentityId
            });

            using var transaction = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled);

            var persistenceComponents = _updateDraftBillPersistenceComponents.OrderBy(_ => _.Stage);

            foreach (var component in persistenceComponents)
            {
                component.SetLogContext(requestId);
                if (!await component.Run(userIdentityId, culture, settings, model, result) || result.HasError)
                {
                    break;
                }
            }

            if (!result.HasError) transaction.Complete();

            _logger.Trace($"{nameof(UpdateDraftBill)}:{(result.HasError?"Error" : "Completed")}", result);

            return result;
        }

        public async Task<SaveOpenItemResult> FinaliseDraftBill(int userIdentityId, string culture, OpenItemModel model, Guid requestId, BillGenerationTracking trackingDetails, bool shouldSendBillsToReviewer)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (trackingDetails == null) throw new ArgumentNullException(nameof(trackingDetails));
            if (model.ItemEntityId == null) throw new ArgumentException(nameof(model.ItemEntityId));
            if (model.ItemTransactionId == null) throw new ArgumentException(nameof(model.ItemTransactionId));
            
            var result = new SaveOpenItemResult(requestId);
            
            _logger.SetContext(requestId);
            _logger.Trace($"{nameof(FinaliseDraftBill)}:Start", model);

            var siteSettings = await _siteSettingsResolver.Resolve(new BillingSiteSettingsScope
                                                               {
                                                                   Scope = SettingsResolverScope.IncludeUserSpecificSettings,
                                                                   UserIdentityId = userIdentityId
                                                               },
                                                               new Dictionary<string, object>
                                                               {
                                                                   { AdditionalBillingOptions.SendFinalisedBillToReviewer, shouldSendBillsToReviewer },
                                                                   { AdditionalBillingOptions.BillGenerationTracking, trackingDetails }
                                                               });

            using var transaction = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled);

            var persistenceComponents = _finaliseDraftBillPersistenceComponents.OrderBy(_ => _.Stage);

            foreach (var component in persistenceComponents)
            {
                component.SetLogContext(requestId);
                if (!await component.Run(userIdentityId, culture, siteSettings, model, result) || result.HasError)
                {
                    break;
                }
            }

            if (!result.HasError) transaction.Complete();

            _logger.Trace($"{nameof(FinaliseDraftBill)}:{(result.HasError?"Error" : "Completed")}", result);

            return result;
        }

        public async Task GenerateCreditBill(int userIdentityId, string culture, IEnumerable<BillGenerationRequest> bills, BillGenerationTracking trackingDetails)
        {
            _logger.SetContext(trackingDetails.RequestContextId);
            _logger.Trace($"{nameof(GenerateCreditBill)}:Start", bills);

            /*
             * This is the 'after process' for Credit Bill where it creates the bill using reporting services.
             * Credit Bill logic is in XFOP area untouched.
             *
             * There is also no reason why the 'Send Bills To Reviewer' should not extend to this Credit Bill functionality.
             */

            await _billProductionJobDispatcher.Dispatch(userIdentityId, culture, trackingDetails,
                                                        BillProductionType.ProductionDuringFinalisePhase, new Dictionary<string, object>(), bills.ToArray());

            _logger.Trace($"{nameof(GenerateCreditBill)}:Dispatched");
        }

        public async Task PrintBills(int userIdentityId, string culture, IEnumerable<BillGenerationRequest> bills, BillGenerationTracking trackingDetails, bool shouldSendBillsToReviewer)
        {
            _logger.SetContext(trackingDetails.RequestContextId);
            _logger.Trace($"{nameof(PrintBills)}:Start", bills);

            var options = new Dictionary<string, object>
            {
                { AdditionalBillingOptions.SendFinalisedBillToReviewer, shouldSendBillsToReviewer },
                { AdditionalBillingOptions.BillGenerationTracking, trackingDetails }
            };

            await _billProductionJobDispatcher.Dispatch(userIdentityId, culture, trackingDetails,
                                                        BillProductionType.ProductionDuringPrintPhase, options, bills.ToArray());

            _logger.Trace($"{nameof(PrintBills)}:Dispatched");
        }
    }
}
