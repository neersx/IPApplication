namespace Inprotech.Contracts
{
    public static class StoredProcedures
    {
        public const string VerifyLicenses = "ip_VerifyLicenses";

        public const string ListExpiringLicenses = "ip_ListExpiringLicenses";
        
        public const string GetLastInternalCode = "ip_GetLastInternalCode";

        public const string RegisterAccess = "ip_RegisterAccess";

        public const string ListPortalTab = "p_ListTabs";

        public const string ValidateOfficialNumber = "cs_ValidateOfficialNumber";

        public const string GetNextRenewalDate = "cs_GetNextRenewalDate";

        public const string RecalculateDerivedAttention = "cs_RecalculateDerivedAttention";

        public const string GlobalNameChange = "csw_GlobalNameChange";

        public const string GetAgeOfCase = "pt_GetAgeOfCase";

        public const string PolicingStartContinuously = "ipu_Policing_Start_Continuously";

        public const string RunSanityCheck = "ipw_RunSanityCheck";

        public const string ListName = "naw_ListName";

        public const string ListTrustAccounting = "naw_ListNameTrustAccounting";

        public const string ListTrustAccountingDetail = "naw_ListNameTrustAccountingDetail";

        public const string ProcessInstructions = "csw_ProcessInstructions";

        public const string InsertActivityAttachment = "ipw_InsertActivityAttachment";

        public class TimeRecording
        {
            public const string PostTime = "ts_PostTime";
        }

        public class WipManagement
        {
            public const string GetWipCost = "wp_GetWipCost";

            public const string GetWipDefault = "wp_DefaultWipInformation";

            public const string PostWip = "wp_PostWIP";

            public const string AdjustWip = "wpw_AdjustWIP";

            public const string SplitWip = "wpw_SplitWIP";

            public const string GetWipItem = "wpw_GetWIPItem";

            public const string ListProtocolDisbursements = "acw_ListProtocolDisbursements";
        }

        public static class Billing
        {
            public const string GetOpenItem = "biw_GetOpenItem";

            public const string GetCaseDetail = "biw_GetCaseDetail";

            public const string GetCaseDetailsFromCaseList = "biw_GetCaseDetailsFromCaseList";

            public const string GetBillCases = "biw_GetBillCases";

            public const string GetDebtorDetails = "biw_GetDebtorDetails";

            public const string GetBillDebtors = "biw_GetBillDebtors";

            public const string GetCopyToNames = "biw_GetCopyToNames";

            public const string GetDebtorsFromCaseList = "biw_GetDebtorsFromCaseList";

            public const string GetCopyToContactDetails = "biw_GetCopyToContactDetails";

            public const string GetBillAvailableWip = "biw_GetBillAvailableWIP";

            public const string GetExchangeDetails = "ac_GetExchangeDetails";

            public const string GetDefaultDiscountDetails = "acw_GetDefaultDiscountDetails";

            public const string GetDefaultMarginDetails = "acw_GetDefaultMarginDetails";

            public const string GetDefaultTaxCodeForWip = "acw_GetDefaultTaxCodeForWIP";

            public const string GetTaxRate = "acw_GetTaxRate"; // Compatibility management

            public const string GetEffectiveTaxRate = "acw_GetEffectiveTaxRate"; // Compatibility management

            public const string CalculateNameBillingDiscountRate = "biw_CalculateNameBillingDiscountRate";

            public const string FetchBestBillFormat = "biw_FetchBestBillFormat";

            public const string GenerateMappedValuesXml = "biw_GenerateMappedValuesXML";

            public const string GetDebitNotes = "biw_GetDebitNotes";

            public const string GetBillCredits = "biw_GetBillCredits";

            public const string GetEBillingXml = "biw_GetEBillingXML";

            public const string CopyDraftWip = "biw_CopyDraftWIP";

            public const string DeleteDraftBill = "biw_DeleteDraftBill";

            public const string FinaliseOpenItem = "biw_FinaliseOpenItem";

            public const string GenerateChangeAlert = "biw_GenerateChangeAlert";

            public const string GenerateBillChangeAlert = "biw_GenerateBillChangeAlert";

            public const string PostDebtorHistory = "acw_PostDebtorHistory";
        }
    }
}