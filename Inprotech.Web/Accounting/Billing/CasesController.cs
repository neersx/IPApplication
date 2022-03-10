using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Formatting;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Accounting.Billing
{
    [Authorize]
    [NoEnrichment]
    [UseDefaultContractResolver]
    [RoutePrefix("api/accounting/billing")]
    [RequiresLicense(LicensedModule.Billing)]
    [RequiresLicense(LicensedModule.TimeandBillingModule)]
    public class CasesController : ApiController
    {
        readonly ICaseDataCommands _caseDataCommands;
        readonly ICaseWipCalculator _caseWipCalculator;
        readonly ICaseDataExtension _caseDataExtension;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IRestrictedForBilling _restrictedForBilling;
        readonly ICaseStatusValidator _caseStatusValidator;
        readonly ISecurityContext _securityContext;

        public CasesController(
            ISecurityContext securityContext,
            IPreferredCultureResolver preferredCultureResolver,
            ICaseDataCommands caseDataCommands,
            IRestrictedForBilling restrictedForBilling,
            ICaseStatusValidator caseStatusValidator,
            ICaseWipCalculator caseWipCalculator,
            ICaseDataExtension caseDataExtension)
        {
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _caseDataCommands = caseDataCommands;
            _restrictedForBilling = restrictedForBilling;
            _caseStatusValidator = caseStatusValidator;
            _caseWipCalculator = caseWipCalculator;
            _caseDataExtension = caseDataExtension;
        }

        [HttpGet]
        [Route("open-item/cases")]
        [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        public async Task<CaseDataCollection> GetOpenItemCases(int itemEntityId, int itemTransactionId)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            var cases = (await _caseDataCommands.GetOpenItemCases(userId, culture, itemEntityId, itemTransactionId)).ToArray();

            var caseIds = cases.Select(_ => _.CaseId).ToArray();

            var totalAvailableWip = await _caseWipCalculator.GetTotalAvailableWip(caseIds, itemEntityId);

            var totalUnlockedWip = await _caseWipCalculator.GetUnlockedAvailableWip(caseIds, itemEntityId);

            var restrictedCases = await _restrictedForBilling.Retrieve(caseIds).ToArrayAsync();

            var caseExtendedData = await _caseDataExtension.GetPropertyTypeAndCountry(caseIds, culture);

            foreach (var @case in cases)
            {
                @case.UnlockedWip = totalUnlockedWip.Get(@case.CaseId);
                @case.TotalWip = totalAvailableWip.Get(@case.CaseId);

                var extendedData = caseExtendedData?.Get(@case.CaseId);
                if (extendedData != null)
                {
                    @case.PropertyTypeDescription = extendedData.PropertyTypeDescription;
                    @case.Country = extendedData.Country;
                }

                var restrictedCase = restrictedCases.FirstOrDefault(_ => _.CaseId == @case.CaseId);
                if (restrictedCase != null)
                {
                    @case.CaseStatus = restrictedCase.CaseStatus;
                    @case.OfficialNumber = restrictedCase.OfficialNumber;
                    @case.HasRestrictedStatusForBilling = true;
                }
            }

            return new CaseDataCollection(cases, restrictedCases);
        }

        [HttpPost]
        [Route("open-item/cases")]
        [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        public async Task<CaseDataCollection> GetOpenItemCases([FromBody] string mergeXmlKeys)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            var merged = new MergeXmlKeys(mergeXmlKeys);

            var rawCases = (await _caseDataCommands.GetOpenItemCases(userId, culture, mergeXmlKeys: merged)).ToArray();

            var cases = UnsetMainCaseThenRemoveDuplicates(merged.OpenItemXmls.First().ItemTransNo, rawCases);

            var caseIds = cases.Select(_ => _.CaseId).ToArray();

            var restrictedCases = await _restrictedForBilling.Retrieve(caseIds).ToArrayAsync();
            var caseExtendedData = await _caseDataExtension.GetPropertyTypeAndCountry(caseIds, culture);

            foreach (var @case in cases)
            {
                var extendedData = caseExtendedData?.Get(@case.CaseId);
                if (extendedData != null)
                {
                    @case.PropertyTypeDescription = extendedData.PropertyTypeDescription;
                    @case.Country = extendedData.Country;
                }

                var restrictedCase = restrictedCases.FirstOrDefault(_ => _.CaseId == @case.CaseId);
                if (restrictedCase != null)
                {
                    @case.CaseStatus = restrictedCase.CaseStatus;
                    @case.OfficialNumber = restrictedCase.OfficialNumber;
                    @case.HasRestrictedStatusForBilling = true;
                }
            }

            return new CaseDataCollection(cases, restrictedCases);
        }

        static CaseData[] UnsetMainCaseThenRemoveDuplicates(int firstTransactionId, CaseData[] cases)
        {
            var nonFirstDraftBillMainCases = from c in cases
                                                where c.ItemTransNo != firstTransactionId && c.IsMainCase == true
                                                select c;
            
            var toRemove = new HashSet<CaseData>();
            foreach (var @case in nonFirstDraftBillMainCases)
            {
                @case.IsMainCase = false;
                if (cases.Count(_ => _.CaseId == @case.CaseId) > 1)
                {
                    toRemove.Add(@case);
                }
            }

            return cases.Except(toRemove).ToArray();
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("cases/is-restricted-for-billing")]
        public async Task<CaseDataCollection> RestrictedForBilling(int caseId)
        {
            return new(await _restrictedForBilling.Retrieve(new[] { caseId }).ToArrayAsync());
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("cases/is-restricted-for-prepayment")]
        public async Task<bool> RestrictedForPrepayment(int caseId)
        {
            return await _caseStatusValidator.IsCaseStatusRestrictedForPrepayment(caseId);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("cases/case-debtors")]
        public async Task<IEnumerable<int>> GetCaseDebtors(int caseId)
        {
            return await _caseStatusValidator.GetCaseDebtors(caseId);
        }

        [HttpPost]
        [Route("valid-action")]
        [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        public async Task<ActionData> GetValidAction([FromBody] ValidActionIdentifier validActionIdentifier)
        {
            if(validActionIdentifier == null) 
                throw new ArgumentNullException(nameof(validActionIdentifier));

            return await _caseDataExtension.GetValidAction(validActionIdentifier, _preferredCultureResolver.Resolve());
        }

        [HttpPost]
        [Route("cases")]
        [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        public async Task<CaseDataCollection> GetCases([FromBody] CaseRequest caseRequest)
        {
            if (caseRequest == null) throw new ArgumentNullException(nameof(caseRequest));

            var culture = _preferredCultureResolver.Resolve();
            var resolveCases = await ResolveCases(caseRequest);

            var totalAvailableWip = caseRequest.EntityId == null
                ? new Dictionary<int, decimal?>()
                : await _caseWipCalculator.GetTotalAvailableWip(resolveCases.CaseIds, caseRequest.EntityId);

            var totalUnlockedWip = caseRequest.EntityId == null
                ? new Dictionary<int, decimal?>()
                : await _caseWipCalculator.GetUnlockedAvailableWip(resolveCases.CaseIds, caseRequest.EntityId);

            var draftBills = await _caseWipCalculator.GetDraftBillsByCase(resolveCases.CaseIds);

            var restrictedCases = await _restrictedForBilling.Retrieve(resolveCases.CaseIds).ToArrayAsync();
            var caseExtendedData = await _caseDataExtension.GetPropertyTypeAndCountry(resolveCases.CaseIds, culture);

            foreach (var @case in resolveCases.Cases)
            {
                @case.UnlockedWip = totalUnlockedWip.Get(@case.CaseId);
                @case.TotalWip = totalAvailableWip.Get(@case.CaseId);
                @case.DraftBills.AddRange(draftBills.Get(@case.CaseId) ?? Enumerable.Empty<string>());

                var extendedData = caseExtendedData?.Get(@case.CaseId);
                if (extendedData != null)
                {
                    @case.PropertyTypeDescription = extendedData.PropertyTypeDescription;
                    @case.Country = extendedData.Country;
                }

                var restrictedCase = restrictedCases.FirstOrDefault(_ => _.CaseId == @case.CaseId);
                if (restrictedCase != null)
                {
                    @case.CaseStatus = restrictedCase.CaseStatus;
                    @case.OfficialNumber = restrictedCase.OfficialNumber;
                    @case.HasRestrictedStatusForBilling = true;
                }
            }

            return new CaseDataCollection(resolveCases.Cases, restrictedCases);
        }

        async Task<(IEnumerable<CaseData> Cases, int[] CaseIds)> ResolveCases(CaseRequest caseRequest)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            int[] caseIds;
            var cases = new List<CaseData>();

            if (caseRequest.CaseListId != null)
            {
                cases.AddRange(await _caseDataCommands.GetCases(userId, culture, (int)caseRequest.CaseListId, caseRequest.RaisedByStaffId));
                caseIds = cases.Select(_ => _.CaseId).ToArray();
            }
            else
            {
                caseIds = caseRequest.GetCaseIds();
                foreach (var caseId in caseRequest.GetCaseIds()) cases.Add(await _caseDataCommands.GetCase(userId, culture, caseId, caseRequest.RaisedByStaffId));
            }

            return (cases, caseIds);
        }

        public class CaseRequest
        {
            public int? CaseListId { get; set; }
            public string CaseIds { get; set; }
            public int RaisedByStaffId { get; set; }
            public int? EntityId { get; set; }

            public int[] GetCaseIds()
            {
                return string.IsNullOrWhiteSpace(CaseIds)
                    ? new int[0]
                    : CaseIds.Split(',').Select(int.Parse).ToArray();
            }
        }
    }

    public class CaseDataCollection
    {
        public CaseDataCollection(IEnumerable<CaseData> caseData, IEnumerable<CaseData> restrictedCaseList = null)
        {
            CaseList = caseData;
            RestrictedCaseList = restrictedCaseList ?? Enumerable.Empty<CaseData>();
        }

        public IEnumerable<CaseData> CaseList { get; set; }

        public IEnumerable<CaseData> RestrictedCaseList { get; set; }
    }
}