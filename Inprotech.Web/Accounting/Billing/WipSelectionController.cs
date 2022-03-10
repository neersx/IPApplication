using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Formatting;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Tax;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Accounting.Billing
{ 
    [Authorize]
    [NoEnrichment]
    [UseDefaultContractResolver]
    [RoutePrefix("api/accounting/billing")]
    [RequiresLicense(LicensedModule.Billing)]
    [RequiresLicense(LicensedModule.TimeandBillingModule)]
    [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Create)]
    [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Modify)]
    [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Delete)]
    [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Create)]
    [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Modify)]
    [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Delete)]
    public class WipSelectionController : ApiController
    {
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IWipItemsService _wipItemsService;
        readonly ITaxRateResolver _taxRateResolver;

        public WipSelectionController(
            ISecurityContext securityContext,
            IPreferredCultureResolver preferredCultureResolver,
            IWipItemsService wipItemsService, 
            ITaxRateResolver taxRateResolver)
        {
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _wipItemsService = wipItemsService;
            _taxRateResolver = taxRateResolver;
        }

        [HttpPost]
        [Route("wip-selection")]
        [RequiresNameAuthorization(PropertyPath = "selectionCriteria.DebtorId")]
        public async Task<IEnumerable<AvailableWipItem>> GetWipItems(WipSelectionCriteria selectionCriteria)
        {
            if (selectionCriteria == null) throw new ArgumentNullException(nameof(selectionCriteria));

            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _wipItemsService.GetAvailableWipItems(userId, culture, selectionCriteria);
        }

        [HttpPost]
        [Route("wip-selection/exchange-rates")]
        [RequiresNameAuthorization(PropertyPath = "selectionCriteria.DebtorId")]
        public async Task<WipItemExchangeRates> GetWipItemExchangeRates([FromUri] string currencyCode, [FromBody] WipSelectionCriteria selectionCriteria)
        {
            if (currencyCode == null) throw new ArgumentNullException(nameof(currencyCode));
            if (selectionCriteria == null) throw new ArgumentNullException(nameof(selectionCriteria));

            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _wipItemsService.GetWipItemExchangeRates(userId, culture, currencyCode, selectionCriteria);
        }

        [HttpPost]
        [Route("wip-selection/discounts")]
        public async Task<IEnumerable<AvailableWipItem>> RecalculateDiscounts(DiscountRecalculationParameters recalculationParameters)
        {
            if (recalculationParameters == null) throw new ArgumentNullException(nameof(recalculationParameters));

            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _wipItemsService.RecalculateDiscounts(userId, culture, recalculationParameters.BilledAmount, recalculationParameters.RaisedByStaffId, recalculationParameters.DiscountWipItems);
        }

        [HttpGet]
        [Route("wip-selection/tax-rates")]
        public async Task<IEnumerable<TaxRate>> TaxRates(int entityId, int raisedByStaffId, DateTime transactionDate)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _taxRateResolver.Resolve(userId, culture, raisedByStaffId, entityId, transactionDate);
        }

        [HttpPost]
        [Route("wip-selection/include-draft-wip-items")]
        [RequiresCaseAuthorization(PropertyPath = "parameters.CaseId")]
        public async Task<IEnumerable<AvailableWipItem>> IncludeDraftWipItems(IncludeDraftWipItemsParameters parameters)
        {
            if (parameters == null) throw new ArgumentNullException(nameof(parameters));

            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _wipItemsService.ConvertDraftWipToAvailableWipItems(userId, culture,
                                                                             parameters.DraftWipItems,
                                                                             parameters.ItemType, parameters.StaffId, parameters.BillCurrency, parameters.BillDate,
                                                                             parameters.CaseId, parameters.DebtorId);
        }

        [HttpPost]
        [Route("wip-selection/include-stamp-fees")]
        [RequiresNameAuthorization(PropertyPath = "draftWipItem.NameId")]
        [RequiresCaseAuthorization(PropertyPath = "draftWipItem.CaseId")]
        public async Task<IEnumerable<AvailableWipItem>> IncludeStampFees([FromUri] int raisedByStaffId, [FromUri] DateTime billDate, [FromBody] DraftWip draftWipItem)
        {
            if (draftWipItem == null) throw new ArgumentNullException(nameof(draftWipItem));

            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _wipItemsService.ConvertStampFeeWipToAvailableWipItems(userId, culture, draftWipItem, raisedByStaffId, billDate);
        }
        
        public class IncludeDraftWipItemsParameters
        {
            public ItemType ItemType { get; set; }

            public int StaffId { get; set; }

            public string BillCurrency { get; set; }
            
            public DateTime BillDate { get; set; }

            public int? CaseId { get; set; }

            public int DebtorId { get; set; }

            public CompleteDraftWipItem[] DraftWipItems { get; set; }
        }

        public class DiscountRecalculationParameters
        {
            public int RaisedByStaffId { get; set; }
            public decimal BilledAmount { get; set; }
            public IEnumerable<AvailableWipItem> DiscountWipItems { get; set; } = new List<AvailableWipItem>();
        }
    }
}
