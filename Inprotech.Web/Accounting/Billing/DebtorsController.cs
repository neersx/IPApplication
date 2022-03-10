using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Formatting;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Notifications.Validation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
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
    public class DebtorsController : ApiController
    {
        public enum TypeOfDetails
        {
            Summary,
            Detailed
        }

        readonly IBillingLanguageResolver _billingLanguageResolver;
        readonly IDebtorListCommands _debtorListCommands;
        readonly IDebtorRestriction _debtorRestriction;
        readonly IOpenItemStatusResolver _openItemStatusResolver;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly IDebtorAvailableWipTotals _wipTotal;

        public DebtorsController(
            ISecurityContext securityContext,
            IPreferredCultureResolver preferredCultureResolver,
            IOpenItemStatusResolver openItemStatusResolver,
            IDebtorAvailableWipTotals availableWipTotal,
            IBillingLanguageResolver billingLanguageResolver,
            IDebtorListCommands debtorListCommands,
            IDebtorRestriction debtorRestriction)
        {
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _openItemStatusResolver = openItemStatusResolver;
            _wipTotal = availableWipTotal;
            _billingLanguageResolver = billingLanguageResolver;
            _debtorListCommands = debtorListCommands;
            _debtorRestriction = debtorRestriction;
        }

        [HttpGet]
        [Route("debtors")]
        [RequiresCaseAuthorization]
        [RequiresNameAuthorization(PropertyName = "debtorNameId")]
        [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        public async Task<DebtorDataCollection> GetDebtors(TypeOfDetails type = TypeOfDetails.Summary,
                                                           int? entityId = null, int? transactionId = null, int? debtorNameId = null, DateTime? billDate = null,
                                                           int? raisedByStaffId = null,
                                                           int? caseId = null, string caseIds = null, int? caseListId = null, string action = null,
                                                           bool? useRenewalDebtor = null, bool? useSendBillsTo = null)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();
            var caseIdArray = CsvToIntArray(caseIds);

            var r = type == TypeOfDetails.Summary
                ? await _debtorListCommands.RetrieveDebtorsFromCases(userId, culture,
                                                                     useRenewalDebtor.GetValueOrDefault(),
                                                                     action,
                                                                     caseId: caseId,
                                                                     caseIds: caseIdArray,
                                                                     caseListId: caseListId)
                : await _debtorListCommands.RetrieveDebtorDetails(userId, culture,
                                                                  caseId: caseId,
                                                                  entityId: entityId,
                                                                  debtorNameId: debtorNameId,
                                                                  billDate: billDate,
                                                                  useSendBillsTo: useSendBillsTo ?? true,
                                                                  useRenewalDebtor: useRenewalDebtor.GetValueOrDefault(),
                                                                  action: action,
                                                                  raisedByStaffId: raisedByStaffId);

            if (type == TypeOfDetails.Detailed && !r.Alerts.Any())
            {
                var openItemStatus = await _openItemStatusResolver.Resolve(entityId, transactionId);
                var debtorsArray = r.Debtors.ToArray();
                var debtorRestrictions = await _debtorRestriction.GetDebtorRestriction(culture, debtorsArray.Select(_ => _.NameId).ToArray());

                foreach (var debtor in debtorsArray)
                {
                    debtor.TotalWip = openItemStatus switch
                    {
                        TransactionStatus.Active => null,
                        TransactionStatus.Draft => await _wipTotal.ForDraftBill(caseIdArray, debtor.NameId, entityId, (int) transactionId),
                        _ => await _wipTotal.ForNewBill(caseIdArray, debtor.NameId, entityId)
                    };

                    debtor.LanguageId = await _billingLanguageResolver.Resolve(debtor.NameId, caseId);
                    debtor.LanguageDescription = _billingLanguageResolver[(debtor.LanguageId, culture)];
                    debtor.DebtorRestriction = debtorRestrictions.Get(debtor.NameId);
                }
            }

            return new DebtorDataCollection
            {
                DebtorList = r.Debtors,
                ErrorMessage = r.Alerts.Flatten()
            };
        }

        [HttpPost]
        [Route("debtors")]
        [RequiresCaseAuthorization]
        [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        public async Task<DebtorDataCollection> ReloadDebtors([FromUri] int caseId,
                                                              [FromUri] int? entityId,
                                                              [FromUri] string action,
                                                              [FromUri] bool useRenewalDebtor,
                                                              [FromUri] DateTime billDate,
                                                              [FromBody] ReloadDebtorDetails[] detailsToReload)
        {
            if (detailsToReload == null) throw new ArgumentNullException(nameof(detailsToReload));

            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            var debtors = new List<DebtorData>();

            foreach (var req in detailsToReload)
            {
                var debtorDetails = await _debtorListCommands.RetrieveDebtorDetails(userId, culture,
                                                                                    billDate: billDate,
                                                                                    entityId: entityId,
                                                                                    action: action,
                                                                                    caseId: caseId,
                                                                                    debtorNameId: req.DebtorNameId,
                                                                                    useSendBillsTo: req.UseSendBillsTo,
                                                                                    useRenewalDebtor: useRenewalDebtor,
                                                                                    raisedByStaffId: null);

                if (debtorDetails.Alerts.Any())
                {
                    debtors.Add(new DebtorData {ErrorMessage = debtorDetails.Alerts.Flatten()});
                    continue;
                }

                if (debtorDetails.Debtors.Any()) debtors.AddRange(debtorDetails.Debtors);
            }

            var debtorRestrictions = await _debtorRestriction.GetDebtorRestriction(culture, debtors.Select(_ => _.NameId).ToArray());
            foreach (var debtor in debtors)
            {
                debtor.DebtorRestriction = debtorRestrictions.Get(debtor.NameId);
            }

            return new DebtorDataCollection {DebtorList = debtors};
        }

        [HttpGet]
        [Route("open-item/debtors")]
        [RequiresAccessTo(ApplicationTask.MaintainDebitNote, ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        [RequiresAccessTo(ApplicationTask.MaintainCreditNote, ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Delete)]
        public async Task<DebtorDataCollection> GetDebtorsOnTheBill(int entityId, int transactionId, int? raisedByStaffId = null, string caseIds = null)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();
            var caseIdArray = CsvToIntArray(caseIds);

            var r = await _debtorListCommands.RetrieveBillDebtors(userId, culture, entityId, transactionId, raisedByStaffId);

            var openItemStatus = await _openItemStatusResolver.Resolve(entityId, transactionId);

            var debtorsArray = r.Debtors.ToArray();

            var debtorRestrictions = await _debtorRestriction.GetDebtorRestriction(culture, debtorsArray.Select(_ => _.NameId).ToArray());
            
            foreach (var debtor in debtorsArray)
            {
                debtor.TotalWip = openItemStatus switch
                {
                    TransactionStatus.Draft => await _wipTotal.ForDraftBill(caseIdArray, debtor.NameId, entityId, transactionId),
                    _ => null
                };
                debtor.DebtorRestriction = debtorRestrictions.Get(debtor.NameId);
            }
            
            return new DebtorDataCollection
            {
                DebtorList = r.Debtors,
                ErrorMessage = r.Alerts.Flatten()
            };
        }

        [HttpGet]
        [Route("debtor/copies")]
        [RequiresNameAuthorization(PropertyName = "debtorNameId")]
        public async Task<DebtorCopiesTo> GetDebtorCopiesTo(int debtorNameId, int copyToNameId)
        {
            var userId = _securityContext.User.Id;
            var culture = _preferredCultureResolver.Resolve();

            return await _debtorListCommands.GetCopiesToContactDetails(userId, culture, debtorNameId, copyToNameId);
        }

        static int[] CsvToIntArray(string input)
        {
            return (from s in (input ?? string.Empty).Split(',')
                    let s1 = s.Trim()
                    where !string.IsNullOrWhiteSpace(s1)
                    select int.Parse(s1)).ToArray();
        }

        public class ReloadDebtorDetails
        {
            public int DebtorNameId { get; set; }
            
            public bool UseSendBillsTo { get; set; }
        }
    }

    public class DebtorDataCollection
    {
        public IEnumerable<DebtorData> DebtorList { get; set; } = new List<DebtorData>();

        public bool HasError => !string.IsNullOrWhiteSpace(ErrorMessage);

        public string ErrorMessage { get; set; }
    }
}