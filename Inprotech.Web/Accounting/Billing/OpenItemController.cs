using System;
using System.Collections.Generic;
using System.Globalization;
using System.IdentityModel;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Formatting;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.ContentManagement;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Utilities;

namespace Inprotech.Web.Accounting.Billing
{
    [Authorize]
    [NoEnrichment]
    [UseDefaultContractResolver]
    [RoutePrefix("api/accounting/billing")]
    [RequiresLicense(LicensedModule.Billing)]
    [RequiresLicense(LicensedModule.TimeandBillingModule)]
    public class OpenItemController : ApiController
    {
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IRequestContext _requestContext;
        readonly ITempStorageHandler _tempStorageHandler;
        readonly IExportContentService _exportContentService;
        readonly IOpenItemService _openItemService;
        
        public OpenItemController(
            ISecurityContext securityContext, 
            IPreferredCultureResolver preferredCultureResolver, 
            IRequestContext requestContext,
            ITempStorageHandler tempStorageHandler,
            IExportContentService exportContentService,
            IOpenItemService openItemService)
        {
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _requestContext = requestContext;
            _tempStorageHandler = tempStorageHandler;
            _exportContentService = exportContentService;
            _openItemService = openItemService;
        }
        
        [HttpGet]
        [Route("open-item")]
        [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Create)]
        [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Create)]
        public async Task<OpenItemModel> PrepareNewDraft(ItemTypesForBilling itemType)
        {
            var userIdentityId = _securityContext.IdentityId;
            var culture = _preferredCultureResolver.Resolve();
            
            return await _openItemService.PrepareForNewDraftBill(userIdentityId, culture, itemType);
        }
        
        [HttpGet]
        [Route("open-item")]
        [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        public async Task<OpenItemModel> GetOpenItem(int itemEntityId, string openItemNo)
        {
            if (openItemNo == null) throw new ArgumentNullException(nameof(openItemNo));

            var userIdentityId = _securityContext.IdentityId;
            var culture = _preferredCultureResolver.Resolve();
            
            return await _openItemService.RetrieveForExistingBill(userIdentityId, culture, itemEntityId, openItemNo);
        }

        [HttpGet]
        [Route("open-item")]
        [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        public async Task<OpenItemModel> MergeDebitNoteDrafts(string merged)
        {
            if (merged == null) throw new ArgumentNullException(nameof(merged));
            if (merged.Split('|').Length <= 1) throw new ArgumentException("There must be more than one Debit Notes to be merged.");

            var userIdentityId = _securityContext.IdentityId;
            var culture = _preferredCultureResolver.Resolve();
            
            return await _openItemService.MergeSelectedDraftDebitNotes(userIdentityId, culture, merged);
        }

        [HttpPost]
        [Route("open-item")]
        [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        [AppliesToComponent(KnownComponents.Billing)]
        public async Task<SaveOpenItemResult> Save([FromUri]string mode, [FromBody] OpenItemModel model, [FromUri]string connectionId=null)
        {
            if (model == null) throw new ArgumentNullException(nameof(model));
            if (model.ItemEntityId == null) throw new ArgumentException(nameof(model.ItemEntityId));
            
            var userIdentityId = _securityContext.IdentityId;
            var culture = _preferredCultureResolver.Resolve();

            return mode switch
            {
                "create" => await _openItemService.SaveNewDraftBill(userIdentityId, culture, model, _requestContext.RequestId),
                "update" => await _openItemService.UpdateDraftBill(userIdentityId, culture, model, _requestContext.RequestId),
                "finalise" => await FinaliseOpenItem(userIdentityId, culture, model, mode, connectionId),
                "finalise-with-review" => await FinaliseOpenItem(userIdentityId, culture, model, mode, connectionId),
                _ => throw new ArgumentException("unknown command")
            };
        }

        [HttpDelete]
        [Route("open-item/{itemEntityId}/{openItemNo}")]
        [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Delete)]
        [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Delete)]
        [AppliesToComponent(KnownComponents.Billing)]
        public async Task<bool> Delete(int itemEntityId, string openItemNo)
        {
            if (openItemNo == null) throw new ArgumentNullException(nameof(openItemNo));
            
            var userIdentityId = _securityContext.IdentityId;
            var culture = _preferredCultureResolver.Resolve();

            return await _openItemService.DeleteDraftBill(userIdentityId, culture, itemEntityId, openItemNo);
        }

        [HttpGet]
        [Route("open-item/validate")]
        public async Task<dynamic> ValidateItemDate(string itemDate = null, int? itemEntityId = null, int? itemTransactionId = null, string openItemNo = null)
        {
            if (itemDate != null)
            {
                if (!DateTime.TryParseExact(itemDate, "yyyy-MM-dd", DateTimeFormatInfo.InvariantInfo, DateTimeStyles.None, out var parsedItemDate))
                {
                    throw new BadRequestException($"{nameof(itemDate)} is required in yyyy-MM-dd format");
                }

                return await _openItemService.ValidateItemDate(parsedItemDate);
            }

            if (itemEntityId == null) throw new ArgumentNullException(nameof(itemEntityId));
            if (itemTransactionId == null) throw new ArgumentNullException(nameof(itemTransactionId));
            if (openItemNo == null) throw new ArgumentNullException(nameof(openItemNo));

            return _openItemService.ValidateBeforeFinalise(new FinaliseRequest
            {
                ItemEntityId = (int) itemEntityId,
                ItemTransactionId = (int) itemTransactionId,
                OpenItemNo = openItemNo
            });
        }

        [HttpGet]
        [Route("open-item/is-unique")]
        public async Task<bool> ValidateOpenItemNoUnique(string openItemNo)
        {
            return await _openItemService.ValidateOpenItemNoIsUnique(openItemNo);
        }
        
        [HttpPost]
        [Route("open-item/print")]
        [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        [AppliesToComponent(KnownComponents.Billing)]
        public async Task<BillGenerationTracking> Print([FromBody] IEnumerable<BillGenerationRequest> requests, [FromUri]string mode=null, [FromUri]string connectionId=null)
        {
            if (requests == null) throw new ArgumentNullException(nameof(requests));

            // TODO
            // send signalr connectionId from front end.
            // if (connectionId == null) throw new ArgumentNullException(nameof(connectionId));
            connectionId ??= Guid.NewGuid().ToString();
            //
            
            var userIdentityId = _securityContext.IdentityId;
            var culture = _preferredCultureResolver.Resolve();
            var trackingDetails = new BillGenerationTracking
            {
                ConnectionId = connectionId,
                RequestContextId = _requestContext.RequestId,
                ContentId = await _exportContentService.GenerateContentId(connectionId)
            };

            switch (mode)
            {
                case "generate-credit-bill":
                    await _openItemService.GenerateCreditBill(userIdentityId, culture, requests, trackingDetails);
                    break;

                case "with-review":
                    await _openItemService.PrintBills(userIdentityId, culture, requests, trackingDetails, true);
                    break;

                default:
                    await _openItemService.PrintBills(userIdentityId, culture, requests, trackingDetails, false);
                    break;
            }

            return trackingDetails;
        }

        async Task<SaveOpenItemResult> FinaliseOpenItem(int userIdentityId, string culture, OpenItemModel openItemModel, string mode, string connectionId)
        {
            // TODO
            // send signalr connectionId from front end.
            // if (connectionId == null) throw new ArgumentNullException(nameof(connectionId));
            connectionId ??= Guid.NewGuid().ToString();
            //

            var settings = new BillGenerationTracking
            {
                ConnectionId = connectionId,
                ContentId = await _exportContentService.GenerateContentId(connectionId)
            };

            var shouldSendBillsToReviewer = mode switch
            {
                "finalise" => false,
                "finalise-with-review" => true,
                _ => throw new BadRequestException("unknown mode for finalisation")
            };

            return await _openItemService.FinaliseDraftBill(userIdentityId, culture, openItemModel, _requestContext.RequestId, settings, shouldSendBillsToReviewer);
        }
    }

    public class OpenItemPreparationRequest
    {
        public int EntityKey { get; set; }
        public string EntityName { get; set; }
        public string EntityNameCode { get; set; }
        public int RaisedByNameKey { get; set; }
        public string RaisedByName { get; set; }
        public string RaisedByNameCode { get; set; }
        public bool IsNonRenewalRelatedWip { get; set; }
        public bool IsRenewalRelatedWip { get; set; }
        public bool IsUseRenewalDebtor { get; set; }
        public DateTime? FromItemDate { get; set; }
        public DateTime? ToItemDate { get; set; }
        public List<CreateBillRequest> CreateBillRequests { get; set; }
    }

    public class CreateBillRequest
    {
        public int? DebtorKey { get; set; }
        public int? CaseKey { get; set; }
        public decimal TotalAmount { get; set; }
        public int? AllocatedDebtorKey { get; set; }
        public DateTime? FromItemDate { get; set; }
        public DateTime? ToItemDate { get; set; }
        public bool? IsRenewalWip { get; set; }
        public bool? IsNonRenewalWip { get; set; }
        public bool? IsUseRenewalDebtor { get; set; }
    }
}
