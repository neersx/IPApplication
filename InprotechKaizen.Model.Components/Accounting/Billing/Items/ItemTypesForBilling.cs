using InprotechKaizen.Model.Accounting;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public enum ItemTypesForBilling : int
    {
        CreditNote = ItemType.CreditNote,
        DebitNote = ItemType.DebitNote,
        InternalCreditNote = ItemType.InternalCreditNote,
        InternalDebitNote = ItemType.InternalDebitNote,
    }
}