using System.Collections.Generic;

namespace InprotechKaizen.Model.Components.Accounting
{
    public static class KnownErrors
    {
        public const string DebtorNotAClientOrNotConfiguredForBilling = "AC14";
        public const string OtherDraftBillsExistsForCasesOnThisBill = "AC121";
        public const string CasesOnThisBillHasUnbilledWip = "AC122";
        public const string CasesOnThisBillHasUnpostedTime = "AC123";
        public const string ItemPostedToDifferentPeriod = "AC124";
        public const string CouldNotDeterminePostPeriod = "AC126";
        public const string ItemDateEarlierThanLastFinalisedItemDate = "AC207";
        public const string CannotPostFutureDate = "AC208";
        public const string BillDatesInThePastNotAllowed = "AC215";
        public const string FutureBillDatesAllowedIfDateWithinCurrentPeriod = "AC216";
        public const string ItemDateCannotBeInFuturePeriodThatIsClosedForModule = "AC217";
        public const string ItemDateNotProvided = "BI1";
        public const string WipAlreadyOnDifferentBill = "B123";
        public const string TotalOfDebitOrCreditNoteMustBeGreaterThanZero = "BI28";
        public const string EntityRestrictedByCurrency = "BI32";
        public const string BillCaseHasStatusRestrictedForBilling = "BI33";
        public const string FailurePersistingOpenItem = "BI34";
        public const string EBillingXmlInvalid = "BI35";

        public static readonly Dictionary<string, string> CodeMap =
            new()
            {
                {DebtorNotAClientOrNotConfiguredForBilling, "The selected debtor is not a client or is not configured for Billing."},
                {ItemDateNotProvided, "Item Date is required."},
                {BillDatesInThePastNotAllowed, "Bill dates in the past are not allowed."},
                {FutureBillDatesAllowedIfDateWithinCurrentPeriod, "Future bill dates are only allowed if the date is in the same period as the current date."},
                {CouldNotDeterminePostPeriod, "An accounting period could not be determined for the given date. Please check the period definitions and try again."},
                {CannotPostFutureDate, "The item date cannot be in the future. It must be within the current accounting period or up to and including the current date."},
                {ItemPostedToDifferentPeriod, "The item date is not within the period it will be posted to.  Please check that the transaction is dated correctly."},
                {ItemDateCannotBeInFuturePeriodThatIsClosedForModule, "The item date cannot be in the future period that is closed for the module."},
                {ItemDateEarlierThanLastFinalisedItemDate, "The item date cannot be earlier than the last finalised item date."},
                {TotalOfDebitOrCreditNoteMustBeGreaterThanZero, "The total of the debit/credit note must not be less than zero."},
                {EntityRestrictedByCurrency, "The Entity's currency is not the same as the Home Currency so billing against this entity is not allowed."},
                {BillCaseHasStatusRestrictedForBilling, "One or more cases included cannot be billed because its case status restricts this type of financial transaction."},
                {FailurePersistingOpenItem, "General error saving open item."},
                {EBillingXmlInvalid, "Unable to save E-Billing XML as the XML provided is invalid."},
                {WipAlreadyOnDifferentBill, "One or more WIP item(s) have been included on a different bill."},
                {OtherDraftBillsExistsForCasesOnThisBill, "Other draft bills exist for Cases on this bill"},
                {CasesOnThisBillHasUnbilledWip, "Cases on this bill have debit WIP that has not yet been included on a bill"},
                {CasesOnThisBillHasUnpostedTime,  "Cases on this bill have unposted time in one or more diary entries"}
            };
    }
}