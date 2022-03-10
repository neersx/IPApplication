using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http;
using System.Xml.Linq;
using Inprotech.Infrastructure.Formatting;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Tax;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Accounting.Billing
{
    [Authorize]
    [NoEnrichment]
    [UseDefaultContractResolver]
    [RoutePrefix("api/accounting/billing/debit-and-credit-notes")]
    [RequiresLicense(LicensedModule.Billing)]
    [RequiresLicense(LicensedModule.TimeandBillingModule)]
    [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Create)]
    [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Modify)]
    [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Delete)]
    [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Create)]
    [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Modify)]
    [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Delete)]
    public class DebitOrCreditNotesController : ApiController
    {
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IElectronicBillingXmlResolver _electronicBillingXmlResolver;
        readonly IDebitOrCreditNotes _debitOrCreditNotes;
        readonly ITaxRateResolver _taxRateResolver;

        public DebitOrCreditNotesController(
            ISecurityContext securityContext,
            IPreferredCultureResolver preferredCultureResolver,
            IElectronicBillingXmlResolver electronicBillingXmlResolver,
            IDebitOrCreditNotes debitOrCreditNotes,
            ITaxRateResolver taxRateResolver)
        {
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _electronicBillingXmlResolver = electronicBillingXmlResolver;
            _debitOrCreditNotes = debitOrCreditNotes;
            _taxRateResolver = taxRateResolver;
        }

        [HttpGet]
        [Route("")]
        public async Task<IEnumerable<DebitOrCreditNote>> GetDebitNotes(int itemEntityId, int itemTransactionId)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _debitOrCreditNotes.Retrieve(userId, culture, itemEntityId, itemTransactionId);
        }

        [HttpPost]
        [Route("merged")]
        public async Task<IEnumerable<DebitOrCreditNote>> GetMergedDebitNotes([FromUri] int itemEntityId, [FromUri] int itemTransactionId, [FromBody] XElement mergeXmlKeys)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();
            var validMergedXmlKeys = new MergeXmlKeys(mergeXmlKeys);

            return await _debitOrCreditNotes.MergedCreditItems(userId, culture, validMergedXmlKeys, itemEntityId, itemTransactionId);
        }

        [HttpGet]
        [Route("effective-tax-rate")]
        public async Task<TaxRate> GetEffectiveTaxRate(int entityId, int raisedByStaffId, DateTime billDate, string taxCode, string sourceCountry)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _taxRateResolver.Resolve(userId, culture, taxCode, sourceCountry, raisedByStaffId, entityId, billDate);
        }
        
        [HttpPost]
        [Route("available-credits")]
        public async Task<IEnumerable<CreditItem>> GetAvailableCredits(AvailableCreditsParameters parameters)
        {
            if (parameters == null) throw new ArgumentNullException(nameof(parameters));

            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _debitOrCreditNotes.AvailableCredits(userId, culture, parameters.EntityId, parameters.CaseIds, parameters.DebtorIds);
        }

        [HttpPost]
        [Route("available-credits/merged")]
        public async Task<IEnumerable<CreditItem>> GetMergedAvailableCredits(XElement mergeXmlKeys)
        {
            if (mergeXmlKeys == null) throw new ArgumentNullException(nameof(mergeXmlKeys));

            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();
            var validMergeXmlKeys = new MergeXmlKeys(mergeXmlKeys);

            return await _debitOrCreditNotes.MergedAvailableCredits(userId, culture, validMergeXmlKeys);
        }

        [HttpGet]
        [Route("e-bill")]
        public async Task<ElectronicBillingData> ResolveElectronicBillingData(string openItemNo, int itemEntityId)
        {
            if (openItemNo == null) throw new ArgumentNullException(nameof(openItemNo));

            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _electronicBillingXmlResolver.Resolve(userId, culture, openItemNo, itemEntityId);
        }

        public class AvailableCreditsParameters
        {
            public int EntityId { get; set; }
            
            public int[] CaseIds { get; set; }

            public int[] DebtorIds { get; set; }
        }
    }
}
