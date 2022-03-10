using System;

namespace InprotechKaizen.Model.Accounting
{
    [Flags]
    public enum SystemIdentifier : short
    {
        /// <summary>
        /// Processing
        /// </summary>
        Inprotech = 1,

        /// <summary>
        /// WIP
        /// </summary>
        TimeAndBilling = 2,

        /// <summary>
        /// Debtors
        /// </summary>
        AccountsReceivable = 4,

        /// <summary>
        /// Creditors
        /// </summary>
        AccountsPayable = 8,

        /// <summary>
        /// Cash and Bank
        /// </summary>
        Cashbook = 16,

        /// <summary>
        /// General Ledger
        /// </summary>
        GeneralLedger = 32,

        /// <summary>
        /// Trust Accounting
        /// </summary>
        TrustAccounts = 64
    }
}
