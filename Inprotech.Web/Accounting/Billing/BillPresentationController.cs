using System;
using System.Collections.Generic;
using System.Linq;
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
using InprotechKaizen.Model.Components.Accounting.Billing.Items.References;
using InprotechKaizen.Model.Components.Accounting.Billing.Presentation;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Accounting.Billing
{
    [Authorize]
    [NoEnrichment]
    [UseDefaultContractResolver]
    [RoutePrefix("api/accounting/billing/bill-presentation")]
    [RequiresLicense(LicensedModule.Billing)]
    [RequiresLicense(LicensedModule.TimeandBillingModule)]
    public class BillPresentationController : ApiController
    {
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IBillFormatResolver _billFormatResolver;
        readonly ITranslatedNarrative _translatedNarrative;
        readonly IReferenceResolver _referenceResolver;
        readonly IBillLines _billLines;

        public BillPresentationController(
            ISecurityContext securityContext,
            IPreferredCultureResolver preferredCultureResolver,
            IBillFormatResolver billFormatResolver,
            ITranslatedNarrative translatedNarrative,
            IReferenceResolver referenceResolver,
            IBillLines billLines)
        {
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _billFormatResolver = billFormatResolver;
            _translatedNarrative = translatedNarrative;
            _referenceResolver = referenceResolver;
            _billLines = billLines;
        }

        [HttpGet]
        [Route("narrative")]
        public async Task<string> GetTranslatedNarrativeText(short id, int? languageId)
        {
            var culture = _preferredCultureResolver.Resolve();

            return await _translatedNarrative.For(culture, id, languageId: languageId);
        }
        
        [HttpGet]
        [Route("references")]
        public async Task<BillReference> GetBillReference(string caseIds, int? languageId = null, bool useRenewalDebtor = false, int? debtorId = null, string openItemNo = null)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();
            var caseIdArray = caseIds.Split(',')
                                     .Select(_ => int.Parse(_.Trim()))
                                     .ToArray();

            return await _referenceResolver.Resolve(userId, culture, caseIdArray, languageId, useRenewalDebtor, debtorId, openItemNo);
        }

        [HttpGet]
        [Route("lines")]
        public async Task<IEnumerable<BillLine>> GetBillLines(int entityId, int transactionId)
        {
            return await _billLines.Retrieve(entityId, transactionId);
        }

        [HttpPost]
        [Route("merged/lines")]
        public async Task<IEnumerable<BillLine>> GetMergedBillLine(XElement mergedXmlKeys)
        {
            if (mergedXmlKeys == null) throw new ArgumentNullException(nameof(mergedXmlKeys));

            var validMergedXmlKeys = new MergeXmlKeys(mergedXmlKeys);

            return await _billLines.Retrieve(validMergedXmlKeys);
        }

        [HttpGet]
        [Route("format")]
        public async Task<BillFormat> GetBillFormat(int formatId)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _billFormatResolver.Resolve(userId, culture, formatId);
        }

        [HttpPost]
        [Route("format")]
        [RequiresNameAuthorization(PropertyPath = "billFormatCriteria.NameId")]
        public async Task<BillFormat> GetBestBillFormat(BillFormatCriteria billFormatCriteria)
        {
            if (billFormatCriteria == null) throw new ArgumentNullException(nameof(billFormatCriteria));
            
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _billFormatResolver.Resolve(userId, culture, billFormatCriteria);
        }

        [HttpPost]
        [Route("mapping")]
        [RequiresCaseAuthorization(PropertyPath = "billMapXmlParameter.CaseId")]
        [RequiresNameAuthorization(PropertyPath = "billMapXmlParameter.DebtorId")]
        public async Task<XElement> GetBillMappedXmlData(BillMapXmlParameter billMapXmlParameter)
        {
            if (billMapXmlParameter == null) throw new ArgumentNullException(nameof(billMapXmlParameter));
            
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _billLines.GenerateMappedValuesXml(userId, culture, 
                                                            billMapXmlParameter.BillFormatId, 
                                                            billMapXmlParameter.EntityId,
                                                            billMapXmlParameter.DebtorId,
                                                            billMapXmlParameter.CaseId,
                                                            billMapXmlParameter.BillLines.AsXml());
        }

        public class BillMapXmlParameter
        {
            public int BillFormatId { get; set; }

            public int EntityId { get; set; }

            public int DebtorId { get; set; }

            public int? CaseId { get; set; }

            public IEnumerable<BillLine> BillLines { get; set; } = new List<BillLine>();
        }
    }
}