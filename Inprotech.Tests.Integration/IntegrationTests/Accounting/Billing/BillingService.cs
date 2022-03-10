using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Accounting.Billing;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.References;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using InprotechKaizen.Model.Components.Core;
using Newtonsoft.Json.Linq;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing
{
    internal static class BillingService
    {
        internal static OpenItemModel GetDefaultOpenItem(ItemTypesForBilling itemType, string user = "e2e_ken")
        {
            return ApiClient.Get<OpenItemModel>($"accounting/billing/open-item?itemType={itemType}", user);
        }

        internal static OpenItemModel GetOpenItem(int itemEntityId, string openItemNo, string user = "e2e_ken")
        {
            return ApiClient.Get<OpenItemModel>($"accounting/billing/open-item?itemEntityId={itemEntityId}&openItemNo={openItemNo}", user);
        }

        internal static OpenItemModel GetOpenItems(string mergedOpenItems, string user = "e2e_ken")
        {
            return ApiClient.Get<OpenItemModel>($"accounting/billing/open-item?merged={mergedOpenItems}", user);
        }

        internal static ValidationErrorCollection ValidateItemDate(DateTime itemDate, string user = "e2e_ken")
        {
            return ApiClient.Get<ValidationErrorCollection>($"accounting/billing/open-item/validate?itemDate={itemDate:yyyy-MM-dd}", user);
        }

        internal static bool ValidateIfOpenItemUnique(string openItemNo, string user = "e2e_ken")
        {
            return ApiClient.Get<bool>($"accounting/billing/open-item/is-unique?openItemNo={openItemNo}", user);
        }
        
        internal static JObject GetSettings(string scope = "user,site", string user = "e2e_ken")
        {
            return ApiClient.Get<JObject>($"accounting/billing/settings?scope={scope}", user);
        }

        internal static BillSettings GetBillRules(int debtorId, int? caseId = null, int? entityId = null, string action = null, string user = "e2e_ken")
        {
            var settings = ApiClient.Get<BillSettingsController.Settings>($"accounting/billing/settings?scope=bill&debtorId={debtorId}&caseId={caseId}&entityId={entityId}&action={action}", user);

            return settings.Bill;
        }
        
        // Cases (post)

        internal static CaseData GetCase(int caseId, int raisedByStaffId, int? entityId, string user = "e2e_ken")
        {
            return GetCases(new CasesController.CaseRequest
            {
                CaseIds = $"{caseId}",
                EntityId = entityId,
                RaisedByStaffId = raisedByStaffId
            }, user).CaseList.Single();
        }

        internal static CaseDataCollection GetCaseListCases(int caseListId, int raisedByStaffId, string user = "e2e_ken")
        {
            return GetCases(new CasesController.CaseRequest
            {
                CaseListId = caseListId,
                RaisedByStaffId = raisedByStaffId
            }, user);
        }

        internal static CaseDataCollection GetCases(CasesController.CaseRequest request, string user = "e2e_ken")
        {
            return ApiClient.Post<CaseDataCollection>("accounting/billing/cases", request, user);
        }

        internal static CaseDataCollection GetMergedOpenItemCases(string mergeXmlKeys, string user = "e2e_ken")
        {
            // This is called through Bill Search results when multiple bills are merged into one
            return ApiClient.Post<CaseDataCollection>("accounting/billing/open-item/cases", mergeXmlKeys, user);
        }

        internal static CaseDataCollection GetOpenItemCases(int itemEntityId, int itemTransactionId, string user = "e2e_ken")
        {
            return ApiClient.Get<CaseDataCollection>($"accounting/billing/open-item/cases?itemEntityId={itemEntityId}&itemTransactionId={itemTransactionId}", user);
        }
        
        internal static bool HasPrepaymentRestriction(int caseId, string user = "e2e_ken")
        {
            return ApiClient.Get<bool>($"accounting/billing/cases/is-restricted-for-prepayment?caseId={caseId}", user);
        }

        internal static CaseDataCollection GetCasesRestrictedForBilling(int caseId, string user = "e2e_ken")
        {
            return ApiClient.Get<CaseDataCollection>($"accounting/billing/cases/is-restricted-for-billing?caseId={caseId}", user);
            
        }
        
        // Debtors

        internal static DebtorDataCollection GetDebtorListForCases(string caseIds, string action, bool useRenewalDebtor, string user = "e2e_ken")
        {
            // This is called through WIP Overview Search results when multiple wip (from different cases) for the same debtor are passed on to be created as a single bill
            return ApiClient.Get<DebtorDataCollection>($"accounting/billing/debtors?caseIds={caseIds}&action={action}&useRenewalDebtor={useRenewalDebtor}", user);
        }

        internal static DebtorDataCollection GetDebtorListFromCase(int caseId, int[] caseIds, string action, bool useRenewalDebtor, int? entityId, DateTime billDate, int? raisedByStaffId, string user = "e2e_ken")
        {
            var caseIdsCsv = string.Join(",", (caseIds ?? new int[0]).Select(_ => _.ToString()));

            return ApiClient.Get<DebtorDataCollection>($"accounting/billing/debtors?type=Detailed&caseId={caseId}&caseIds={caseIdsCsv}&entityId={entityId}&action={action}&useRenewalDebtor={useRenewalDebtor}&billDate={billDate:s}&raisedByStaffId={raisedByStaffId}", user);
        }
        
        internal static DebtorDataCollection GetDebtorList(int entityId, int transactionId, int? raisedByStaffId, string caseIds, string user = "e2e_ken")
        {
            return ApiClient.Get<DebtorDataCollection>($"accounting/billing/open-item/debtors?caseIds={caseIds}&entityId={entityId}&transactionId={transactionId}&raisedByStaffId={raisedByStaffId}", user);
        }

        internal static DebtorDataCollection GetDebtorsFromCaseList(int caseListId, string action, bool useRenewalDebtor, string user = "e2e_ken")
        {
            return ApiClient.Get<DebtorDataCollection>($"accounting/billing/debtors?caseListId={caseListId}&action={action}&useRenewalDebtor={useRenewalDebtor}", user);
        }

        internal static DebtorDataCollection GetDebtorsFromCase(int caseId, string action, bool useRenewalDebtor, string user = "e2e_ken")
        {
            return ApiClient.Get<DebtorDataCollection>($"accounting/billing/debtors?caseId={caseId}&action={action}&useRenewalDebtor={useRenewalDebtor}", user);
        }

        internal static DebtorDataCollection LoadDebtorsFromDebtorList(int? caseId, int? entityId, string action, bool useRenewalDebtor, DateTime billDate, DebtorsController.ReloadDebtorDetails[] debtorsToLoad, string user = "e2e_ken")
        {
            return ApiClient.Post<DebtorDataCollection>($"accounting/billing/debtors?entityId={entityId}&caseId={caseId}&action={action}&billDate={billDate:s}&useRenewalDebtor={useRenewalDebtor}", 
                                                        debtorsToLoad,
                                                        user);
        }

        internal static DebtorData GetDebtor(int debtorNameId, int? caseId, string caseIds, string action, bool useRenewalDebtor, int? raisedByStaffId, int? entityId, int? transactionId, DateTime billDate, string user = "e2e_ken")
        {
            var apiEndpoint = caseId != null
                ? $"accounting/billing/debtors?type=Detailed&debtorNameId={debtorNameId}&caseId={caseId}&entityId={entityId}&transactionId={transactionId}&action={action}&useRenewalDebtor={useRenewalDebtor}&billDate={billDate:s}&raisedByStaffId={raisedByStaffId}&caseIds={caseIds}"
                : $"accounting/billing/debtors?type=Detailed&debtorNameId={debtorNameId}&entityId={entityId}&transactionId={transactionId}&action={action}&billDate={billDate:s}&raisedByStaffId={raisedByStaffId}&caseIds={caseIds}";

            var debtors = ApiClient.Get<DebtorDataCollection>(apiEndpoint, user);
            
            if (debtors.HasError)
            {
                return new DebtorData
                {
                    ErrorMessage = debtors.ErrorMessage
                };
            }

            return debtors.DebtorList.Single();
        }

        // Debtor Copies to
        internal static DebtorCopiesTo GetCopiesToContactDetails(int debtorNameId, int copyToNameId, string user = "e2e_ken")
        {
            return ApiClient.Get<DebtorCopiesTo>($"accounting/billing/debtor/copies?debtorNameId={debtorNameId}&copyToNameId={copyToNameId}", user);
        }

        // bill-presentation
        internal static string GetTranslatedNarrativeText(short narrativeId, int? languageId, string user = "e2e_ken")
        {
            return (string) ApiClient.Get<JValue>($"accounting/billing/bill-presentation/narrative?id={narrativeId}&languageId={languageId}", user);
        }

        internal static BillReference GetDefaultBillReferences(int[] caseIds, int? languageId, bool useRenewalDebtor, int debtorId, string openItemNo, string user = "e2e_ken")
        {
            var caseIdCsv = string.Join(",", caseIds);

            return ApiClient.Get<BillReference>($"accounting/billing/bill-presentation/references?caseIds={caseIdCsv}&languageId={languageId}&useRenewalDebtor={useRenewalDebtor}&debtorId={debtorId}&openItemNo={openItemNo}", user);
        }

        // wip selection 
        internal static IEnumerable<AvailableWipItem> GetAvailableWipForCase(int itemEntityId, int? itemTransactionId, int[] caseIds, int? debtorId, int raisedByStaffId, ItemType? itemType, DateTime? itemDate, string user = "e2e_ken")
        {
            return ApiClient.Post<IEnumerable<AvailableWipItem>>("accounting/billing/wip-selection", 
                                                                 new WipSelectionCriteria
                                                                 {
                                                                     ItemEntityId = itemEntityId,
                                                                     ItemTransactionId = itemTransactionId,
                                                                     CaseIds = caseIds,
                                                                     DebtorId = debtorId,
                                                                     RaisedByStaffId = raisedByStaffId,
                                                                     ItemDate = itemDate,
                                                                     ItemType = itemType
                                                                 },user);
        }

        internal static IEnumerable<AvailableWipItem> GetAvailableWipForDebtor(int itemEntityId, int? itemTransactionId, int? debtorId, int raisedByStaffId, ItemType? itemType, DateTime? itemDate, string user = "e2e_ken")
        {
            return ApiClient.Post<IEnumerable<AvailableWipItem>>("accounting/billing/wip-selection", 
                                                                 new WipSelectionCriteria
                                                                 {
                                                                     ItemEntityId = itemEntityId,
                                                                     ItemTransactionId = itemTransactionId,
                                                                     DebtorId = debtorId,
                                                                     RaisedByStaffId = raisedByStaffId,
                                                                     ItemDate = itemDate,
                                                                     ItemType = itemType
                                                                 },user);
        }

        internal static IEnumerable<AvailableWipItem> GetAvailableWip(int itemEntityId, int? itemTransactionId, ItemType? itemType, DateTime? itemDate, string user = "e2e_ken")
        {
            return ApiClient.Post<IEnumerable<AvailableWipItem>>("accounting/billing/wip-selection", 
                                                                 new WipSelectionCriteria
                                                                 {
                                                                     ItemEntityId = itemEntityId,
                                                                     ItemTransactionId = itemTransactionId,
                                                                     ItemDate = itemDate,
                                                                     ItemType = itemType
                                                                 },user);
        }
    }
}